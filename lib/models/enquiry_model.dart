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
  final String? statusId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isScheduled;
  

  Enquiry({
    this.id,
    required this.name,
    required this.mobile,
    this.callbackTime,
    this.remark = '',
    required this.packageName,
    required this.totalAmount,
    required this.paidAmount,
    this.createdAt,
    this.updatedAt,
    required this.isScheduled,
    this.statusId,
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
      statusId: json['statusId']?.toString(),
      createdAt: json['created_at'] != null && json['created_at'] != ''
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null && json['updated_at'] != ''
          ? DateTime.parse(json['updated_at'])
          : null,

          isScheduled: json['is_scheduled'] == 1 || json['is_scheduled'] == true,
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
      'status_id': statusId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
       'is_scheduled': isScheduled,
    };
  }

  /// Convert Enquiry to User model
  User toUser() {
    // Find the matching status option
    final List<SelectionStatus> statusOptions = [
      SelectionStatus(
        displyName: "Callback",
        statusColorCode: "#FFA500",
        type: "timer",
        id: "1",
      ),
      SelectionStatus(
        displyName: "Not Interested",
        statusColorCode: "#FF0000",
        type: "default",
        id: "2",
      ),
      SelectionStatus(
        displyName: "Using an App",
        statusColorCode: "#00FF00",
        type: "default",
        id: "3",
      ),
      SelectionStatus(
        displyName: "Interested",
        statusColorCode: "#008000",
        type: "default",
        id: "4",
      ),
      SelectionStatus(
        displyName: "Call Not Attended ",
        statusColorCode: "#808080",
        type: "default",
        id: "5",
      ),
    ];
    
    // Find the status option with the matching ID
    SelectionStatus matchingStatus = statusOptions.firstWhere(
      (status) => status.id == statusId,
      orElse: () => SelectionStatus(
        id: "0",
        displyName: "Unknown",
        statusColorCode: "#808080",
        type: "default",
      ),
    );
    
    return User(
      id: id,
      name: name,
      mobile: mobile,
      callbackTime: callbackTime,
      remark: remark,
      packageName: packageName,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      statusId: statusId,
      statusType: matchingStatus.type,
      statusColorCode: matchingStatus.statusColorCode,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isScheduled: isScheduled,
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
  String? statusId;
  String statusType;
  String statusColorCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  bool isScheduled;

  User({
    this.id,
    required this.name,
    required this.mobile,
    this.callbackTime,
    this.remark = '',
    required this.packageName,
    required this.totalAmount,
    required this.paidAmount,
    this.statusId,
    this.statusType = 'default',
    this.statusColorCode = '#808080',
    this.createdAt,
    this.updatedAt,
    required this.isScheduled,
  });
}

/// Model class for Status Selection
class SelectionStatus {
  final String id;
  final String displyName;
  final String statusColorCode;
  final String type;

  SelectionStatus({
    required this.id,
    required this.displyName,
    required this.statusColorCode,
    required this.type,
  });
}
