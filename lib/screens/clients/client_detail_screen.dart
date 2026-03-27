// lib/screens/clients/client_detail_screen.dart
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
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  String? _activeVisitId;

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
    String? activeVisitId;
    if (mounted) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        final todayVisits = await ApiService.getTodayVisits(user.id);
        try {
          final activeVisit = todayVisits.firstWhere((v) => v.clientId == widget.client.id && v.checkOut == null);
          activeVisitId = activeVisit.id;
        } catch (_) {}
      }
      setState(() {
        _history = visits;
        _historyLoading = false;
        _activeVisitId = activeVisitId;
      });
    }
  }

  Future<void> _call() async {
    if (widget.client.phone == null) return;

    final uri = Uri.parse('tel:${widget.client.phone}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch dialer')),
      );
    }
  }

  Future<void> _openDirections() async {
    final lat = widget.client.lat;
    final lng = widget.client.lng;

    if (lat == null || lng == null) return;

    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open directions')),
      );
    }
  }

  Future<void> _handleCheckIn() async {
    if (_activeVisitId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VisitLoggerScreen(
            client: widget.client,
            visitId: _activeVisitId!,
          ),
        ),
      ).then((_) {
        setState(() => _historyLoading = true);
        _loadHistory();
      });
      return;
    }

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() => _checkInLoading = true);

    final pos = await LocationService.getCurrentPosition();

    if (pos == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to get location.')),
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checked In successfully. Tap Check Out when done.')),
      );
      setState(() {
        _activeVisitId = result['visitId'];
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Check-in failed'),
        ),
      );
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
          Container(
            color: AppTheme.background,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryText,
              unselectedLabelColor: AppTheme.secondaryText,
              indicatorColor: AppTheme.primaryText,
              indicatorWeight: 2,
              tabs: const [
                Tab(text: 'About'),
                Tab(text: 'History')
              ],
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
          _buildMapSection(client),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (client.address != null)
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16),
                      const SizedBox(width: 6),
                      Expanded(child: Text(client.address!)),
                    ],
                  ),

                const SizedBox(height: 12),

                if (client.phone != null)
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 16),
                      const SizedBox(width: 6),
                      Text(client.phone!),
                    ],
                  ),

                if (client.specialty != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.work_outline, size: 16),
                      const SizedBox(width: 6),
                      Text(client.specialty!),
                    ],
                  ),
                ],

                const SizedBox(height: 24),

                Row(
                  children: [
                    _actionButton(
                      label: 'Call',
                      onTap: _call,
                    ),
                    const SizedBox(width: 10),
                    _actionButton(
                      label: _activeVisitId == null ? 'Check In' : 'Check Out',
                      onTap: _checkInLoading ? null : _handleCheckIn,
                      filled: true,
                      loading: _checkInLoading,
                    ),
                    const SizedBox(width: 10),
                    _actionButton(
                      label: 'Directions',
                      onTap: _openDirections,
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
    if (client.lat == null || client.lng == null) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text('No location data'),
      );
    }

    final position = LatLng(client.lat!, client.lng!);

    return SizedBox(
      height: 200,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: position,
          zoom: 15,
        ),
        markers: {
          Marker(
            markerId: const MarkerId('client'),
            position: position,
          ),
        },
        zoomControlsEnabled: false,
        myLocationButtonEnabled: false,
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
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: filled
                ? AppTheme.primaryText
                : AppTheme.cardColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: loading
              ? const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: filled
                        ? Colors.white
                        : AppTheme.primaryText,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_historyLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_history.isEmpty) {
      return const Center(child: Text('No visit history yet'));
    }

    return ListView.builder(
      itemCount: _history.length,
      itemBuilder: (_, i) {
        final visit = _history[i];
        return ListTile(
          title: Text(visit.date),
          subtitle: Text(visit.products.join(', ')),
        );
      },
    );
  }
}