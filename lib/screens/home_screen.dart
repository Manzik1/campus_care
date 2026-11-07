import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import 'incident_screens.dart';

const green = Color(0xFF176B5B);

// HOME SCREEN

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoadingRole = true;
  bool _isStaff = false;
  String? _roleError;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    if (mounted) {
      setState(() {
        _isLoadingRole = true;
        _roleError = null;
      });
    }

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('No logged-in user found.');
      }

      final document = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!document.exists) {
        throw Exception('Your account profile could not be found.');
      }

      final role = document.data()?['role'];

      if (role != 'staff' && role != 'student') {
        throw Exception('Your account role is not configured.');
      }

      if (!mounted) return;

      final staff = role == 'staff';

      context.read<IncidentProvider>().startListening(staff: staff);

      setState(() {
        _isStaff = staff;
        _isLoadingRole = false;
        _roleError = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _roleError = error.toString().replaceFirst('Exception: ', '');
        _isLoadingRole = false;
      });
    }
  }

  Future<void> _refreshDashboard() async {
    context.read<IncidentProvider>().stopListening();
    await _loadUserRole();
  }

  Future<void> _logout() async {
    final confirmed = await _confirmLogout(context);

    if (!confirmed || !mounted) return;

    try {
      context.read<IncidentProvider>().stopListening();
      await context.read<AuthProvider>().logout();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Logout failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CampusCare',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'My Profile',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoadingRole
          ? const Center(child: CircularProgressIndicator())
          : _roleError != null
          ? Center(
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
                    Text(
                      'Could not load your account:\n$_roleError',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _refreshDashboard,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            )
          : Consumer<IncidentProvider>(
              builder: (context, provider, child) {
                return RefreshIndicator(
                  onRefresh: _refreshDashboard,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        _isStaff ? 'Staff Dashboard' : 'Student Dashboard',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(user?.email ?? 'Campus community member'),
                      const SizedBox(height: 8),
                      Text(
                        _isStaff
                            ? 'Review and manage campus incident reports.'
                            : 'Report campus problems and track your reports.',
                      ),

                      const SizedBox(height: 24),

                      if (provider.isLoading) const LinearProgressIndicator(),

                      // Dashboard statistics.
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: _isStaff ? 'All reports' : 'My reports',
                              value: provider.totalCount.toString(),
                              icon: Icons.report_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'Resolved',
                              value: provider.resolvedCount.toString(),
                              icon: Icons.check_circle_outline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Pending',
                              value: provider.pendingCount.toString(),
                              icon: Icons.pending_actions,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'In Progress',
                              value: provider.inProgressCount.toString(),
                              icon: Icons.autorenew,
                            ),
                          ),
                        ],
                      ),

                      if (provider.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          provider.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],

                      const SizedBox(height: 28),

                      Text(
                        _isStaff
                            ? 'Incident management'
                            : 'What would you like to do?',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (!_isStaff)
                        _FeatureCard(
                          icon: Icons.add_circle_outline,
                          title: 'Report an incident',
                          description: 'Report problems around your campus.',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ReportIncidentScreen(),
                              ),
                            );
                          },
                        ),

                      _FeatureCard(
                        icon: Icons.list_alt,
                        title: _isStaff ? 'All incidents' : 'My incidents',
                        description: _isStaff
                            ? 'View and review reports from all students.'
                            : 'View and search incidents you submitted.',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const IncidentListScreen(),
                            ),
                          );
                        },
                      ),

                      if (!_isStaff)
                        _FeatureCard(
                          icon: Icons.track_changes,
                          title: 'Track my reports',
                          description:
                              'Check the progress of your submissions.',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const IncidentListScreen(),
                              ),
                            );
                          },
                        ),

                      if (_isStaff)
                        _FeatureCard(
                          icon: Icons.pending_actions,
                          title: 'Manage reports',
                          description:
                              'Review incidents and update their status.',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const IncidentListScreen(),
                              ),
                            );
                          },
                        ),

                      // Profile navigation.
                      _FeatureCard(
                        icon: Icons.person_outline,
                        title: 'My Profile',
                        description: 'View your account information and role.',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: green,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _isStaff
                                      ? 'Help maintain a better campus by '
                                            'reviewing reports and updating '
                                            'their progress.'
                                      : 'Help make your campus safer, '
                                            'cleaner, and more comfortable '
                                            'by reporting problems.',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// PROFILE SCREEN

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await _confirmLogout(context);

    if (!confirmed || !context.mounted) return;

    try {
      context.read<IncidentProvider>().stopListening();
      await context.read<AuthProvider>().logout();
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Logout failed: $error')));
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Not available';

    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }

    if (date == null) return 'Not available';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;

    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: const Center(child: Text('No logged-in account found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: green));
          }

          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Unable to load your profile. Please try again.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data?.data() ?? {};

          final name = (data['name'] as String?)?.trim().isNotEmpty == true
              ? (data['name'] as String).trim()
              : user.displayName?.trim().isNotEmpty == true
              ? user.displayName!.trim()
              : 'CampusCare User';

          final email = user.email ?? 'Email unavailable';
          final role = data['role'] == 'staff' ? 'Staff' : 'Student';
          final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 12),

              // Profile header.
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: green.withValues(alpha: 0.12),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: green,
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      email,
                      style: const TextStyle(color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE1F0EB),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        role,
                        style: const TextStyle(
                          color: green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Account Information',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 14),

              _ProfileInfoCard(
                icon: Icons.person_outline,
                label: 'Full name',
                value: name,
              ),

              _ProfileInfoCard(
                icon: Icons.email_outlined,
                label: 'Email address',
                value: email,
              ),

              _ProfileInfoCard(
                icon: Icons.badge_outlined,
                label: 'Account role',
                value: role,
              ),

              _ProfileInfoCard(
                icon: Icons.calendar_today_outlined,
                label: 'Account created',
                value: _formatDate(data['createdAt']),
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: green,
                    side: const BorderSide(color: green),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// PROFILE INFORMATION CARD

class _ProfileInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: green.withValues(alpha: 0.12),
          child: Icon(icon, color: green),
        ),
        title: Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }
}

// LOGOUT CONFIRMATION

Future<bool> _confirmLogout(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to log out of CampusCare?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout', style: TextStyle(color: green)),
          ),
        ],
      );
    },
  );

  return result == true;
}

// DASHBOARD STATISTICS CARD

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Icon(icon, size: 28, color: green),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }
}

// DASHBOARD FEATURE CARD

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: green.withValues(alpha: 0.12),
          child: Icon(icon, color: green),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(description),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
