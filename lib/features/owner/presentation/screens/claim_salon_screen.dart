import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aina/core/routing/route_names.dart';
import 'package:aina/core/theme/app_colors.dart';
import 'package:aina/core/theme/theme_extensions.dart';
import 'package:aina/features/salon/data/models/salon.dart';
import 'package:aina/features/salon/presentation/widgets/salon_cover_image.dart';
import 'package:aina/features/salon/providers/salon_providers.dart';

/// The owner-only equivalent of the customer SearchScreen: lets a
/// business-owner account find their salon among the still-unclaimed
/// listings so they can claim it, without exposing the full customer
/// browsing experience (no favoriting, no booking, no already-claimed
/// salons cluttering the list - those belong to someone else already).
class ClaimSalonScreen extends ConsumerStatefulWidget {
  const ClaimSalonScreen({super.key});

  @override
  ConsumerState<ClaimSalonScreen> createState() => _ClaimSalonScreenState();
}

class _ClaimSalonScreenState extends ConsumerState<ClaimSalonScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Salon> _filter(List<Salon> salons) {
    final unclaimed = salons.where((s) => !s.isClaimed);
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return unclaimed.toList();
    return unclaimed.where((s) {
      return s.name.toLowerCase().contains(query) ||
          (s.area?.toLowerCase().contains(query) ?? false) ||
          (s.city?.toLowerCase().contains(query) ?? false) ||
          (s.address?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final salonsAsync = ref.watch(salonListProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        title: Text(
          'Find your salon',
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _controller,
              onChanged: (value) => setState(() => _query = value),
              style: TextStyle(color: context.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search by name or area',
                hintStyle: TextStyle(color: context.textSecondary),
                prefixIcon: Icon(Icons.search, color: context.textSecondary),
                filled: true,
                fillColor: context.surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: salonsAsync.when(
              data: (salons) {
                final results = _filter(salons);
                if (results.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        _query.trim().isEmpty
                            ? 'No unclaimed salons right now.'
                            : 'No unclaimed salons match your search.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.textSecondary),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final salon = results[index];
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
                          pathParameters: {'salonId': salon.id},
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: SalonCoverImage(name: salon.name, imageUrl: salon.coverImageUrl),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      salon.name,
                                      style: TextStyle(fontWeight: FontWeight.w600, color: context.textPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      salon.area ?? salon.city ?? '',
                                      style: TextStyle(color: context.textSecondary, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Icon(Icons.chevron_right, color: AppColors.accent),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(
                child: Text("Couldn't load salons.", style: TextStyle(color: context.textSecondary)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
