import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:aina/core/constants/asset_paths.dart';
import 'package:aina/core/routing/route_names.dart';
import 'package:aina/core/theme/app_colors.dart';
import 'package:aina/core/theme/theme_extensions.dart';
import 'package:aina/features/favorites/presentation/widgets/favorite_button.dart';
import 'package:aina/features/salon/data/models/salon.dart';
import 'package:aina/features/salon/presentation/widgets/salon_cover_image.dart';
import 'package:aina/features/salon/providers/salon_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedArea; // null = "All"

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Distinct areas present in the fetched salon list, sorted alphabetically.
  /// Derived client-side rather than a separate query - the salon count is
  /// small enough that this is both simpler and avoids an extra round trip.
  List<String> _areasFrom(List<Salon> salons) {
    final areas = salons
        .map((s) => s.area)
        .whereType<String>()
        .where((a) => a.trim().isNotEmpty)
        .toSet()
        .toList();
    areas.sort();
    return areas;
  }

  List<Salon> _applyFilters(List<Salon> salons) {
    return salons.where((salon) {
      final matchesArea = _selectedArea == null || salon.area == _selectedArea;
      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          salon.name.toLowerCase().contains(query) ||
          (salon.area?.toLowerCase().contains(query) ?? false) ||
          (salon.city?.toLowerCase().contains(query) ?? false);
      return matchesArea && matchesSearch;
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
          'Aina',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: context.textSecondary),
            tooltip: 'Search',
            onPressed: () => context.pushNamed(RouteNames.search),
          ),
          IconButton(
            icon: Icon(Icons.favorite_border, color: context.textSecondary),
            tooltip: 'Favorites',
            onPressed: () => context.pushNamed(RouteNames.favorites),
          ),
          IconButton(
            icon: Icon(Icons.calendar_today_outlined, color: context.textSecondary),
            tooltip: 'My bookings',
            onPressed: () => context.pushNamed(RouteNames.myBookings),
          ),
          IconButton(
            icon: Icon(Icons.person_outline, color: context.textSecondary),
            tooltip: 'Profile',
            onPressed: () => context.pushNamed(RouteNames.profile),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(salonListProvider),
        child: salonsAsync.when(
          data: (allSalons) {
            final areas = _areasFrom(allSalons);
            final filtered = _applyFilters(allSalons);

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      style: TextStyle(color: context.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search salons or areas',
                        hintStyle: TextStyle(color: context.textSecondary),
                        prefixIcon: Icon(Icons.search, color: context.textSecondary),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                icon: Icon(Icons.clear, color: context.textSecondary),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              ),
                        filled: true,
                        fillColor: context.surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.outlineColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.outlineColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ),
                ),

                if (areas.isNotEmpty)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: areas.length + 1, // +1 for "All"
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final isAll = index == 0;
                          final area = isAll ? null : areas[index - 1];
                          final label = isAll ? 'All areas' : area!;
                          final isSelected = _selectedArea == area;

                          return ChoiceChip(
                            label: Text(label),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _selectedArea = area),
                            selectedColor: AppColors.primary,
                            backgroundColor: context.surfaceColor,
                            side: BorderSide(color: context.outlineColor),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppColors.secondary
                                  : context.textPrimary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: allSalons.isEmpty
                        ? const _EmptyState()
                        : _NoResultsState(
                            onClear: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _selectedArea = null;
                              });
                            },
                          ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) => _SalonCard(salon: filtered[index]),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (error, _) => _ErrorState(
            onRetry: () => ref.invalidate(salonListProvider),
          ),
        ),
      ),
    );
  }
}

class _SalonCard extends StatelessWidget {
  final Salon salon;

  const _SalonCard({required this.salon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.outlineColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushNamed(
          RouteNames.salonDetails,
          pathParameters: {'salonId': salon.id},
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  SalonCoverImage(
                    name: salon.name,
                    imageUrl: salon.coverImageUrl,
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: FavoriteButton(salonId: salon.id),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          salon.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: context.textPrimary,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (salon.isVerified)
                        const Icon(Icons.verified, size: 18, color: AppColors.accent),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (salon.area != null || salon.city != null)
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 14, color: context.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          [salon.area, salon.city].where((e) => e != null).join(', '),
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: AppColors.ratingStar),
                      const SizedBox(width: 4),
                      Text(
                        salon.ratingCount > 0
                            ? '${salon.ratingAvg.toStringAsFixed(1)} (${salon.ratingCount})'
                            : 'No ratings yet',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
                  const SizedBox(height: 24),
                  Text(
                    'No salons yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Salons will show up here once they join Aina.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.textSecondary),
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

class _NoResultsState extends StatelessWidget {
  final VoidCallback onClear;

  const _NoResultsState({required this.onClear});

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
                  SvgPicture.asset(AssetPaths.emptyStateSearch, width: 160, height: 160),
                  const SizedBox(height: 24),
                  Text(
                    'No salons match your search',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try a different area or search term.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: onClear,
                    child: const Text('Clear filters'),
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
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

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
                  const SizedBox(height: 24),
                  Text(
                    "Couldn't load salons",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check your connection and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: onRetry,
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
