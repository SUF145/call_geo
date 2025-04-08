import 'package:flutter/foundation.dart';

enum UserRole { admin, user }

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? mobileNumber;
  final UserRole role;
  final String? createdBy; // ID of the admin who created this user

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.mobileNumber,
    this.role = UserRole.user,
    this.createdBy,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Explicitly check the role value and print for debugging
    final roleValue = json['role'];
    debugPrint('Role value from JSON: $roleValue');
    final role = roleValue == 'admin' ? UserRole.admin : UserRole.user;
    debugPrint('Parsed role: $role');

    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      mobileNumber: json['mobile_number'],
      role: role,
      createdBy: json['created_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'mobile_number': mobileNumber,
      'role': role == UserRole.admin ? 'admin' : 'user',
      'created_by': createdBy,
    };
  }

  bool get isAdmin => role == UserRole.admin;
}
