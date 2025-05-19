import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:safety_app/models/report.dart';
import 'package:safety_app/services/auth_service.dart';
import 'package:safety_app/services/firestore_service.dart';
import 'package:uuid/uuid.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _placeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ratingController = TextEditingController();
  GeoPoint? _searchedLocation;
  bool _isSearching = false;
  String? _searchError;

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

  Future<void> _searchLocation() async {
    setState(() {
      _isSearching = true;
      _searchError = null;
      _searchedLocation = null;
    });

    try {
      final city = _cityController.text.trim();
      final district = _districtController.text.trim();
      final place = _placeController.text.trim();

      if (city.isEmpty || district.isEmpty || place.isEmpty) {
        setState(() {
          _searchError = 'Please fill in all location fields.';
          _isSearching = false;
        });
        return;
      }

      final query = '$place, $district, $city';
      debugPrint('Searching for location: $query');

      // Use addressSuggestion without maxResults parameter
      final searchResults = await addressSuggestion(query);

      if (searchResults.isNotEmpty) {
        final result = searchResults.first;
        final geoPoint = result.point;
        if (geoPoint != null) {
          setState(() {
            _searchedLocation = geoPoint;
            debugPrint('Found location: ${geoPoint.latitude}, ${geoPoint.longitude}');
          });
        } else {
          setState(() {
            _searchError = 'Location coordinates not available.';
          });
        }
      } else {
        setState(() {
          _searchError = 'Location not found. Please try a different search.';
        });
      }
    } catch (e) {
      debugPrint('Error searching location: $e');
      setState(() {
        _searchError = 'Error searching location. Please try again.';
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _submitReport() async {
    if (_searchedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please search for a location first.')),
      );
      return;
    }

    final description = _descriptionController.text.trim();
    final ratingText = _ratingController.text.trim();

    if (description.isEmpty || ratingText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    final rating = double.tryParse(ratingText);
    if (rating == null || rating < 0 || rating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid rating between 0 and 5.')),
      );
      return;
    }

    try {
      final userId = AuthService().currentUser?.uid ?? 'anonymous';
      final report = Report(
        id: const Uuid().v4(),
        latitude: _searchedLocation!.latitude,
        longitude: _searchedLocation!.longitude,
        rating: rating,
        description: description,
        confirmations: 0,
        userId: userId,
      );

      await FirestoreService().addReport(report);
      debugPrint('Report submitted successfully: ${report.id}');

      // Navigate back to MapScreen and pass the searched location
      Navigator.pop(context, _searchedLocation);
    } catch (e) {
      debugPrint('Error submitting report: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting report: $e')),
      );
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    _districtController.dispose();
    _placeController.dispose();
    _descriptionController.dispose();
    _ratingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Unsafe Area'),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(
          color: Colors.white,
          size: 24,
        ),
        leading: IconButton(
          icon: _loadImageIcon(
            'assets/icons/arrow_back.png',
            24,
            null, // Use PNG's original color
            Icons.error,
          ),
          onPressed: () {
            debugPrint('Back button pressed, navigating back to MapScreen');
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _districtController,
              decoration: const InputDecoration(
                labelText: 'District',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _placeController,
              decoration: const InputDecoration(
                labelText: 'Place',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isSearching ? null : _searchLocation,
              child: _isSearching
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Search Location'),
            ),
            if (_searchError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _searchError!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (_searchedLocation != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: const Text(
                  'Location Found Successfully',
                  style: TextStyle(color: Colors.green),
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              'Report Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _ratingController,
              decoration: const InputDecoration(
                labelText: 'Rating (0-5)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _submitReport,
                child: const Text('Submit Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}