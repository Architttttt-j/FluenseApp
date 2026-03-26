// lib/screens/visits/product_detail_sheet.dart
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

class ProductDetailSheet extends StatefulWidget {
  final String productName;
  final Map<String, dynamic> initial;

  const ProductDetailSheet({
    super.key,
    required this.productName,
    required this.initial,
  });

  @override
  State<ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<ProductDetailSheet> {
  late bool _explained;
  late bool _available;
  late TextEditingController _remarksController;

  @override
  void initState() {
    super.initState();
    _explained = widget.initial['explained'] ?? false;
    _available = widget.initial['available'] ?? false;
    _remarksController = TextEditingController(text: widget.initial['remarks'] ?? '');
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(widget.productName,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),

          // Explained checkbox
          _checkRow(
            label: 'explained',
            value: _explained,
            onChanged: (v) => setState(() => _explained = v!),
          ),
          const SizedBox(height: 12),

          // Available checkbox
          _checkRow(
            label: 'available',
            value: _available,
            onChanged: (v) => setState(() => _available = v!),
          ),
          const SizedBox(height: 16),

          // Remarks
          Text('remarks', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _remarksController,
            maxLines: 2,
            decoration: const InputDecoration(hintText: 'Add remarks...'),
          ),
          const SizedBox(height: 20),

          // Confirm
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                'explained': _explained,
                'available': _available,
                'remarks': _remarksController.text.trim(),
              }),
              child: const Text('Confirm'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkRow({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        Checkbox(
          value: value,
          activeColor: AppTheme.primaryText,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
