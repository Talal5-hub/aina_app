import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aina/core/routing/route_names.dart';
import 'package:aina/core/services/supabase_service.dart';
import 'package:aina/core/theme/app_colors.dart';
import 'package:aina/core/theme/theme_extensions.dart';
import 'package:aina/core/view_mode/active_view_provider.dart';
import 'package:aina/features/auth/providers/auth_providers.dart';
import 'package:aina/features/profile/data/models/profile.dart';
import 'package:aina/features/profile/providers/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
    final email = SupabaseService.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        title: Text(
          'Profile',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: context.textSecondary),
            tooltip: 'Settings',
            onPressed: () => context.pushNamed(RouteNames.settings),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) => _ProfileContent(profile: profile, email: email),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text("Couldn't load your profile.",
                    style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ref.invalidate(myProfileProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends ConsumerStatefulWidget {
  const _ProfileContent({required this.profile, required this.email});

  final Profile profile;
  final String email;

  @override
  ConsumerState<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends ConsumerState<_ProfileContent> {
  bool _isSigningOut = false;

  String get _initials {
    final name = widget.profile.fullName?.trim();
    if (name == null || name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: widget.profile.fullName ?? '');
    final phoneController = TextEditingController(text: widget.profile.phone ?? '');
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit profile'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full name'),
                textCapitalization: TextCapitalization.words,
                // Defense-in-depth only — the server's validate_profile_row
                // trigger is the actual, non-bypassable check.
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) return null; // optional field
                  if (trimmed.length > 100) return 'Name is too long';
                  if (!RegExp(r"^[a-zA-Z\s.'-]+$").hasMatch(trimmed)) {
                    return 'Name contains invalid characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) return null; // optional field
                  final digitCount = trimmed.replaceAll(RegExp(r'[^0-9]'), '').length;
                  if (digitCount < 7 || digitCount > 15) return 'Enter a valid phone number';
                  if (!RegExp(r'^[0-9+()\-\s]+$').hasMatch(trimmed)) {
                    return 'Phone contains invalid characters';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(context).pop(true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true || !mounted) return;

    try {
      await ref.read(profileRepositoryProvider).updateMyProfile(
            fullName: nameController.text.trim(),
            phone: phoneController.text.trim(),
          );
      ref.invalidate(myProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't update your profile. Please try again."),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text("You'll need to sign back in to book or view your appointments."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSigningOut = true);
    await ref.read(authRepositoryProvider).signOut();
    // No further setState needed - the router's auth-state listener
    // redirects to login once the session clears.
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary,
                backgroundImage: widget.profile.avatarUrl != null
                    ? NetworkImage(widget.profile.avatarUrl!)
                    : null,
                child: widget.profile.avatarUrl == null
                    ? Text(
                        _initials,
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                widget.profile.fullName?.isNotEmpty == true ? widget.profile.fullName! : 'Add your name',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(widget.email, style: TextStyle(color: context.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _editProfile,
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Edit profile'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryDark,
            side: BorderSide(color: context.outlineColor),
            padding: const EdgeInsets.symmetric(vertical: 14),
            minimumSize: const Size.fromHeight(0),
          ),
        ),
        const SizedBox(height: 24),
        _ViewSwitcher(),
        const SizedBox(height: 16),
        _MenuTile(
          icon: Icons.calendar_today_outlined,
          label: 'My Bookings',
          onTap: () => context.pushNamed(RouteNames.myBookings),
        ),
        _MenuTile(
          icon: Icons.favorite_border,
          label: 'Favorites',
          onTap: () => context.pushNamed(RouteNames.favorites),
        ),
        _MenuTile(
          icon: Icons.storefront_outlined,
          label: 'My Business',
          onTap: () => context.pushNamed(RouteNames.myBusiness),
        ),
        _MenuTile(
          icon: Icons.settings_outlined,
          label: 'Settings',
          onTap: () => context.pushNamed(RouteNames.settings),
        ),
        const SizedBox(height: 12),
        _MenuTile(
          icon: Icons.logout,
          label: _isSigningOut ? 'Signing out…' : 'Sign out',
          iconColor: AppColors.error,
          labelColor: AppColors.error,
          onTap: _isSigningOut ? null : _confirmSignOut,
        ),
      ],
    );
  }
}

/// Lets the person flip between the Customer and Business experiences
/// at any time - see ActiveViewNotifier. Switching navigates back to
/// `/home`, where RoleGate re-evaluates and shows the matching screen.
class _ViewSwitcher extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // valueOrNull: while the initial fetch is in flight, neither option
    // shows as selected rather than blocking on a spinner here - a
    // tap still works immediately once resolved.
    final activeView = ref.watch(activeViewProvider).valueOrNull;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.outlineColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ViewSwitcherOption(
              label: 'Customer',
              icon: Icons.person_outline,
              isSelected: activeView == ActiveView.customer,
              onTap: () {
                ref.read(activeViewProvider.notifier).setView(ActiveView.customer);
                context.goNamed(RouteNames.home);
              },
            ),
          ),
          Expanded(
            child: _ViewSwitcherOption(
              label: 'Business',
              icon: Icons.storefront_outlined,
              isSelected: activeView == ActiveView.business,
              onTap: () {
                ref.read(activeViewProvider.notifier).setView(ActiveView.business);
                context.goNamed(RouteNames.home);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewSwitcherOption extends StatelessWidget {
  const _ViewSwitcherOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: isSelected ? AppColors.secondary : context.textSecondary),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.secondary : context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: context.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.outlineColor),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? context.textPrimary),
        title: Text(label, style: TextStyle(color: labelColor ?? context.textPrimary, fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.chevron_right, color: context.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
