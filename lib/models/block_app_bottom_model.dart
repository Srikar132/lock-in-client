import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lock_in/data/models/installed_app_model.dart';
import 'package:lock_in/presentation/providers/app_management_provide.dart';

// ============================================================================
// FIXED: BlockAppsSheet with keyboard handling
// ============================================================================
class BlockAppsSheet extends ConsumerStatefulWidget {
  const BlockAppsSheet({super.key});

  @override
  ConsumerState<BlockAppsSheet> createState() => _BlockAppsSheetState();
}

class _BlockAppsSheetState extends ConsumerState<BlockAppsSheet> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupedApps = ref.watch(groupedAppsProvider);
    final isLoading = ref.watch(installedAppsProvider).isLoading;

    // FIXED: Use MediaQuery to get proper height accounting for keyboard
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final availableHeight = screenHeight - keyboardHeight;

    return Container(
      // FIXED: Use min to ensure we don't exceed available space
      height: availableHeight * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          _buildSearchBar(context, ref),
          if (isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: RepaintBoundary(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 30),
                  itemCount: groupedApps.keys.length,
                  cacheExtent: 500,
                  itemBuilder: (context, index) {
                    final category = groupedApps.keys.elementAt(index);
                    final apps = groupedApps[category]!;
                    return _CategorySection(
                      key: ValueKey(category),
                      category: category,
                      apps: apps,
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Select Apps to Block',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 20),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          ref.read(appSearchQueryProvider.notifier).state = val;
        },
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search apps',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF6A6A6A)),
          filled: true,
          fillColor: const Color(0xFF2A2A2A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
    );
  }
}

// ============================================================================
// OPTIMIZED: Category Section with Manual Expansion Control
// ============================================================================
class _CategorySection extends ConsumerStatefulWidget {
  final String category;
  final List<InstalledApp> apps;

  const _CategorySection({
    super.key,
    required this.category,
    required this.apps,
  });

  @override
  ConsumerState<_CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends ConsumerState<_CategorySection>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final blockedSet = ref.watch(blockedAppsProvider);

    final blockedCount = widget.apps.where((app) =>
        blockedSet.contains(app.packageName)
    ).length;
    final areAllBlocked = blockedCount == widget.apps.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.category,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (blockedCount > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF82D65D).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$blockedCount',
                        style: const TextStyle(
                          color: Color(0xFF82D65D),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: areAllBlocked,
                      activeColor: const Color(0xFF82D65D),
                      inactiveTrackColor: const Color(0xFF3A3A3A),
                      onChanged: (bool value) {
                        final currentSet = Set<String>.from(blockedSet);
                        if (value) {
                          for (var app in widget.apps) {
                            currentSet.add(app.packageName);
                          }
                        } else {
                          for (var app in widget.apps) {
                            currentSet.remove(app.packageName);
                          }
                        }
                        ref.read(blockedAppsProvider.notifier).state = currentSet;
                      },
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _isExpanded ? 0.5 : 0,
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Column(
              children: widget.apps.map((app) {
                return _AppListTile(
                  key: ValueKey(app.packageName),
                  app: app,
                );
              }).toList(),
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// OPTIMIZED: Individual App Tile
// ============================================================================
class _AppListTile extends ConsumerWidget {
  final InstalledApp app;

  const _AppListTile({super.key, required this.app});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedSet = ref.watch(blockedAppsProvider);
    final isBlocked = blockedSet.contains(app.packageName);

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              final currentSet = Set<String>.from(blockedSet);
              if (isBlocked) {
                currentSet.remove(app.packageName);
              } else {
                currentSet.add(app.packageName);
              }
              ref.read(blockedAppsProvider.notifier).state = currentSet;
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _AppIcon(packageName: app.packageName),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      app.appName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: isBlocked,
                      activeColor: const Color(0xFF82D65D),
                      inactiveTrackColor: const Color(0xFF3A3A3A),
                      onChanged: (bool value) {
                        final currentSet = Set<String>.from(blockedSet);
                        if (value) {
                          currentSet.add(app.packageName);
                        } else {
                          currentSet.remove(app.packageName);
                        }
                        ref.read(blockedAppsProvider.notifier).state = currentSet;
                      },
                    ),
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

// ============================================================================
// OPTIMIZED: App Icon Widget
// ============================================================================
class _AppIcon extends ConsumerWidget {
  final String packageName;

  const _AppIcon({required this.packageName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconAsync = ref.watch(appIconProvider(packageName));

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: iconAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (err, stack) => const Icon(
            Icons.android,
            color: Colors.white,
            size: 24,
          ),
          data: (iconBytes) {
            if (iconBytes == null) {
              return const Icon(
                Icons.android,
                color: Colors.white,
                size: 24,
              );
            }
            return Image.memory(
              iconBytes,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.android,
                  color: Colors.white,
                  size: 24,
                );
              },
            );
          },
        ),
      ),
    );
  }
}