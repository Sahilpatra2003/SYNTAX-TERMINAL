import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:safety_app/models/report.dart';
import 'package:safety_app/services/firestore_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late MapController _controller;
  List<Map<String, dynamic>> facilities = [];
  List<Report> reports = [];
  List<GeoPoint> reportMarkers = [];
  GeoPoint? userLocation;
  bool _isMounted = false;
  bool _mapLoadError = false;
  bool _showReportList = false;
  bool _isLoadingReports = false;
  bool _isInitializing = true;
  String? _reportLoadError;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      debugPrint('Initializing MapScreen');
      _controller = MapController.withPosition(
        initPosition: GeoPoint(latitude: 22.5726, longitude: 88.3639), // Kolkata, India
      );
      debugPrint('MapController initialized successfully');
      await Future.wait([
        _loadFacilities(),
        _loadReports(),
        _setUserLocation(),
      ]);
      debugPrint('All initialization tasks completed');
    } catch (e) {
      debugPrint('Error during initialization: $e');
      if (_isMounted) {
        setState(() {
          _mapLoadError = true;
        });
      }
    } finally {
      if (_isMounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _loadFacilities() async {
    try {
      final data = await DefaultAssetBundle.of(context).loadString('assets/data.json');
      if (_isMounted) {
        setState(() {
          facilities = List<Map<String, dynamic>>.from(jsonDecode(data));
          debugPrint('Loaded ${facilities.length} facilities');
          for (var facility in facilities) {
            if (facility['lat'] == null || facility['lng'] == null || facility['type'] == null) {
              debugPrint('Invalid facility data: $facility');
              continue;
            }
            debugPrint('Adding facility marker at ${facility['lat']}, ${facility['lng']} (Type: ${facility['type']})');
            try {
              _controller.addMarker(
                GeoPoint(latitude: facility['lat'], longitude: facility['lng']),
                markerIcon: MarkerIcon(
                  icon: Icon(
                    facility['type'] == 'police' ? Icons.local_police : Icons.local_hospital,
                    color: facility['type'] == 'police' ? Colors.blue : Colors.red,
                    size: facility['type'] == 'police' ? 32 : 48,
                  ),
                ),
              );
            } catch (e) {
              debugPrint('Error adding facility marker at ${facility['lat']}, ${facility['lng']}: $e');
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading facilities: $e');
    }
  }

  Future<void> _loadReports() async {
    if (_isLoadingReports) return;
    setState(() {
      _isLoadingReports = true;
      _reportLoadError = null;
    });

    try {
      final fetchedReports = await FirestoreService().getReports();
      debugPrint('Fetched ${fetchedReports.length} reports from Firestore');
      if (_isMounted) {
        final uniqueReports = <String, Report>{};
        for (var report in fetchedReports) {
          debugPrint('Processing report: ${report.id}, ${report.latitude}, ${report.longitude}');
          uniqueReports[report.id] = report;
        }
        final newReports = uniqueReports.values.toList();
        debugPrint('After deduplication, ${newReports.length} unique reports');
        debugPrint('Reports: ${newReports.map((r) => r.toMap()).toList()}');

        if (!areReportsEqual(reports, newReports)) {
          debugPrint('Reports have changed, updating markers');
          for (var marker in reportMarkers) {
            if (userLocation == null ||
                (marker.latitude != userLocation!.latitude &&
                    marker.longitude != userLocation!.longitude)) {
              try {
                debugPrint('Removing marker at ${marker.latitude}, ${marker.longitude}');
                _controller.removeMarker(marker);
              } catch (e) {
                debugPrint('Error removing marker at $marker: $e');
              }
            }
          }

          setState(() {
            reports = newReports;
            reportMarkers.clear();
            for (var report in reports) {
              if (report.latitude != 0 && report.longitude != 0) {
                final point = GeoPoint(
                  latitude: report.latitude.toDouble(),
                  longitude: report.longitude.toDouble(),
                );
                try {
                  debugPrint('Adding report marker at ${point.latitude}, ${point.longitude}');
                  _controller.addMarker(
                    point,
                    markerIcon: MarkerIcon(
                      icon: Icon(
                        Icons.warning,
                        color: (report.confirmations.toInt() >= 6) ? Colors.red : Colors.orange,
                        size: 32,
                      ),
                    ),
                  );
                  reportMarkers.add(point);
                } catch (e) {
                  debugPrint('Error adding marker for report ${report.id}: $e');
                }
              }
            }
          });
        } else {
          debugPrint('Reports unchanged, skipping marker update');
        }
      }
    } catch (e) {
      debugPrint('Error loading reports: $e');
      if (_isMounted) {
        setState(() {
          reports = [];
          reportMarkers.clear();
          _reportLoadError = e.toString().contains('permission')
              ? 'Permission denied. Please ensure you have access to view reports.'
              : 'Unable to load reports. Please check your internet connection or try again later.';
        });
      }
    } finally {
      if (_isMounted) {
        setState(() {
          _isLoadingReports = false;
        });
      }
    }
  }

  bool areReportsEqual(List<Report> oldReports, List<Report> newReports) {
    if (oldReports.length != newReports.length) return false;
    for (int i = 0; i < oldReports.length; i++) {
      if (oldReports[i].id != newReports[i].id ||
          oldReports[i].latitude.toDouble() != newReports[i].latitude.toDouble() ||
          oldReports[i].longitude.toDouble() != newReports[i].longitude.toDouble() ||
          oldReports[i].confirmations.toInt() != newReports[i].confirmations.toInt()) {
        return false;
      }
    }
    return true;
  }

  Future<void> _setUserLocation() async {
    if (_isMounted) {
      setState(() {
        userLocation = GeoPoint(latitude: 22.5726, longitude: 88.3639); // Kolkata, India
        try {
          debugPrint('Adding user location marker at ${userLocation!.latitude}, ${userLocation!.longitude}');
          _controller.addMarker(
            userLocation!,
            markerIcon: MarkerIcon(
              icon: Icon(
                Icons.person,
                color: Colors.green,
                size: 24,
              ),
            ),
          );
        } catch (e) {
          debugPrint('Error adding user location marker: $e');
        }
      });
    }
    await _checkProximity();
  }

  double calculateDistance(GeoPoint p1, GeoPoint p2) {
    const double earthRadius = 6371e3;
    final double lat1 = p1.latitude * (math.pi / 180);
    final double lon1 = p1.longitude * (math.pi / 180);
    final double lat2 = p2.latitude * (math.pi / 180);
    final double lon2 = p2.longitude * (math.pi / 180);
    final double dlat = lat2 - lat1;
    final double dlon = lon2 - lon1;

    final double sinDLatOver2 = math.sin(dlat / 2);
    final double sinDLonOver2 = math.sin(dlon / 2);
    final double a = (sinDLatOver2 * sinDLatOver2) +
        math.cos(lat1) * math.cos(lat2) * (sinDLonOver2 * sinDLonOver2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final double distance = earthRadius * c;
    return distance;
  }

  Future<void> _checkProximity() async {
    if (userLocation == null || !_isMounted) return;
    for (var report in reports) {
      if (report.confirmations.toInt() >= 6) {
        final distance = calculateDistance(
          userLocation!,
          GeoPoint(
            latitude: report.latitude.toDouble(),
            longitude: report.longitude.toDouble(),
          ),
        );
        if (distance < 500) {
          final now = DateTime.now();
          if (now.hour >= 20) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                debugPrint('Showing proximity warning for report at ${report.latitude}, ${report.longitude}');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Avoid this area at night')),
                );
              }
            });
          }
        }
      }
    }
  }

  // Helper widget to load an image with a fallback
  Widget _loadImageIcon(String assetPath, double size, Color? color, IconData fallbackIcon) {
    return FutureBuilder(
      future: precacheImage(AssetImage(assetPath), context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            debugPrint('Failed to load image: $assetPath, error: ${snapshot.error}, stackTrace: ${snapshot.stackTrace}');
            return Icon(
              fallbackIcon,
              size: size,
              color: color ?? Colors.red,
            );
          } else {
            debugPrint('Successfully loaded image: $assetPath');
            return ImageIcon(
              AssetImage(assetPath),
              size: size,
              color: color,
            );
          }
        } else {
          return Icon(
            fallbackIcon,
            size: size,
            color: Colors.grey,
          );
        }
      },
    );
  }

  // Helper method to convert rating to star symbols
  String _getStarRating(num rating) {
    int starCount = rating.toInt();
    if (starCount < 0) starCount = 0;
    if (starCount > 5) starCount = 5;
    return '⭐' * starCount;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building MapScreen with showReportList: $_showReportList');
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: _loadImageIcon(
            'assets/icons/settings.png',
            24,
            null, // Use PNG's original color
            Icons.error,
          ),
          onPressed: () {
            debugPrint('Navigating to settings screen');
            Navigator.pushNamed(context, '/settings');
          },
          tooltip: 'Settings',
        ),
        title: const Text('Safety Map'),
        actions: [
          IconButton(
            icon: _loadImageIcon(
              _showReportList ? 'assets/icons/map.png' : 'assets/icons/list.png',
              24,
              Colors.black,
              _showReportList ? Icons.map : Icons.list,
            ),
            onPressed: () {
              debugPrint('Toggling report list visibility');
              setState(() {
                _showReportList = !_showReportList;
              });
            },
            tooltip: _showReportList ? 'Show Map Only' : 'Show Report List',
          ),
          IconButton(
            icon: _loadImageIcon(
              'assets/icons/refresh.png',
              24,
              Colors.black,
              Icons.refresh,
            ),
            onPressed: _loadReports,
            tooltip: 'Refresh Reports',
          ),
        ],
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.only(bottom: 120.0),
        child: Column(
          children: [
            Expanded(
              child: _mapLoadError
                  ? const Center(
                child: Text(
                  'Failed to load map. Please check your internet connection or try again later.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              )
                  : OSMFlutter(
                controller: _controller,
                osmOption: OSMOption(
                  zoomOption: const ZoomOption(
                    initZoom: 14,
                    minZoomLevel: 10,
                    maxZoomLevel: 19,
                    stepZoom: 1.0,
                  ),
                  userLocationMarker: UserLocationMaker(
                    personMarker: MarkerIcon(
                      icon: Icon(
                        Icons.person,
                        color: Colors.green,
                        size: 24,
                      ),
                    ),
                    directionArrowMarker: MarkerIcon(
                      icon: Icon(
                        Icons.arrow_forward,
                        color: Colors.green,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                mapIsLoading: const Center(child: CircularProgressIndicator()),
              ),
            ),
            if (_showReportList)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: _isLoadingReports
                    ? const Center(child: CircularProgressIndicator())
                    : _reportLoadError != null
                    ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _reportLoadError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                )
                    : reports.isEmpty
                    ? const Center(child: Text('No reports available.'))
                    : ListView.builder(
                  key: const ValueKey('report_list'),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    debugPrint('Rendering report in list: ${report.id}');
                    return ListTile(
                      leading: _loadImageIcon(
                        'assets/icons/warning.png',
                        24,
                        (report.confirmations.toInt() >= 6) ? Colors.red : Colors.orange,
                        Icons.warning,
                      ),
                      title: Text(report.description),
                      subtitle: Text(
                        'Rating: ${_getStarRating(report.rating)} | Confirmations: ${report.confirmations.toString()}',
                        style: TextStyle(
                          color: report.rating.toInt() == 5 ? Colors.red : Colors.black,
                        ),
                      ),
                      onTap: () {
                        debugPrint('Tapped report: ${report.id}, moving to ${report.latitude}, ${report.longitude}');
                        _controller.setZoom(zoomLevel: 16);
                        _controller.moveTo(
                          GeoPoint(
                            latitude: report.latitude.toDouble(),
                            longitude: report.longitude.toDouble(),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () async {
              debugPrint('Report Unsafe Area button tapped, navigating to report screen');
              final result = await Navigator.pushNamed(context, '/report');
              if (result != null && result is GeoPoint) {
                debugPrint('Received location from ReportScreen: ${result.latitude}, ${result.longitude}');
                _controller.setZoom(zoomLevel: 16);
                _controller.moveTo(result);
              }
            },
            child: _loadImageIcon(
              'assets/icons/report.png',
              24,
              Colors.black,
              Icons.report,
            ),
            tooltip: 'Report Unsafe Area',
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () {
              if (mounted) {
                debugPrint('SOS button tapped');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('SOS sent: ${userLocation?.latitude}, ${userLocation?.longitude}'),
                  ),
                );
              }
            },
            child: _loadImageIcon(
              'assets/icons/sos.png',
              24,
              Colors.black,
              Icons.sos,
            ),
            tooltip: 'SOS',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _isMounted = false;
    _controller.dispose();
    super.dispose();
  }
}