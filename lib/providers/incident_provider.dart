import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/incident.dart';
import '../services/incident_service.dart';

class IncidentProvider extends ChangeNotifier {
  final IncidentService _service = IncidentService();

  List<Incident> _incidents = [];

  bool isLoading = true;
  String? errorMessage;
  String searchQuery = '';
  String selectedCategory = 'All';
  bool isStaff = false;

  StreamSubscription<List<Incident>>? _subscription;

  int _streamGeneration = 0;
  bool _disposed = false;

  // Read-only access to incidents.
  List<Incident> get incidents => List.unmodifiable(_incidents);

  // Listen to Firestore incident updates.
  void startListening({required bool staff}) {
    if (_subscription != null && isStaff == staff) {
      return;
    }

    // Invalidate callbacks from previous subscriptions.
    final generation = ++_streamGeneration;

    final previousSubscription = _subscription;
    _subscription = null;

    if (previousSubscription != null) {
      unawaited(previousSubscription.cancel());
    }

    isStaff = staff;
    _incidents = [];
    isLoading = true;
    errorMessage = null;
    searchQuery = '';
    selectedCategory = 'All';

    notifyListeners();

    try {
      _subscription = _service
          .getIncidents(isStaff: staff)
          .listen(
            (data) {
              if (_disposed || generation != _streamGeneration) {
                return;
              }

              _incidents = data;
              isLoading = false;
              errorMessage = null;
              notifyListeners();
            },
            onError: (Object error) {
              if (_disposed || generation != _streamGeneration) {
                return;
              }

              _subscription = null;
              isLoading = false;
              errorMessage = 'Unable to load incidents: $error';
              notifyListeners();
            },
            onDone: () {
              if (_disposed || generation != _streamGeneration) {
                return;
              }

              _subscription = null;
              isLoading = false;
              errorMessage ??= 'Incident updates have stopped.';
              notifyListeners();
            },
          );
    } catch (error) {
      if (_disposed || generation != _streamGeneration) {
        return;
      }

      _subscription = null;
      isLoading = false;
      errorMessage = 'Unable to start incident updates: $error';
      notifyListeners();
    }
  }

  // Stop listening and clear data when the user logs out.
  void stopListening() {
    ++_streamGeneration;

    final previousSubscription = _subscription;
    _subscription = null;

    if (previousSubscription != null) {
      unawaited(previousSubscription.cancel());
    }

    _incidents = [];
    isLoading = true;
    errorMessage = null;
    searchQuery = '';
    selectedCategory = 'All';
    isStaff = false;

    notifyListeners();
  }

  // Search and category filtering.
  List<Incident> get filteredIncidents {
    final query = searchQuery.trim().toLowerCase();

    return _incidents.where((incident) {
      final matchesSearch =
          query.isEmpty ||
          incident.title.toLowerCase().contains(query) ||
          incident.location.toLowerCase().contains(query) ||
          incident.description.toLowerCase().contains(query) ||
          incident.category.toLowerCase().contains(query) ||
          incident.reporterName.toLowerCase().contains(query);

      final matchesCategory =
          selectedCategory == 'All' || incident.category == selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  // Dashboard statistics.
  int get totalCount => _incidents.length;

  int get resolvedCount =>
      _incidents.where((incident) => incident.status == 'Resolved').length;

  int get pendingCount =>
      _incidents.where((incident) => incident.status == 'Submitted').length;

  int get inProgressCount =>
      _incidents.where((incident) => incident.status == 'In Progress').length;

  // Create a new incident.
  Future<void> addIncident({
    required String title,
    required String description,
    required String category,
    required String location,
    XFile? image,
  }) async {
    await _service.createIncident(
      title: title,
      description: description,
      category: category,
      location: location,
      image: image,
    );
  }

  // Update incident status.
  Future<void> updateStatus(String id, String status) async {
    await _service.updateStatus(id, status);
  }

  // Delete an incident.
  Future<void> deleteIncident(String id) async {
    await _service.deleteIncident(id);
  }

  // Update search query.
  void search(String value) {
    if (searchQuery == value) return;

    searchQuery = value;
    notifyListeners();
  }

  // Update selected category.
  void filter(String category) {
    if (selectedCategory == category) return;

    selectedCategory = category;
    notifyListeners();
  }

  // Clear all filters.
  void clearFilters() {
    if (searchQuery.isEmpty && selectedCategory == 'All') {
      return;
    }

    searchQuery = '';
    selectedCategory = 'All';
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_streamGeneration;

    final previousSubscription = _subscription;
    _subscription = null;

    if (previousSubscription != null) {
      unawaited(previousSubscription.cancel());
    }

    super.dispose();
  }
}
