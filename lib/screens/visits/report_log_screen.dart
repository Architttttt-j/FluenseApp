// lib/screens/visits/report_log_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/visit_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class ReportLogScreen extends StatefulWidget {
  const ReportLogScreen({super.key});

  @override
  State<ReportLogScreen> createState() => _ReportLogScreenState();
}

class _ReportLogScreenState extends State<ReportLogScreen> {
  List<VisitModel> _visits = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    setState(() => _loading = true);
    final visits = await ApiService.getTodayVisits(user.id);
    if (mounted) setState(() { _visits = visits; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Report Log')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryText))
          : _visits.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.assignment_outlined, size: 52, color: AppTheme.borderColor),
                      const SizedBox(height: 12),
                      Text('No visits logged today', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReports,
                  color: AppTheme.primaryText,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _visits.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _buildReportCard(_visits[i]),
                  ),
                ),
    );
  }

  Widget _buildReportCard(VisitModel visit) {
    final date = visit.date;
    final dayName = _getDayName(date);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$dayName, $date',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
              if (visit.checkIn != null && visit.checkOut != null)
                Text('${visit.checkIn} – ${visit.checkOut}',
                    style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 6),
          // Client type summary
          if (visit.clientType != null)
            Text(
              '1 ${_capitalize(visit.clientType!)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          // Products
          if (visit.products.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Products : ${visit.products.join(' , ')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (visit.notes != null && visit.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(visit.notes!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  String _getDayName(String date) {
    try {
      final parts = date.split('-');
      if (parts.length != 3) return '';
      final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[d.weekday - 1];
    } catch (_) {
      return '';
    }
  }

  String _capitalize(String s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;
}
