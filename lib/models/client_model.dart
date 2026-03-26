// lib/models/client_model.dart

class ClientModel {
  final String id;
  final String name;
  final String type; // "doctor", "retailer", "stockist"
  final String region;
  final String regionId;
  final String? specialty;
  final String? address;
  final String? phone;
  final double? lat;
  final double? lng;
  final String status;

  ClientModel({
    required this.id,
    required this.name,
    required this.type,
    required this.region,
    required this.regionId,
    this.specialty,
    this.address,
    this.phone,
    this.lat,
    this.lng,
    this.status = 'active',
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'doctor',
      region: json['region'] ?? '',
      regionId: json['regionId'] ?? '',
      specialty: json['specialty'],
      address: json['address'],
      phone: json['phone'],
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      status: json['status'] ?? 'active',
    );
  }

  String get typeLabel {
    switch (type) {
      case 'doctor':
        return 'Doctor';
      case 'retailer':
        return 'Retailer';
      case 'stockist':
        return 'Stockist';
      default:
        return type;
    }
  }
}
