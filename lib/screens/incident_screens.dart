import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/incident.dart';
import '../providers/incident_provider.dart';

const green = Color(0xFF176B5B);

const categories = [
  'Water shortage',
  'Electricity',
  'Broken facilities',
  'Damaged furniture',
  'Sanitation',
  'Safety concern',
  'Other',
];

const incidentStatuses = [
  'Submitted',
  'Under Review',
  'In Progress',
  'Resolved',
  'Rejected',
];

// REPORT AN INCIDENT

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final formKey = GlobalKey<FormState>();
  final title = TextEditingController();
  final description = TextEditingController();
  final location = TextEditingController();

  String category = categories.first;
  XFile? image;
  bool loading = false;

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    location.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    try {
      final selected = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1200,
      );

      if (selected != null && mounted) {
        setState(() => image = selected);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to select photograph: $e')),
      );
    }
  }

  void removeImage() {
    setState(() => image = null);
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();

    if (!formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      await context.read<IncidentProvider>().addIncident(
        title: title.text.trim(),
        description: description.text.trim(),
        category: category,
        location: location.text.trim(),
        image: image,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incident submitted successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Submission failed: $e')));
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report an Incident')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: title,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Incident title',
                  hintText: 'e.g. Broken classroom chair',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.report_problem_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter an incident title';
                  }
                  if (value.trim().length < 3) {
                    return 'Title must contain at least 3 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: categories.map((item) {
                  return DropdownMenuItem(value: item, child: Text(item));
                }).toList(),
                onChanged: loading
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => category = value);
                        }
                      },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: location,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Campus location',
                  hintText: 'e.g. Library, Block A',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter the incident location';
                  }
                  if (value.trim().length < 2) {
                    return 'Enter a more specific location';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: description,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 5,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Explain what happened, where and when...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 10) {
                    return 'Enter at least 10 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              const Text(
                'Attach a photograph (optional)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              if (image != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(image!.path),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stack) {
                      return Container(
                        height: 120,
                        color: Colors.black12,
                        alignment: Alignment.center,
                        child: const Text('Unable to preview photograph'),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(Icons.check_circle, color: green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        image!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: loading ? null : removeImage,
                      tooltip: 'Remove photograph',
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                  ],
                ),
              ] else
                InkWell(
                  onTap: loading ? null : pickImage,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 25),
                    decoration: BoxDecoration(
                      border: Border.all(color: green.withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFE1F0EB),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          color: green,
                          size: 35,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap to add a photograph',
                          style: TextStyle(
                            color: green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Choose an image from your gallery',
                          style: TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                  ),
                  child: loading
                      ? const SizedBox(
                          height: 23,
                          width: 23,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Submit Incident'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// BROWSE AND FILTER INCIDENTS

class IncidentListScreen extends StatelessWidget {
  const IncidentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Campus Incidents')),
      body: Consumer<IncidentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: green));
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 45,
                    ),
                    const SizedBox(height: 12),
                    Text(provider.errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        provider.stopListening();
                        provider.startListening(staff: provider.isStaff);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final incidents = provider.filteredIncidents;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  onChanged: provider.search,
                  decoration: InputDecoration(
                    hintText: 'Search incidents or locations...',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: provider.searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: provider.clearFilters,
                            icon: const Icon(Icons.clear),
                            tooltip: 'Clear search and filters',
                          )
                        : null,
                  ),
                ),
              ),

              SizedBox(
                height: 55,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: ['All', ...categories].map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(item),
                        selected: provider.selectedCategory == item,
                        selectedColor: const Color(0xFFD5EADF),
                        onSelected: (_) => provider.filter(item),
                      ),
                    );
                  }).toList(),
                ),
              ),

              Expanded(
                child: incidents.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(25),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.search_off,
                                size: 55,
                                color: green,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No incidents found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Try another search or select a different category.',
                                textAlign: TextAlign.center,
                              ),
                              TextButton(
                                onPressed: provider.clearFilters,
                                child: const Text('Clear filters'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: incidents.length,
                        itemBuilder: (context, index) {
                          final incident = incidents[index];

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFE1F0EB),
                                child: Icon(
                                  _categoryIcon(incident.category),
                                  color: green,
                                ),
                              ),
                              title: Text(
                                incident.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${incident.category} • ${incident.location}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 7),
                                    _StatusBadge(status: incident.status),
                                  ],
                                ),
                              ),
                              isThreeLine: true,
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => IncidentDetailsScreen(
                                      incident: incident,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// INCIDENT DETAILS AND STAFF STATUS MANAGEMENT

class IncidentDetailsScreen extends StatefulWidget {
  final Incident incident;

  const IncidentDetailsScreen({super.key, required this.incident});

  @override
  State<IncidentDetailsScreen> createState() => _IncidentDetailsScreenState();
}

class _IncidentDetailsScreenState extends State<IncidentDetailsScreen> {
  late Future<bool> staffFuture;

  @override
  void initState() {
    super.initState();
    staffFuture = isStaff();
  }

  Future<bool> isStaff() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return false;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return doc.data()?['role'] == 'staff';
  }

  Future<void> updateIncidentStatus(String incidentId, String status) async {
    try {
      await context.read<IncidentProvider>().updateStatus(incidentId, status);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  Future<void> deleteIncident(String incidentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete incident?'),
          content: const Text(
            'Are you sure you want to delete this incident? '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    try {
      await context.read<IncidentProvider>().deleteIncident(incidentId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incident deleted successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Incident Details')),
      body: FutureBuilder<bool>(
        future: staffFuture,
        builder: (context, staffSnapshot) {
          if (staffSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: green));
          }

          if (staffSnapshot.hasError) {
            return const Center(
              child: Text('Unable to load account permissions.'),
            );
          }

          final staff = staffSnapshot.data == true;

          return Consumer<IncidentProvider>(
            builder: (context, provider, child) {
              Incident currentIncident = widget.incident;

              for (final item in provider.incidents) {
                if (item.id == widget.incident.id) {
                  currentIncident = item;
                  break;
                }
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentIncident.title,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _StatusBadge(status: currentIncident.status),

                    const SizedBox(height: 20),

                    if (currentIncident.imageUrl.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          currentIncident.imageUrl,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stack) {
                            return Container(
                              height: 120,
                              color: const Color(0xFFE1F0EB),
                              alignment: Alignment.center,
                              child: const Text('Unable to load photograph'),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    _detail('Category', currentIncident.category),
                    _detail('Location', currentIncident.location),
                    _detail('Reported by', currentIncident.reporterName),
                    _detail('Status', currentIncident.status),
                    _detail('Description', currentIncident.description),

                    const SizedBox(height: 15),

                    const Text(
                      'Status Progress',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    _StatusTimeline(status: currentIncident.status),

                    const SizedBox(height: 25),

                    if (staff) ...[
                      const Divider(),

                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        key: ValueKey(currentIncident.status),
                        initialValue:
                            incidentStatuses.contains(currentIncident.status)
                            ? currentIncident.status
                            : 'Submitted',
                        decoration: const InputDecoration(
                          labelText: 'Update incident status',
                          border: OutlineInputBorder(),
                        ),
                        items: incidentStatuses.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            updateIncidentStatus(currentIncident.id, value);
                          }
                        },
                      ),

                      const SizedBox(height: 12),

                      TextButton.icon(
                        onPressed: () {
                          deleteIncident(currentIncident.id);
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'Delete incident',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}

// STATUS TIMELINE

class _StatusTimeline extends StatelessWidget {
  final String status;

  const _StatusTimeline({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == 'Rejected') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.red),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'This incident has been rejected.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final stages = ['Submitted', 'Under Review', 'In Progress', 'Resolved'];

    final currentIndex = stages.indexOf(status);
    final safeIndex = currentIndex < 0 ? 0 : currentIndex;

    return Column(
      children: [
        Row(
          children: List.generate(stages.length, (index) {
            final completed = index <= safeIndex;
            final current = index == safeIndex;

            return Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      if (index > 0)
                        Expanded(
                          child: Container(
                            height: 3,
                            color: index <= safeIndex
                                ? green
                                : Colors.grey.shade300,
                          ),
                        ),

                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: completed ? green : Colors.grey.shade300,
                        ),
                        child: Icon(
                          index < safeIndex
                              ? Icons.check
                              : current
                              ? Icons.circle
                              : Icons.circle_outlined,
                          size: 17,
                          color: completed
                              ? Colors.white
                              : Colors.grey.shade600,
                        ),
                      ),

                      if (index < stages.length - 1)
                        Expanded(
                          child: Container(
                            height: 3,
                            color: index < safeIndex
                                ? green
                                : Colors.grey.shade300,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    stages[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: current ? FontWeight.bold : FontWeight.normal,
                      color: completed ? green : Colors.black54,
                    ),
                  ),

                  if (current)
                    const Text(
                      'Current',
                      style: TextStyle(
                        fontSize: 9,
                        color: green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

// STATUS BADGE

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color background;
    Color foreground;

    switch (status) {
      case 'Resolved':
        background = const Color(0xFFDDF3E5);
        foreground = const Color(0xFF23834D);
        break;
      case 'In Progress':
        background = const Color(0xFFE1F0EB);
        foreground = green;
        break;
      case 'Under Review':
        background = const Color(0xFFFFF0CC);
        foreground = const Color(0xFF996500);
        break;
      case 'Rejected':
        background = const Color(0xFFFFE1E1);
        foreground = Colors.red.shade700;
        break;
      default:
        background = const Color(0xFFFFF0CC);
        foreground = const Color(0xFF996500);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// CATEGORY ICONS

IconData _categoryIcon(String category) {
  switch (category) {
    case 'Water shortage':
      return Icons.water_drop_outlined;
    case 'Electricity':
      return Icons.bolt_outlined;
    case 'Broken facilities':
      return Icons.business_outlined;
    case 'Damaged furniture':
      return Icons.chair_outlined;
    case 'Sanitation':
      return Icons.cleaning_services_outlined;
    case 'Safety concern':
      return Icons.shield_outlined;
    default:
      return Icons.report_problem_outlined;
  }
}
