import 'package:flutter/material.dart';
import 'package:aina/features/salon/data/models/service.dart';

/// Result of the add/edit service dialog, handed back to the caller
/// to persist via [OwnerRepository]. Kept separate from [Service]
/// itself since a new service has no id yet.
class ServiceFormResult {
  final String name;
  final String? description;
  final double price;
  final int durationMinutes;
  final String? category;

  const ServiceFormResult({
    required this.name,
    this.description,
    required this.price,
    required this.durationMinutes,
    this.category,
  });
}

/// Shows the add/edit service form as a dialog. Pass [existing] to
/// pre-fill for editing; omit it to add a new service. Returns null if
/// the user cancels.
Future<ServiceFormResult?> showServiceFormDialog(
  BuildContext context, {
  Service? existing,
}) {
  final nameController = TextEditingController(text: existing?.name ?? '');
  final descriptionController = TextEditingController(text: existing?.description ?? '');
  final priceController = TextEditingController(text: existing?.price.toStringAsFixed(0) ?? '');
  final durationController = TextEditingController(
    text: existing?.durationMinutes.toString() ?? '',
  );
  final categoryController = TextEditingController(text: existing?.category ?? '');
  final formKey = GlobalKey<FormState>();

  return showDialog<ServiceFormResult>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(existing == null ? 'Add service' : 'Edit service'),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Service name'),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'Price (Rs)'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (double.tryParse(v.trim()) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: durationController,
                      decoration: const InputDecoration(labelText: 'Duration (min)'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (int.tryParse(v.trim()) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category (optional)',
                  hintText: 'Hair, Nails, Skin, Makeup...',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) return;
            Navigator.of(context).pop(
              ServiceFormResult(
                name: nameController.text.trim(),
                description: descriptionController.text.trim(),
                price: double.parse(priceController.text.trim()),
                durationMinutes: int.parse(durationController.text.trim()),
                category: categoryController.text.trim(),
              ),
            );
          },
          child: Text(existing == null ? 'Add' : 'Save'),
        ),
      ],
    ),
  );
}
