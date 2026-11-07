import 'package:cloud_firestore/cloud_firestore.dart';

class Incident {
  final String id;
  final String title;
  final String description;
  final String category;
  final String location;
  final String imageUrl;
  final String userId;
  final String reporterName;
  final String status;
  final DateTime createdAt;

  const Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.imageUrl,
    required this.userId,
    required this.reporterName,
    required this.status,
    required this.createdAt,
  });

  // Safely read string fields from Firestore.
  static String _readString(
    Map<String, dynamic> data,
    String field,
    String defaultValue,
  ) {
    final value = data[field];

    return value is String ? value : defaultValue;
  }

  // Safely convert Firestore timestamps into DateTime.
  static DateTime _readDate(Map<String, dynamic> data) {
    final timestamp = data['createdAt'];

    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }

    if (timestamp is DateTime) {
      return timestamp;
    }

    // Use a consistent fallback for missing or invalid dates.
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  // Convert a Firestore document into an Incident object.
  factory Incident.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return Incident(
      id: doc.id,
      title: _readString(data, 'title', ''),
      description: _readString(data, 'description', ''),
      category: _readString(data, 'category', 'Other'),
      location: _readString(data, 'location', ''),
      imageUrl: _readString(data, 'imageUrl', ''),
      userId: _readString(data, 'userId', ''),
      reporterName: _readString(data, 'reporterName', 'Student'),
      status: _readString(data, 'status', 'Submitted'),
      createdAt: _readDate(data),
    );
  }

  // Convert an Incident object into Firestore-compatible data.
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'imageUrl': imageUrl,
      'userId': userId,
      'reporterName': reporterName,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create a copy with selected fields changed.
  Incident copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? location,
    String? imageUrl,
    String? userId,
    String? reporterName,
    String? status,
    DateTime? createdAt,
  }) {
    return Incident(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      userId: userId ?? this.userId,
      reporterName: reporterName ?? this.reporterName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
