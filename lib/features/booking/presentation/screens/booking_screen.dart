import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aina/core/routing/route_names.dart';
import 'package:aina/core/theme/app_colors.dart';
import 'package:aina/core/theme/theme_extensions.dart';
import 'package:aina/features/booking/providers/booking_providers.dart';
import 'package:aina/features/salon/data/models/service.dart';

/// Passed via GoRouter's `extra` when navigating from the salon details
/// screen, so this screen doesn't need to re-fetch the service it
/// already has in memory.
class BookingScreenArgs {
  final Service service;
  final String salonName;

  const BookingScreenArgs({required this.service, required this.salonName});
}

class BookingScreen extends ConsumerStatefulWidget {
  final String salonId;
  final BookingScreenArgs? args;

  const BookingScreen({super.key, required this.salonId, this.args});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final _notesController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSubmitting = false;
  bool _bookingConfirmed = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  Future<void> _confirmBooking() async {
    final service = widget.args?.service;
    if (service == null || _selectedDate == null || _selectedTime == null) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(bookingRepositoryProvider).createBooking(
            salonId: widget.salonId,
            serviceId: service.id,
            bookingDate: _selectedDate!,
            bookingTime: _formatTimeOfDay(_selectedTime!),
            notes: _notesController.text.trim(),
          );

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _bookingConfirmed = true;
      });
    } on Exception catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't create booking. Please try again."),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.args?.service;

    if (service == null) {
      // Reached without the expected `extra` (e.g. direct deep link) -
      // nothing meaningful to book, so send back rather than crash.
      return Scaffold(
        backgroundColor: context.bgColor,
        appBar: AppBar(backgroundColor: context.bgColor, elevation: 0),
        body: Center(
          child: Text(
            "This booking link isn't valid.",
            style: TextStyle(color: context.textSecondary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        title: const Text('Book appointment'),
      ),
      body: SafeArea(
        child: _bookingConfirmed ? _buildConfirmation(context) : _buildForm(context, service),
      ),
    );
  }

  Widget _buildForm(BuildContext context, Service service) {
    final canConfirm = _selectedDate != null && _selectedTime != null && !_isSubmitting;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.outlineColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.args!.salonName,
                  style: TextStyle(color: context.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.timer_outlined,
                        size: 16, color: context.textSecondary),
                    const SizedBox(width: 4),
                    Text('${service.durationMinutes} min',
                        style: TextStyle(color: context.textSecondary)),
                    const SizedBox(width: 16),
                    Icon(Icons.payments_outlined,
                        size: 16, color: context.textSecondary),
                    const SizedBox(width: 4),
                    Text('Rs ${service.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Date',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          _PickerTile(
            icon: Icons.calendar_today_outlined,
            label: _selectedDate == null
                ? 'Select a date'
                : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
            onTap: _pickDate,
          ),
          const SizedBox(height: 20),

          Text(
            'Time',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          _PickerTile(
            icon: Icons.access_time,
            label: _selectedTime == null ? 'Select a time' : _selectedTime!.format(context),
            onTap: _pickTime,
          ),
          const SizedBox(height: 20),

          Text(
            'Notes (optional)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Any special requests?',
            ),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: canConfirm ? _confirmBooking : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.secondary,
                disabledBackgroundColor: context.outlineColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.secondary,
                      ),
                    )
                  : const Text(
                      'Confirm booking',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmation(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AnimatedSuccessCheck(),
            const SizedBox(height: 16),
            Text(
              'Booking confirmed!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              "You'll see this appointment in your bookings.",
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textSecondary),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => context.goNamed(RouteNames.home),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Back to home',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A simple scale + fade + checkmark-draw animation, built from plain
/// Flutter widgets rather than a Lottie file - no JSON-parsing risk.
class _AnimatedSuccessCheck extends StatefulWidget {
  @override
  State<_AnimatedSuccessCheck> createState() => _AnimatedSuccessCheckState();
}

class _AnimatedSuccessCheckState extends State<_AnimatedSuccessCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _checkProgress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6, curve: Curves.elasticOut));
    _checkProgress = CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: SizedBox(
            width: 140,
            height: 140,
            child: CustomPaint(
              painter: _CheckCirclePainter(progress: _checkProgress.value),
            ),
          ),
        );
      },
    );
  }
}

class _CheckCirclePainter extends CustomPainter {
  final double progress;

  _CheckCirclePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final circlePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, circlePaint);

    final checkPaint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final p1 = Offset(size.width * 0.28, size.height * 0.52);
    final p2 = Offset(size.width * 0.45, size.height * 0.68);
    final p3 = Offset(size.width * 0.74, size.height * 0.36);

    final path = Path()..moveTo(p1.dx, p1.dy);

    if (progress <= 0.5) {
      final t = (progress / 0.5).clamp(0.0, 1.0);
      path.lineTo(
        p1.dx + (p2.dx - p1.dx) * t,
        p1.dy + (p2.dy - p1.dy) * t,
      );
    } else {
      path.lineTo(p2.dx, p2.dy);
      final t = ((progress - 0.5) / 0.5).clamp(0.0, 1.0);
      path.lineTo(
        p2.dx + (p3.dx - p2.dx) * t,
        p2.dy + (p3.dy - p2.dy) * t,
      );
    }

    canvas.drawPath(path, checkPaint);
  }

  @override
  bool shouldRepaint(covariant _CheckCirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.outlineColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: context.textSecondary),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: context.textPrimary)),
          ],
        ),
      ),
    );
  }
}
