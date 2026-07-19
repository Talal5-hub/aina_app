import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aina/core/theme/app_colors.dart';
import 'package:aina/core/theme/theme_extensions.dart';
import 'package:aina/features/booking/data/models/booking.dart';
import 'package:aina/features/owner/data/models/owner_booking.dart';
import 'package:aina/features/owner/presentation/widgets/salon_info_form_dialog.dart';
import 'package:aina/features/owner/presentation/widgets/service_form_dialog.dart';
import 'package:aina/features/owner/providers/owner_providers.dart';
import 'package:aina/features/salon/data/models/service.dart';
import 'package:aina/features/salon/providers/salon_providers.dart';

class SalonManagementScreen extends ConsumerWidget {
  const SalonManagementScreen({super.key, required this.salonId});

  final String salonId;

  Future<void> _editSalonInfo(BuildContext context, WidgetRef ref) async {
    final salon = ref.read(salonDetailsProvider(salonId)).valueOrNull;
    if (salon == null) return;

    final result = await showSalonInfoFormDialog(context, salon: salon);
    if (result == null) return;

    try {
      await ref.read(ownerRepositoryProvider).updateSalonInfo(
            salonId: salonId,
            name: result.name,
            address: result.address,
            city: result.city,
            area: result.area,
            phone: result.phone,
            description: result.description,
          );
      ref.invalidate(salonDetailsProvider(salonId));
      ref.invalidate(myOwnedSalonsProvider);
    } catch (e) {
      if (!context.mounted) return;
      final message = e.toString().contains('duplicate key') || e.toString().contains('unique')
          ? 'A salon with this name already exists. Please choose a different name.'
          : "Couldn't update salon info. Please try again.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salonAsync = ref.watch(salonDetailsProvider(salonId));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.bgColor,
        appBar: AppBar(
          backgroundColor: context.bgColor,
          elevation: 0,
          title: Text(
            salonAsync.valueOrNull?.name ?? 'Manage salon',
            style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.edit_outlined, color: context.textSecondary),
              tooltip: 'Edit salon info',
              onPressed: () => _editSalonInfo(context, ref),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Bookings'),
              Tab(text: 'Services'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BookingsTab(salonId: salonId),
            _ServicesTab(salonId: salonId),
          ],
        ),
      ),
    );
  }
}

class _BookingsTab extends ConsumerWidget {
  const _BookingsTab({required this.salonId});

  final String salonId;

  ({String label, Color color}) _statusStyle(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return (label: 'Pending', color: AppColors.warning);
      case BookingStatus.confirmed:
        return (label: 'Confirmed', color: AppColors.accent);
      case BookingStatus.completed:
        return (label: 'Completed', color: AppColors.success);
      case BookingStatus.cancelled:
        return (label: 'Cancelled', color: AppColors.error);
    }
  }

  String _formatDateTime(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day} ${months[date.month - 1]} · $hour:$minute $period';
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    String bookingId,
    BookingStatus newStatus,
  ) async {
    try {
      await ref.read(ownerRepositoryProvider).updateBookingStatus(bookingId, newStatus);
      ref.invalidate(salonBookingsProvider(salonId));
    } catch (e) {
      // Debug-only: prints the real Postgrest error (missing function,
      // RLS denial, bad column name, etc.) instead of only ever showing
      // the generic SnackBar text below.
      assert(() {
        debugPrint('updateBookingStatus($bookingId, $newStatus) failed: $e');
        return true;
      }());
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't update this booking. Please try again."),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(salonBookingsProvider(salonId));

    return bookingsAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) {
          return Center(
            child: Text('No bookings yet.', style: TextStyle(color: context.textSecondary)),
          );
        }
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => ref.invalidate(salonBookingsProvider(salonId)),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final ob = bookings[index];
              final booking = ob.booking;
              final statusStyle = _statusStyle(booking.status);
              final canConfirm = booking.status == BookingStatus.pending;
              final canComplete = booking.status == BookingStatus.confirmed;
              final canCancel = booking.status == BookingStatus.pending ||
                  booking.status == BookingStatus.confirmed;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.outlineColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            booking.serviceName ?? 'Service',
                            style: TextStyle(fontWeight: FontWeight.w600, color: context.textPrimary),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusStyle.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusStyle.label,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusStyle.color),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ob.customerName?.isNotEmpty == true ? ob.customerName! : 'Customer',
                      style: TextStyle(color: context.textPrimary, fontSize: 13.5),
                    ),
                    if (ob.customerPhone != null && ob.customerPhone!.isNotEmpty)
                      Row(
                        children: [
                          Expanded(
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                ob.customerPhone!,
                                style: TextStyle(color: context.textSecondary, fontSize: 12.5),
                              ),
                            ),
                          ),
                          _ContactIconButton(
                            icon: Icons.call_outlined,
                            onPressed: () => launchUrl(Uri.parse('tel:${ob.customerPhone}')),
                          ),
                          const SizedBox(width: 4),
                          _ContactIconButton(
                            icon: Icons.chat_outlined,
                            onPressed: () => launchUrl(
                              Uri.parse('https://wa.me/${ob.customerPhone!.replaceAll('+', '').replaceAll(' ', '')}'),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDateTime(booking.appointmentDateTime),
                      style: TextStyle(color: context.textSecondary, fontSize: 12.5),
                    ),
                    if (booking.servicePrice != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Rs ${booking.servicePrice!.toStringAsFixed(0)}',
                          style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    if (canConfirm || canComplete || canCancel) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (canConfirm)
                            OutlinedButton(
                              onPressed: () => _updateStatus(context, ref, booking.id, BookingStatus.confirmed),
                              style: OutlinedButton.styleFrom(foregroundColor: AppColors.accent),
                              child: const Text('Confirm'),
                            ),
                          if (canComplete)
                            OutlinedButton(
                              onPressed: () => _updateStatus(context, ref, booking.id, BookingStatus.completed),
                              style: OutlinedButton.styleFrom(foregroundColor: AppColors.success),
                              child: const Text('Mark completed'),
                            ),
                          if (canCancel)
                            OutlinedButton(
                              onPressed: () => _updateStatus(context, ref, booking.id, BookingStatus.cancelled),
                              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                              child: const Text('Cancel'),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(
        child: Text("Couldn't load bookings.", style: TextStyle(color: context.textSecondary)),
      ),
    );
  }
}

class _ServicesTab extends ConsumerWidget {
  const _ServicesTab({required this.salonId});

  final String salonId;

  Future<void> _addService(BuildContext context, WidgetRef ref) async {
    final result = await showServiceFormDialog(context);
    if (result == null) return;

    try {
      await ref.read(ownerRepositoryProvider).addService(
            salonId: salonId,
            name: result.name,
            description: result.description,
            price: result.price,
            durationMinutes: result.durationMinutes,
            category: result.category,
          );
      ref.invalidate(salonServicesProvider(salonId));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't add service. Please try again."),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _editService(BuildContext context, WidgetRef ref, Service service) async {
    final result = await showServiceFormDialog(context, existing: service);
    if (result == null) return;

    try {
      await ref.read(ownerRepositoryProvider).updateService(
            serviceId: service.id,
            name: result.name,
            description: result.description,
            price: result.price,
            durationMinutes: result.durationMinutes,
            category: result.category,
          );
      ref.invalidate(salonServicesProvider(salonId));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't update service. Please try again."),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _deleteService(BuildContext context, WidgetRef ref, Service service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this service?'),
        content: Text('This removes "${service.name}" from your menu. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(ownerRepositoryProvider).deleteService(service.id);
      ref.invalidate(salonServicesProvider(salonId));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't delete service. Please try again."),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(salonServicesProvider(salonId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addService(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.secondary,
        icon: const Icon(Icons.add),
        label: const Text('Add service'),
      ),
      body: servicesAsync.when(
        data: (services) {
          if (services.isEmpty) {
            return Center(
              child: Text('No services yet. Tap "Add service" to create one.',
                  style: TextStyle(color: context.textSecondary), textAlign: TextAlign.center),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.outlineColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(service.name,
                              style: TextStyle(fontWeight: FontWeight.w600, color: context.textPrimary)),
                          const SizedBox(height: 2),
                          Text('Rs ${service.price.toStringAsFixed(0)} · ${service.durationMinutes} min',
                              style: TextStyle(color: context.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: context.textSecondary, size: 20),
                      onPressed: () => _editService(context, ref, service),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                      onPressed: () => _deleteService(context, ref, service),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Text("Couldn't load services.", style: TextStyle(color: context.textSecondary)),
        ),
      ),
    );
  }
}

class _ContactIconButton extends StatelessWidget {
  const _ContactIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.accent),
      ),
    );
  }
}
