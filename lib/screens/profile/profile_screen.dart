// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/attendance_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<AttendanceModel> _attendanceHistory = [];
  bool _attendanceLoading = true;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final history = await ApiService.getAttendanceHistory(user.id);
    if (mounted) {
      setState(() {
        _attendanceHistory = history;
        _attendanceLoading = false;
      });
    }
  }

  Future<void> _pickProfileImage() async {
    // MR can only change profile picture
    final picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null && mounted) {
      // Upload logic would go here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated')),
      );
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Sign out?'),
        content: const Text('You will need to log in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.secondaryText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Sign out', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.cardColor,
                    backgroundImage:
                        user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                    child: user.avatarUrl == null
                        ? Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryText,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickProfileImage,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryText,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AppTheme.background, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Text(user.name, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(user.displayRole,
                style: Theme.of(context).textTheme.bodyMedium),

            const SizedBox(height: 24),

            // Info card
            _buildInfoCard(user),

            const SizedBox(height: 20),

            // Attendance summary card
            _buildAttendanceCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(user) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _infoRow(
              icon: Icons.email_outlined, label: 'Email', value: user.email),
          _divider(),
          _infoRow(
              icon: Icons.location_on_outlined,
              label: 'Region',
              value: user.region ?? '—'),
          _divider(),
          if (user.phone != null)
            _infoRow(
                icon: Icons.phone_outlined, label: 'Phone', value: user.phone!),
          if (user.phone != null) _divider(),
          if (user.dob != null)
            _infoRow(
                icon: Icons.cake_outlined,
                label: 'Date of Birth',
                value: user.dob!),
          if (user.dob != null) _divider(),
          if (user.joinDate != null)
            _infoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Joined',
                value: user.joinDate!),
        ],
      ),
    );
  }

  Widget _infoRow(
      {required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.secondaryText),
          const SizedBox(width: 12),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Divider(height: 1),
      );

  Widget _buildAttendanceCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Attendance', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (_attendanceLoading)
            const Center(
                child: CircularProgressIndicator(
                    color: AppTheme.primaryText, strokeWidth: 2))
          else if (_attendanceHistory.isEmpty)
            Text('No attendance records',
                style: Theme.of(context).textTheme.bodySmall)
          else
            ..._attendanceHistory.take(10).map((a) => _attendanceRow(a)),
        ],
      ),
    );
  }

  Widget _attendanceRow(AttendanceModel a) {
    Color statusColor;
    switch (a.status) {
      case 'present':
        statusColor = AppTheme.success;
        break;
      case 'half_day':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = AppTheme.error;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(a.date, style: Theme.of(context).textTheme.bodyMedium),
          ),
          if (a.checkIn != null)
            Text('In: ${a.checkIn!}',
                style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: 8),
          if (a.checkOut != null)
            Text('Out: ${a.checkOut!}',
                style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: statusColor, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}
