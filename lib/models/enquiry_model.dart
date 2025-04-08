import 'package:flutter/material.dart';

/// Model class for Enquiry from API
class Enquiry {
  final String? id;
  final String name;
  final String mobile;
  final DateTime? callbackTime;
  final String remark;
  final String packageName;
  final String totalAmount;
  final String paidAmount;
  final String status;
  final String statusColorCode;
  final String statusType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Enquiry({
    this.id,
    required this.name,
    required this.mobile,
    this.callbackTime,
    this.remark = '',
    required this.packageName,
    required this.totalAmount,
    required this.paidAmount,
    required this.status,
    required this.statusColorCode,
    required this.statusType,
    this.createdAt,
    this.updatedAt,
  });

  /// Create an Enquiry from JSON data
  factory Enquiry.fromJson(Map<String, dynamic> json) {
    return Enquiry(
      id: json['id']?.toString(),
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      callbackTime: json['callback_time'] != null && json['callback_time'] != ''
          ? DateTime.parse(json['callback_time'])
          : null,
      remark: json['remark'] ?? '',
      packageName: json['package_name'] ?? '',
      totalAmount: json['total_amount']?.toString() ?? '0',
      paidAmount: json['paid_amount']?.toString() ?? '0',
      status: json['status'] ?? 'Pending',
      statusColorCode: json['status_color_code'] ?? '#808080',
      statusType: json['status_type'] ?? 'default',
      createdAt: json['created_at'] != null && json['created_at'] != ''
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null && json['updated_at'] != ''
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  /// Convert Enquiry to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'callback_time': callbackTime?.toIso8601String(),
      'remark': remark,
      'package_name': packageName,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'status': status,
      'status_color_code': statusColorCode,
      'status_type': statusType,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Convert Enquiry to User model
  User toUser() {
    return User(
      id: id,
      name: name,
      mobile: mobile,
      callbackTime: callbackTime,
      remark: remark,
      packageName: packageName,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      status: status,
      statusColorCode: statusColorCode,
      statusType: statusType,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Model class for User in the UI
class User {
  String? id;
  final String name;
  final String mobile;
  DateTime? callbackTime;
  final String remark;
  final String packageName;
  final String totalAmount;
  final String paidAmount;
  String status;
  String statusColorCode;
  String statusType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    this.id,
    required this.name,
    required this.mobile,
    this.callbackTime,
    this.remark = '',
    required this.packageName,
    required this.totalAmount,
    required this.paidAmount,
    required this.status,
    required this.statusColorCode,
    required this.statusType,
    this.createdAt,
    this.updatedAt,
  });
}

/// Model class for Status Selection
class SelectionStatus {
  final String displyName;
  final String statusColorCode;
  final String type;

  SelectionStatus({
    required this.displyName,
    required this.statusColorCode,
    required this.type,
  });
}
