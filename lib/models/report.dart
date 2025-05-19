class Report {
  final String id;
  final double latitude;
  final double longitude;
  final double rating;
  final String description;
  final int confirmations;
  final String userId;

  Report({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.description,
    required this.confirmations,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'description': description,
      'confirmations': confirmations,
      'userId': userId,
    };
  }

  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      rating: (map['rating'] as num).toDouble(),
      description: map['description'] as String,
      confirmations: (map['confirmations'] as num).toInt(),
      userId: map['userId'] as String,
    );
  }
}