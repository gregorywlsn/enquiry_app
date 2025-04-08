import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:enquiry_app/models/enquiry_model.dart';

/// Service class to handle API requests
class ApiService {
  // Base URL for the API
  final String baseUrl = 'https://yeahbuddyapp.in/staging/stammapis/APIs'; // Change this to your actual API URL
  
  // HTTP client
  final http.Client _client = http.Client();
  
  /// Get all enquiries
  Future<List<Enquiry>> getEnquiries() async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/enquiry/read.php'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data.containsKey('records')) {
          final List<dynamic> records = data['records'];
          return records.map((record) => Enquiry.fromJson(record)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load enquiries: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load enquiries: $e');
    }
  }
  
  /// Get a single enquiry by ID
  Future<Enquiry> getEnquiry(String id) async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/enquiry/read_one.php?id=$id'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Enquiry.fromJson(data);
      } else {
        throw Exception('Failed to load enquiry: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load enquiry: $e');
    }
  }
  
  /// Create a new enquiry
  Future<void> createEnquiry(Map<String, dynamic> enquiryData) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/enquiry/create.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(enquiryData),
      );
      
      if (response.statusCode != 201) {
        throw Exception('Failed to create enquiry: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create enquiry: $e');
    }
  }
  
  /// Update an existing enquiry
  Future<void> updateEnquiry(String id, Map<String, dynamic> enquiryData) async {
    try {
      // Add ID to the data
      enquiryData['id'] = id;
      
      final response = await _client.post(
        Uri.parse('$baseUrl/enquiry/update.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(enquiryData),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update enquiry: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update enquiry: $e');
    }
  }
  
  /// Update enquiry status
  Future<void> updateEnquiryStatus(String id, String statusId, Map<String, dynamic> statusData) async {
    try {
      // Add ID to the data
      statusData['id'] = id;
      statusData['statusId'] = statusId;
      
      final response = await _client.post(
        Uri.parse('$baseUrl/enquiry/update_status.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(statusData),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update enquiry status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update enquiry status: $e');
    }
  }
  
  /// Delete an enquiry
  Future<void> deleteEnquiry(String id) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/enquiry/delete.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id': id}),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to delete enquiry: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete enquiry: $e');
    }
  }
}
