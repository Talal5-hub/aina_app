import 'package:flutter/material.dart';
import 'package:aina/features/salon/data/models/salon.dart';

class SalonInfoFormResult {
  final String name;
  final String address;
  final String city;
  final String? area;
  final String? phone;
  final String? description;

  const SalonInfoFormResult({
    required this.name,
    required this.address,
    required this.city,
    this.area,
    this.phone,
    this.description,
  });
}

/// Edits a salon's name/address/contact info. Renaming to a name
/// that's already taken by another salon will be rejected server-side
/// by the database's unique name index - the caller should catch that
/// and show a friendly message rather than this dialog trying to
/// pre-validate uniqueness itself (it has no cheap way to check that).
Future<SalonInfoFormResult?> showSalonInfoFormDialog(
  BuildContext context, {
  required Salon salon,
}) {
  final nameController = TextEditingController(text: salon.name);
  final addressController = TextEditingController(text: salon.address ?? '');
  final cityController = TextEditingController(text: salon.city ?? '');
  final areaController = TextEditingController(text: salon.area ?? '');
  final phoneController = TextEditingController(text: salon.phone ?? '');
  final descriptionController = TextEditingController(text: salon.description ?? '');
  final formKey = GlobalKey<FormState>();

  return showDialog<SalonInfoFormResult>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit salon info'),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Salon name'),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: cityController,
                      decoration: const InputDecoration(labelText: 'City'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: areaController,
                      decoration: const InputDecoration(labelText: 'Area'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Contact phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
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
              SalonInfoFormResult(
                name: nameController.text.trim(),
                address: addressController.text.trim(),
                city: cityController.text.trim(),
                area: areaController.text.trim().isEmpty ? null : areaController.text.trim(),
                phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                description: descriptionController.text.trim().isEmpty
                    ? null
                    : descriptionController.text.trim(),
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
