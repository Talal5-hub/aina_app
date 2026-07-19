import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aina/core/routing/route_names.dart';
import 'package:aina/core/theme/app_colors.dart';
import 'package:aina/core/theme/theme_extensions.dart';
import 'package:aina/features/owner/providers/owner_providers.dart';
import 'package:aina/features/profile/providers/profile_providers.dart';

/// Registering a brand-new salon (as opposed to claiming an existing
/// Google-Maps listing via ClaimSalonScreen). If the owner already has
/// at least one salon, the name must match one of their existing
/// salons exactly - this screen enforces that client-side for a fast
/// error message, but `create_owner_salon` re-checks it server-side
/// regardless. When it matches, an email OTP step appears before the
/// salon is actually created.
class CreateSalonScreen extends ConsumerStatefulWidget {
  const CreateSalonScreen({super.key});

  @override
  ConsumerState<CreateSalonScreen> createState() => _CreateSalonScreenState();
}

enum _Step { form, otp }

class _CreateSalonScreenState extends ConsumerState<CreateSalonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController(text: 'Islamabad');
  final _areaController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _otpController = TextEditingController();

  _Step _step = _Step.form;
  bool _isSubmitting = false;
  bool _isSendingOtp = false;
  String? _resolvedError;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _resolvedError = null);

    final ownedSalons = ref.read(myOwnedSalonsProvider).valueOrNull ?? [];
    final name = _nameController.text.trim();

    if (ownedSalons.isEmpty) {
      // First salon: no extra verification needed.
      await _createSalon();
      return;
    }

    final matchesExisting =
        ownedSalons.any((s) => s.name.trim().toLowerCase() == name.toLowerCase());

    if (!matchesExisting) {
      setState(() {
        _resolvedError =
            'Additional locations must use the exact same business name as your existing salon '
            '("${ownedSalons.first.name}"). To register a different business, use a separate account.';
      });
      return;
    }

    // Same name as an existing salon of theirs - verify it's really
    // them before creating another one under that name.
    setState(() => _isSendingOtp = true);
    try {
      await ref.read(ownerRepositoryProvider).sendOwnershipVerificationOtp();
      if (!mounted) return;
      setState(() {
        _isSendingOtp = false;
        _step = _Step.otp;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSendingOtp = false;
        _resolvedError = "Couldn't send a verification code. Please try again.";
      });
    }
  }

  Future<void> _verifyOtpAndCreate() async {
    final code = _otpController.text.trim();
    if (code.length < 6) {
      setState(() => _resolvedError = 'Enter the 6-digit code from your email.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _resolvedError = null;
    });

    try {
      await ref.read(ownerRepositoryProvider).verifyOwnershipOtp(code);
      await _createSalon();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _resolvedError = 'That code is incorrect or expired. Please try again.';
      });
    }
  }

  Future<void> _createSalon() async {
    setState(() {
      _isSubmitting = true;
      _resolvedError = null;
    });

    try {
      await ref.read(ownerRepositoryProvider).createOwnerSalon(
            name: _nameController.text.trim(),
            address: _addressController.text.trim(),
            city: _cityController.text.trim(),
            area: _areaController.text.trim().isEmpty ? null : _areaController.text.trim(),
            phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
            description:
                _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          );

      if (!mounted) return;
      ref.invalidate(myOwnedSalonsProvider);
      // The server just auto-switched active_view to 'business' - pick
      // that up now rather than waiting for the next app launch.
      ref.invalidate(myProfileProvider);
      context.goNamed(RouteNames.myBusiness);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salon registered!')),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('already exists')
          ? 'A salon with this name already exists. Names must be unique.'
          : e.toString().contains('same business name')
              ? 'Additional locations must use the same business name as your existing salon.'
              : "Couldn't register this salon. Please try again.";
      setState(() {
        _isSubmitting = false;
        _resolvedError = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        title: Text(
          _step == _Step.form ? 'Register your salon' : 'Verify it\'s you',
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: _step == _Step.form ? _buildForm(context) : _buildOtpStep(context),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_resolvedError != null) ...[
              _ErrorBanner(message: _resolvedError!),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Salon name'),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'City'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _areaController,
                    decoration: const InputDecoration(labelText: 'Area (optional)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Contact phone (optional)'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_isSubmitting || _isSendingOtp) ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: (_isSubmitting || _isSendingOtp)
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.secondary),
                      )
                    : const Text('Continue', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpStep(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "We've sent a 6-digit code to your account email. Enter it below to confirm "
            "you're the owner of this business before adding another location.",
            style: TextStyle(color: context.textSecondary),
          ),
          const SizedBox(height: 20),
          if (_resolvedError != null) ...[
            _ErrorBanner(message: _resolvedError!),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _otpController,
            decoration: const InputDecoration(labelText: '6-digit code'),
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _verifyOtpAndCreate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.secondary),
                    )
                  : const Text('Verify & register', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _step = _Step.form),
              child: const Text('Back'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.error, fontSize: 13)),
    );
  }
}
