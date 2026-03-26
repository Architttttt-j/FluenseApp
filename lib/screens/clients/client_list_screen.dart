// lib/screens/clients/client_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/client_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'client_detail_screen.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  List<ClientModel> _clients = [];
  List<ClientModel> _filtered = [];
  bool _loading = true;
  String _searchQuery = '';

  final List<String> _tabs = ['Doctor', 'Retailer', 'Stockist'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _applyFilter();
    });
    _loadClients();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    final user = context.read<AuthProvider>().user;
    setState(() => _loading = true);
    final clients = await ApiService.getClients(regionId: user?.regionId);
    if (mounted) {
      setState(() {
        _clients = clients;
        _loading = false;
      });
      _applyFilter();
    }
  }

  void _applyFilter() {
    final type = _tabs[_tabController.index].toLowerCase();
    setState(() {
      _filtered = _clients
          .where((c) =>
              c.type == type &&
              (c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  (c.address ?? '').toLowerCase().contains(_searchQuery.toLowerCase())))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Client List'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Column(
            children: [
              // Search + filter row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) {
                          _searchQuery = v;
                          _applyFilter();
                        },
                        decoration: InputDecoration(
                          hintText: 'Search clients...',
                          prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.secondaryText),
                          filled: true,
                          fillColor: AppTheme.cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.tune, size: 18, color: AppTheme.primaryText),
                    ),
                  ],
                ),
              ),
              // Tab bar
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryText,
                unselectedLabelColor: AppTheme.secondaryText,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                indicatorColor: AppTheme.primaryText,
                indicatorWeight: 2,
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryText))
          : TabBarView(
              controller: _tabController,
              children: List.generate(3, (_) => _buildClientList()),
            ),
    );
  }

  Widget _buildClientList() {
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_search, size: 48, color: AppTheme.borderColor),
            const SizedBox(height: 12),
            Text('No clients found', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadClients,
      color: AppTheme.primaryText,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _buildClientTile(_filtered[i]),
      ),
    );
  }

  Widget _buildClientTile(ClientModel client) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ClientDetailScreen(client: client)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                client.type == 'doctor'
                    ? Icons.medical_services_outlined
                    : client.type == 'retailer'
                        ? Icons.store_outlined
                        : Icons.warehouse_outlined,
                size: 18,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(client.name, style: Theme.of(context).textTheme.titleMedium),
                  if (client.address != null)
                    Text(
                      client.address!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.secondaryText, size: 20),
          ],
        ),
      ),
    );
  }
}
