// lib/screens/visits/visit_logger_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../config/app_theme.dart';
import '../../models/client_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import 'product_detail_sheet.dart';

class VisitLoggerScreen extends StatefulWidget {
  final ClientModel client;
  final String visitId;

  const VisitLoggerScreen({
    super.key,
    required this.client,
    required this.visitId,
  });

  @override
  State<VisitLoggerScreen> createState() => _VisitLoggerScreenState();
}

class _VisitLoggerScreenState extends State<VisitLoggerScreen> {
  final _notesController = TextEditingController();

  // Products: productName -> {explained: bool, available: bool, remarks: String}
  final Map<String, Map<String, dynamic>> _productDetails = {};
  final List<String> _selectedProducts = [];

  // Collaborator
  List<UserModel> _regionMRs = [];
  String? _selectedCollaboratorId;
  bool _collaboratorsLoading = false;

  // Image
  File? _image;
  final _picker = ImagePicker();

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadRegionMRs();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadRegionMRs() async {
    final user = context.read<AuthProvider>().user;
    if (user?.regionId == null) return;
    setState(() => _collaboratorsLoading = true);
    final mrs = await ApiService.getMRsInRegion(user!.regionId!);
    if (mounted) {
      setState(() {
        _regionMRs = mrs.where((m) => m.id != user.id).toList();
        _collaboratorsLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (picked != null && mounted) setState(() => _image = File(picked.path));
  }

  Future<void> _openProductSheet(String product) async {
    final existing = _productDetails[product] ?? {'explained': false, 'available': false, 'remarks': ''};
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductDetailSheet(
        productName: product,
        initial: existing,
      ),
    );
    if (result != null && mounted) {
      setState(() => _productDetails[product] = result);
    }
  }

  Future<void> _submit() async {
    if (_selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one product')),
      );
      return;
    }
    setState(() => _submitting = true);
    final pos = await LocationService.getCurrentPosition();
    if (pos == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to get location.')));
      }
      setState(() => _submitting = false);
      return;
    }
    final success = await ApiService.endVisit(
      visitId: widget.visitId,
      lat: pos.latitude,
      lng: pos.longitude,
      products: _selectedProducts,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      collaboratorMrId: _selectedCollaboratorId,
    );
    setState(() => _submitting = false);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visit logged successfully!')),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit visit. Try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.client.name),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryText))
                : const Text('Done', style: TextStyle(color: AppTheme.primaryText, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client name chip
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: AppTheme.secondaryText),
                  const SizedBox(width: 8),
                  Text(widget.client.name, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Work with (collaborator)
            _buildCollaboratorSection(),

            const SizedBox(height: 16),

            // Products
            _buildProductsSection(),

            const SizedBox(height: 16),

            // Notes
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Notes (optional)...'),
            ),

            const SizedBox(height: 16),

            // Image upload
            _buildImageSection(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCollaboratorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Work with', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: _collaboratorsLoading
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator(color: AppTheme.primaryText, strokeWidth: 2)),
                )
              : _regionMRs.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No other MRs in region', style: TextStyle(color: AppTheme.secondaryText)),
                    )
                  : Column(
                      children: _regionMRs.map((mr) => _collaboratorTile(mr)).toList(),
                    ),
        ),
      ],
    );
  }

  Widget _collaboratorTile(UserModel mr) {
    final selected = _selectedCollaboratorId == mr.id;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedCollaboratorId = selected ? null : mr.id;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.borderColor, width: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(child: Text(mr.name, style: Theme.of(context).textTheme.titleMedium)),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppTheme.primaryText : AppTheme.borderColor,
                  width: 2,
                ),
                color: selected ? AppTheme.primaryText : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Products', style: Theme.of(context).textTheme.titleMedium),
            GestureDetector(
              onTap: _showProductPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('add products',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.primaryText)),
              ),
            ),
          ],
        ),
        if (_selectedProducts.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: _selectedProducts.map((p) => _productTile(p)).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _productTile(String product) {
    final details = _productDetails[product];
    return GestureDetector(
      onTap: () => _openProductSheet(product),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.borderColor, width: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product, style: Theme.of(context).textTheme.titleMedium),
                  if (details != null)
                    Text(
                      [
                        if (details['explained'] == true) 'Explained',
                        if (details['available'] == true) 'Available',
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppTheme.secondaryText),
          ],
        ),
      ),
    );
  }

  void _showProductPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select Products', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              ...AppConfig.products.map((p) {
                final selected = _selectedProducts.contains(p);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(p, style: Theme.of(context).textTheme.titleMedium),
                  trailing: Checkbox(
                    value: selected,
                    activeColor: AppTheme.primaryText,
                    onChanged: (v) {
                      setModal(() {
                        if (v == true) {
                          _selectedProducts.add(p);
                        } else {
                          _selectedProducts.remove(p);
                          _productDetails.remove(p);
                        }
                      });
                      setState(() {});
                    },
                  ),
                );
              }),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Upload Image', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: _image != null ? 200 : 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: _image == null
                  ? Border.all(color: AppTheme.borderColor, width: 1)
                  : null,
            ),
            child: _image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_image!, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt_outlined, size: 28, color: AppTheme.secondaryText),
                      const SizedBox(height: 6),
                      Text('Tap to take photo',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
