// lib/models/visit_model.dart
import 'attendance_model.dart';

class VisitModel {
  final String id;
  final String mrId;
  final String clientId;
  final String date;
  final String? checkIn;
  final String? checkOut;
  final GeoPoint? checkInLocation;
  final GeoPoint? checkOutLocation;
  final List<String> products;
  final String? notes;
  // Optionally populated from join
  final String? clientName;
  final String? clientType;
  final String? mrName;

  VisitModel({
    required this.id,
    required this.mrId,
    required this.clientId,
    required this.date,
    this.checkIn,
    this.checkOut,
    this.checkInLocation,
    this.checkOutLocation,
    this.products = const [],
    this.notes,
    this.clientName,
    this.clientType,
    this.mrName,
  });

  bool get isCheckedIn => checkIn != null;
  bool get isCheckedOut => checkOut != null;

  factory VisitModel.fromJson(Map<String, dynamic> json) {
    return VisitModel(
      id: json['_id'] ?? json['id'] ?? '',
      mrId: json['mrId'] ?? '',
      clientId: json['clientId'] ?? '',
      date: json['date'] ?? '',
      checkIn: json['checkIn'],
      checkOut: json['checkOut'],
      checkInLocation: json['checkInLocation'] != null
          ? GeoPoint.fromJson(json['checkInLocation'])
          : null,
      checkOutLocation: json['checkOutLocation'] != null
          ? GeoPoint.fromJson(json['checkOutLocation'])
          : null,
      products: List<String>.from(json['products'] ?? []),
      notes: json['notes'],
      clientName: json['clientName'],
      clientType: json['clientType'],
      mrName: json['mrName'],
    );
  }
}
