import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:aina/core/constants/asset_paths.dart';
import 'package:aina/core/routing/route_names.dart';
import 'package:aina/core/theme/app_colors.dart';
import 'package:aina/core/theme/theme_extensions.dart';
import 'package:aina/features/booking/data/models/booking.dart';
import 'package:aina/features/booking/providers/booking_providers.dart';
import 'package:aina/features/salon/presentation/widgets/salon_cover_image.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(myBookingsProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        title: Text(
          'My Bookings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(myBookingsProvider),
        child: bookingsAsync.when(
          data: (bookings) => _BookingsList(bookings: bookings),
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (error, stackTrace) => _ErrorState(
            onRetry: () => ref.invalidate(myBookingsProvider),
          ),
        ),
      ),
    );
  }
}

class _BookingsList extends StatelessWidget {
  const _BookingsList({required this.bookings});

  final List<Booking> bookings;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return const _EmptyState();
    }

    final now = DateTime.now();
    final upcoming = bookings
        .where((b) =>
            b.status != BookingStatus.cancelled &&
            b.status != BookingStatus.completed &&
            b.appointmentDateTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.appointmentDateTime.compareTo(b.appointmentDateTime));

    final other = bookings.where((b) => !upcoming.contains(b)).toList()
      ..sort((a, b) => b.appointmentDateTime.compareTo(a.appointmentDateTime));

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (upcoming.isNotEmpty) ...[
          const _SectionHeader('Upcoming'),
          ...upcoming.map((b) => _BookingCard(booking: b)),
          const SizedBox(height: 8),
        ],
        if (other.isNotEmpty) ...[
          const _SectionHeader('Past & cancelled'),
          ...other.map((b) => _BookingCard(booking: b)),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
      ),
    );
  }
}

class _BookingCard extends ConsumerStatefulWidget {
  const _BookingCard({required this.booking});

  final Booking booking;

  @override
  ConsumerState<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends ConsumerState<_BookingCard> {
  bool _isCancelling = false;

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

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

  Future<void> _confirmAndCancel() async {
    final booking = widget.booking;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this booking?'),
        content: Text(
          "You're about to cancel ${booking.serviceName ?? 'this service'} at "
          "${booking.salonName ?? 'the salon'} on "
          "${_formatDate(booking.appointmentDateTime)}. This can't be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep booking'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);

    try {
      await ref.read(bookingRepositoryProvider).cancelBooking(booking.id);
      if (!mounted) return;
      ref.invalidate(myBookingsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCancelling = false);
      // Surfaces the server's own message (e.g. the 2-day rule) if the
      // Postgres function rejected it - covers the race where the window
      // closed between this screen loading and the tap.
      final message = e.toString().contains('Bookings can only be cancelled')
          ? 'This booking is now within 2 days of the appointment and can no longer be cancelled.'
          : "Couldn't cancel this booking. Please try again.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final statusStyle = _statusStyle(booking.status);
    final appointment = booking.appointmentDateTime;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.outlineColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushNamed(
          RouteNames.salonDetails,
          pathParameters: {'salonId': booking.salonId},
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: SalonCoverImage(
                    name: booking.salonName ?? '?',
                    imageUrl: booking.salonCoverImageUrl,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            booking.serviceName ?? 'Service',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: context.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusStyle.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.salonName ?? '',
                      style: TextStyle(color: context.textSecondary, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 13, color: context.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${_formatDate(appointment)} • ${_formatTime(appointment)}',
                          style: TextStyle(color: context.textSecondary, fontSize: 12.5),
                        ),
                      ],
                    ),
                    if (booking.servicePrice != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Rs ${booking.servicePrice!.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    if (booking.isCancellable)
                      SizedBox(
                        height: 34,
                        child: OutlinedButton.icon(
                          onPressed: _isCancelling ? null : _confirmAndCancel,
                          icon: _isCancelling
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
                                )
                              : const Icon(Icons.close, size: 15),
                          label: Text(_isCancelling ? 'Cancelling…' : 'Cancel booking'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                        ),
                      )
                    else if (booking.status == BookingStatus.pending ||
                        booking.status == BookingStatus.confirmed)
                      Text(
                        "Can't be cancelled within 2 days of the appointment",
                        style: TextStyle(fontSize: 11.5, color: context.textSecondary),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(AssetPaths.emptyStateGeneric, width: 160, height: 160),
                  const SizedBox(height: 16),
                  Text(
                    'No bookings yet',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Once you book an appointment, it will show up here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => context.goNamed(RouteNames.home),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.secondary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    child: const Text('Browse salons', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(AssetPaths.errorStateOffline, width: 160, height: 160),
                  const SizedBox(height: 16),
                  Text(
                    "Couldn't load bookings",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Check your connection and try again.',
                    style: TextStyle(color: context.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: onRetry,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.textPrimary,
                      side: BorderSide(color: context.outlineColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
