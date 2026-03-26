// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/attendance_model.dart';
import '../../models/goal_model.dart';
import '../../models/visit_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../clients/client_list_screen.dart';
import '../visits/report_log_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AttendanceModel? _attendance;
  GoalModel? _goal;
  List<VisitModel> _todayVisits = [];
  bool _loading = true;
  bool _attendanceLoading = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.getTodayAttendance(user.id),
      ApiService.getTodayGoal(user.id),
      ApiService.getTodayVisits(user.id),
    ]);
    if (mounted) {
      setState(() {
        _attendance = results[0] as AttendanceModel?;
        _goal = results[1] as GoalModel?;
        _todayVisits = results[2] as List<VisitModel>;
        _loading = false;
      });
    }
  }

  Future<void> _handleAttendance() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() => _attendanceLoading = true);
    final pos = await LocationService.getCurrentPosition();
    if (pos == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to get location. Check permissions.')),
        );
      }
      setState(() => _attendanceLoading = false);
      return;
    }

    bool success;
    if (_attendance == null || !_attendance!.isCheckedIn) {
      success = await ApiService.checkIn(
        mrId: user.id,
        lat: pos.latitude,
        lng: pos.longitude,
      );
    } else {
      success = await ApiService.checkOut(
        mrId: user.id,
        lat: pos.latitude,
        lng: pos.longitude,
      );
    }

    if (success) await _loadData();
    if (mounted) {
      setState(() => _attendanceLoading = false);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance update failed. Try again.')),
        );
      }
    }
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final screens = [
      _buildHomeContent(user),
      const ClientListScreen(),
      const ReportLogScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: screens[_selectedIndex],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryText,
        unselectedItemColor: AppTheme.secondaryText,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Clients'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHomeContent(user) {
    final checkedIn = _attendance?.isCheckedIn ?? false;
    final checkedOut = _attendance?.isCheckedOut ?? false;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primaryText,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreeting(),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.name ?? '',
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                            ],
                          ),
                        ),
                        // Profile avatar
                        GestureDetector(
                          onTap: () => setState(() => _selectedIndex = 3),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: AppTheme.cardColor,
                            backgroundImage: user?.avatarUrl != null
                                ? NetworkImage(user!.avatarUrl!)
                                : null,
                            child: user?.avatarUrl == null
                                ? Text(
                                    user?.name.isNotEmpty == true
                                        ? user!.name[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryText,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Attendance toggle — in | out
                    _buildAttendanceToggle(checkedIn, checkedOut),

                    const Divider(height: 32),

                    // Today's Activity label
                    Text(
                      "Today's Activity",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),

                    // Big action card with Daily Report, Total Clients, Brochure
                    _buildActivityCard(),

                    const SizedBox(height: 24),

                    // Goal progress
                    if (_goal != null) _buildGoalCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceToggle(bool checkedIn, bool checkedOut) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _attendanceTab(
            label: 'in',
            active: checkedIn,
            onTap: (!checkedIn && !_attendanceLoading) ? _handleAttendance : null,
          ),
          _attendanceTab(
            label: 'out',
            active: checkedOut,
            onTap: (checkedIn && !checkedOut && !_attendanceLoading) ? _handleAttendance : null,
          ),
        ],
      ),
    );
  }

  Widget _attendanceTab({
    required String label,
    required bool active,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppTheme.primaryText : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: _attendanceLoading && label == ((_attendance?.isCheckedIn ?? false) ? 'out' : 'in')
              ? const Center(
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                )
              : Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active ? Colors.white : AppTheme.secondaryText,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildActivityCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Daily Report row
          _activityRow(
            icon: Icons.bar_chart_outlined,
            label: 'Daily Report',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportLogScreen()),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          // Total Clients row
          _activityRow(
            icon: Icons.people_outline,
            label: 'Total Clients',
            trailing: Text(
              _todayVisits.length.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppTheme.primaryText,
              ),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClientListScreen()),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          // Brochure row
          _activityRow(
            icon: Icons.description_outlined,
            label: 'Brochure',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _activityRow({
    required IconData icon,
    required String label,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primaryText),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          trailing ??
              const Icon(Icons.chevron_right, color: AppTheme.secondaryText, size: 20),
        ],
      ),
    );
  }

  Widget _buildGoalCard() {
    final goal = _goal!;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Today's Goal", style: Theme.of(context).textTheme.titleMedium),
              Text(
                '${goal.achieved}/${goal.target}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goal.progress,
              backgroundColor: AppTheme.borderColor,
              color: AppTheme.primaryText,
              minHeight: 6,
            ),
          ),
          if (goal.description != null) ...[
            const SizedBox(height: 8),
            Text(goal.description!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
