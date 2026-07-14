import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aina/core/routing/route_names.dart';
import 'package:aina/core/storage/hive_service.dart';
import 'package:aina/core/theme/app_colors.dart';
import 'package:aina/core/theme/theme_extensions.dart';
import 'package:aina/features/favorites/presentation/widgets/favorite_button.dart';
import 'package:aina/features/salon/data/models/salon.dart';
import 'package:aina/features/salon/presentation/widgets/salon_cover_image.dart';
import 'package:aina/features/salon/providers/salon_providers.dart';

const _recentSearchesKey = 'recent_searches';
const _maxRecentSearches = 8;

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Search is the whole point of this screen, so open the keyboard
    // immediately rather than waiting for a tap.
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<String> get _recentSearches {
    final stored = HiveService.get<List<dynamic>>(HiveService.searchHistoryBox, _recentSearchesKey);
    return stored?.cast<String>() ?? const [];
  }

  Future<void> _commitSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final updated = [trimmed, ..._recentSearches.where((s) => s.toLowerCase() != trimmed.toLowerCase())];
    await HiveService.put(
      HiveService.searchHistoryBox,
      _recentSearchesKey,
      updated.take(_maxRecentSearches).toList(),
    );
    setState(() {});
  }

  Future<void> _clearHistory() async {
    await HiveService.delete(HiveService.searchHistoryBox, _recentSearchesKey);
    setState(() {});
  }

  List<Salon> _filter(List<Salon> salons) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return const [];
    return salons.where((s) {
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
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: (value) => setState(() => _query = value),
            onSubmitted: _commitSearch,
            style: TextStyle(color: context.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search salons, areas...',
              hintStyle: TextStyle(color: context.textSecondary),
              filled: true,
              fillColor: context.surfaceColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(Icons.search, size: 20, color: context.textSecondary),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(Icons.close, size: 18, color: context.textSecondary),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
          ),
        ),
      ),
      body: _query.trim().isEmpty
          ? _RecentSearches(
              recentSearches: _recentSearches,
              onTapTerm: (term) {
                _controller.text = term;
                setState(() => _query = term);
                _commitSearch(term);
              },
              onClear: _clearHistory,
            )
          : salonsAsync.when(
              data: (salons) {
                final results = _filter(salons);
                if (results.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No salons match your search.',
                        style: TextStyle(color: context.textSecondary),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: results.length,
                  itemBuilder: (context, index) => _ResultTile(
                    salon: results[index],
                    onTap: () => _commitSearch(_query),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(
                child: Text("Couldn't load salons.", style: TextStyle(color: context.textSecondary)),
              ),
            ),
    );
  }
}

class _RecentSearches extends StatelessWidget {
  const _RecentSearches({
    required this.recentSearches,
    required this.onTapTerm,
    required this.onClear,
  });

  final List<String> recentSearches;
  final ValueChanged<String> onTapTerm;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (recentSearches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Search for a salon by name, area, or city.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textSecondary),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent searches',
                style: TextStyle(fontWeight: FontWeight.w700, color: context.textPrimary),
              ),
              TextButton(onPressed: onClear, child: const Text('Clear')),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recentSearches.map((term) {
              return ActionChip(
                label: Text(term),
                backgroundColor: context.surfaceColor,
                side: BorderSide(color: context.outlineColor),
                onPressed: () => onTapTerm(term),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.salon, required this.onTap});

  final Salon salon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.outlineColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          onTap();
          context.pushNamed(RouteNames.salonDetails, pathParameters: {'salonId': salon.id});
        },
        child: Row(
          children: [
            SizedBox(
              width: 88,
              height: 88,
              child: Stack(
                children: [
                  SalonCoverImage(name: salon.name, imageUrl: salon.coverImageUrl),
                  Positioned(top: 6, right: 6, child: FavoriteButton(salonId: salon.id, size: 16)),
                ],
              ),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: AppColors.ratingStar),
                        const SizedBox(width: 4),
                        Text(
                          '${salon.ratingAvg.toStringAsFixed(1)} (${salon.ratingCount})',
                          style: TextStyle(color: context.textSecondary, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
