import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/incident.dart';

class IncidentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _cloudName = 'suwraikx';
  static const String _uploadPreset = 'campus_care_upload';

  static const int _maxImageSize = 5 * 1024 * 1024;

  static const List<String> _allowedExtensions = ['jpg', 'jpeg', 'png'];

  static const List<String> validStatuses = [
    'Submitted',
    'In Progress',
    'Resolved',
  ];

  User _requireSignedInUser() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please log in to continue.');
    }

    return user;
  }

  // Retrieve incidents in real time.
  Stream<List<Incident>> getIncidents({required bool isStaff}) {
    final user = _requireSignedInUser();

    Query<Map<String, dynamic>> query = _db.collection('care_requests');

    // Students see only their own reports.
    // Staff can request all reports.
    if (!isStaff) {
      query = query.where('userId', isEqualTo: user.uid);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Incident.fromFirestore(doc)).toList(),
        );
  }

  // Upload an incident image to Cloudinary.
  Future<String> _uploadImageToCloudinary(XFile image) async {
    final extension = image.name.split('.').last.toLowerCase();

    if (!_allowedExtensions.contains(extension)) {
      throw Exception('Only JPG, JPEG, and PNG images are allowed.');
    }

    final imageBytes = await image.readAsBytes();

    if (imageBytes.isEmpty) {
      throw Exception('The selected image is empty.');
    }

    if (imageBytes.length > _maxImageSize) {
      throw Exception('Image size must not exceed 5 MB.');
    }

    final safeFileName = image.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: safeFileName,
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    final Map<String, dynamic> responseData;

    try {
      responseData = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Cloudinary returned an invalid response.');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorData = responseData['error'];
      final message = errorData is Map
          ? errorData['message']?.toString()
          : null;

      throw Exception(message ?? 'Image upload failed. Please try again.');
    }

    final imageUrl = responseData['secure_url'];

    if (imageUrl is! String || imageUrl.isEmpty) {
      throw Exception('Cloudinary did not return an image URL.');
    }

    return imageUrl;
  }

  // Create a new incident report.
  Future<void> createIncident({
    required String title,
    required String description,
    required String category,
    required String location,
    XFile? image,
  }) async {
    final user = _requireSignedInUser();

    final cleanTitle = title.trim();
    final cleanDescription = description.trim();
    final cleanCategory = category.trim();
    final cleanLocation = location.trim();

    if (cleanTitle.isEmpty ||
        cleanDescription.isEmpty ||
        cleanCategory.isEmpty ||
        cleanLocation.isEmpty) {
      throw Exception('Please complete all required incident fields.');
    }

    String imageUrl = '';

    // Upload image if one was selected.
    if (image != null) {
      imageUrl = await _uploadImageToCloudinary(image);
    }

    // Save incident information and image URL in Firestore.
    await _db.collection('care_requests').add({
      'title': cleanTitle,
      'description': cleanDescription,
      'category': cleanCategory,
      'location': cleanLocation,
      'imageUrl': imageUrl,
      'userId': user.uid,
      'reporterName': user.displayName ?? 'Student',
      'status': 'Submitted',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Update incident status.
  Future<void> updateStatus(String incidentId, String status) async {
    _requireSignedInUser();

    if (incidentId.trim().isEmpty) {
      throw Exception('Invalid incident ID.');
    }

    if (!validStatuses.contains(status)) {
      throw Exception('Invalid incident status.');
    }

    await _db.collection('care_requests').doc(incidentId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete an incident.
  Future<void> deleteIncident(String incidentId) async {
    _requireSignedInUser();

    if (incidentId.trim().isEmpty) {
      throw Exception('Invalid incident ID.');
    }

    await _db.collection('care_requests').doc(incidentId).delete();
  }
}
