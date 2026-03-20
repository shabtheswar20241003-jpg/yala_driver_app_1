class IncidentModel {
  final String id;
  final String type;
  final String title;
  final String? imageUrl;
  final double latitude;
  final double longitude;

  IncidentModel({
    required this.id,
    required this.type,
    required this.title,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    return IncidentModel(
      id: json["id"],
      type: json["type"] ?? "",
      title: json["title"] ?? "",
      latitude: (json["latitude"] as num).toDouble(),
      longitude: (json["longitude"] as num).toDouble(),
      imageUrl: json["image_url"],
    );
  }
}
