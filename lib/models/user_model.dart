// lib/models/user_model.dart

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // "mr", "admin", "head_admin"
  final String? region;
  final String? regionId;
  final String? phone;
  final String? dob;
  final String? joinDate;
  final String status; // "active", "inactive"
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.region,
    this.regionId,
    this.phone,
    this.dob,
    this.joinDate,
    this.status = 'active',
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'mr',
      region: json['region'],
      regionId: json['regionId'],
      phone: json['phone'],
      dob: json['dob'],
      joinDate: json['joinDate'],
      status: json['status'] ?? 'active',
      avatarUrl: json['avatarUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'role': role,
        'region': region,
        'regionId': regionId,
        'phone': phone,
        'dob': dob,
        'joinDate': joinDate,
        'status': status,
        'avatarUrl': avatarUrl,
      };

  String get displayRole {
    switch (role) {
      case 'head_admin':
        return 'Head Admin';
      case 'admin':
        return 'Admin';
      default:
        return 'Medical Representative';
    }
  }
}
