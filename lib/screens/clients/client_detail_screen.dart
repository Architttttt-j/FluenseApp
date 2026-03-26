// lib/screens/clients/client_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/client_model.dart';
import '../../models/visit_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../visits/visit_logger_screen.dart';

class ClientDetailScreen extends StatefulWidget {
  final ClientModel client;

  const ClientDetailScreen({super.key, required this.client});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<VisitModel> _history = [];
  bool _historyLoading = true;
  bool _checkInLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final visits = await ApiService.getClientVisitHistory(widget.client.id);
    if (mounted) setState(() { _history = visits; _historyLoading = false; });
  }

  Future<void> _call() async {
    if (widget.client.phone == null) return;
    final uri = Uri.parse('tel:${widget.client.phone}');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  Future<void> _openDirections() async {
    final lat = widget.client.lat;
    final lng = widget.client.lng;
    if (lat == null || lng == null) return;
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  Future<void> _handleCheckIn() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    setState(() => _checkInLoading = true);
    final pos = await LocationService.getCurrentPosition();
    if (pos == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to get location.')));
      }
      setState(() => _checkInLoading = false);
      return;
    }
    final result = await ApiService.startVisit(
      mrId: user.id,
      clientId: widget.client.id,
      lat: pos.latitude,
      lng: pos.longitude,
    );
    setState(() => _checkInLoading = false);
    if (result['success'] == true && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VisitLoggerScreen(
            client: widget.client,
            visitId: result['visitId'],
          ),
        ),
      ).then((_) => _loadHistory());
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Check-in failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = widget.client;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(client.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            color: AppTheme.background,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryText,
              unselectedLabelColor: AppTheme.secondaryText,
              indicatorColor: AppTheme.primaryText,
              indicatorWeight: 2,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: const [Tab(text: 'About'), Tab(text: 'History')],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAboutTab(client),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab(ClientModel client) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map placeholder (replace with google_maps_flutter widget)
          _buildMapSection(client),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Address
                if (client.address != null)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.secondaryText),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(client.address!, style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    ],
                  ),

                const SizedBox(height: 12),

                // Phone
                if (client.phone != null)
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 16, color: AppTheme.secondaryText),
                      const SizedBox(width: 6),
                      Text('Phn no. ${client.phone}',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),

                if (client.specialty != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.work_outline, size: 16, color: AppTheme.secondaryText),
                      const SizedBox(width: 6),
                      Text(client.specialty!,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ],

                const SizedBox(height: 24),

                // Action buttons — call / check in/out / direction
                Row(
                  children: [
                    _actionButton(
                      label: 'call',
                      onTap: _call,
                      filled: false,
                    ),
                    const SizedBox(width: 10),
                    _actionButton(
                      label: 'check in / out',
                      onTap: _checkInLoading ? null : _handleCheckIn,
                      filled: true,
                      loading: _checkInLoading,
                    ),
                    const SizedBox(width: 10),
                    _actionButton(
                      label: 'Direction',
                      onTap: _openDirections,
                      filled: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection(ClientModel client) {
    // If google maps key is configured, use GoogleMap widget here
    // For now showing a static placeholder
    return Container(
      height: 200,
      width: double.infinity,
      color: AppTheme.cardColor,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (client.lat != null && client.lng != null)
            // Placeholder map view — replace with GoogleMap widget
            Container(
              color: const Color(0xFFE8E4DE),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map_outlined, size: 48, color: AppTheme.secondaryText),
                  const SizedBox(height: 8),
                  Text(
                    '${client.lat!.toStringAsFixed(4)}, ${client.lng!.toStringAsFixed(4)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            )
          else
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_off_outlined, size: 48, color: AppTheme.borderColor),
                const SizedBox(height: 8),
                Text('No location data', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    VoidCallback? onTap,
    bool filled = false,
    bool loading = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: filled ? AppTheme.primaryText : AppTheme.cardColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: loading
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
                    color: filled ? Colors.white : AppTheme.primaryText,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_historyLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryText));
    }
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history, size: 48, color: AppTheme.borderColor),
            const SizedBox(height: 12),
            Text('No visit history yet', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildHistoryCard(_history[i]),
    );
  }

  Widget _buildHistoryCard(VisitModel visit) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(visit.date, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
              if (visit.mrName != null)
                Text(visit.mrName!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          if (visit.checkIn != null) ...[
            const SizedBox(height: 4),
            Text(visit.checkIn!, style: Theme.of(context).textTheme.bodySmall),
          ],
          if (visit.products.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              visit.products.join(' , '),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
