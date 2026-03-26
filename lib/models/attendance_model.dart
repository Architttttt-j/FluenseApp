// lib/models/attendance_model.dart

class GeoPoint {
  final double lat;
  final double lng;

  GeoPoint({required this.lat, required this.lng});

  factory GeoPoint.fromJson(Map<String, dynamic> json) {
    return GeoPoint(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
}

class AttendanceModel {
  final String id;
  final String mrId;
  final String date;
  final String? checkIn;
  final String? checkOut;
  final GeoPoint? checkInLocation;
  final GeoPoint? checkOutLocation;
  final String status;

  AttendanceModel({
    required this.id,
    required this.mrId,
    required this.date,
    this.checkIn,
    this.checkOut,
    this.checkInLocation,
    this.checkOutLocation,
    this.status = 'present',
  });

  bool get isCheckedIn => checkIn != null;
  bool get isCheckedOut => checkOut != null;

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['_id'] ?? json['id'] ?? '',
      mrId: json['mrId'] ?? '',
      date: json['date'] ?? '',
      checkIn: json['checkIn'],
      checkOut: json['checkOut'],
      checkInLocation: json['checkInLocation'] != null
          ? GeoPoint.fromJson(json['checkInLocation'])
          : null,
      checkOutLocation: json['checkOutLocation'] != null
          ? GeoPoint.fromJson(json['checkOutLocation'])
          : null,
      status: json['status'] ?? 'present',
    );
  }
}
