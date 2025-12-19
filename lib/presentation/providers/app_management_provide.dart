

// Simple FutureProvider that calls your static method
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lock_in/data/models/installed_app_model.dart';
import 'package:lock_in/services/native_service.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:lock_in/presentation/providers/blocked_content_provider.dart';


final installedAppsProvider = FutureProvider.autoDispose<List<InstalledApp>>((ref) async {
  // You can add logic here to filter system apps if needed
  final apps = await NativeService.getInstalledApps();
  return apps;
});

// 2. Family Provider for Icons (Caches icons individually)
final appIconProvider = FutureProvider.family<Uint8List?, String>((ref, packageName) async {
  return await NativeService.getAppIcon(packageName);
});

// 3. Search Query State
final appSearchQueryProvider = StateProvider<String>((ref) => '');



// 4. Filtered & Grouped Apps (The Brain)
final groupedAppsProvider = Provider<Map<String, List<InstalledApp>>>((ref) {
  final appsAsync = ref.watch(installedAppsProvider);
  final query = ref.watch(appSearchQueryProvider).toLowerCase();

  return appsAsync.maybeWhen(
    data: (apps) {
      // Filter by search query only (include all apps, even system apps)
      final filtered = apps.where((app) {
        final matchesSearch = app.appName.toLowerCase().contains(query);
        // Allow all apps including YouTube which might be marked as system app
        return matchesSearch;
      }).toList();

      // Group by Category
      final Map<String, List<InstalledApp>> grouped = {};
      for (final app in filtered) {
        // You can map raw categories to nicer names here if needed
        String categoryName = app.category.isEmpty ? "Other" : app.category;
        grouped.putIfAbsent(categoryName, () => []).add(app);
      }
      return grouped;
    },
    orElse: () => {},
  );
});

// 5. Allowed Apps Provider (Non-blocked apps)
final allowedAppsProvider = Provider.family<AsyncValue<List<InstalledApp>>, String>((ref, userId) {
  final appsAsync = ref.watch(installedAppsProvider);
  final blockedAppsAsync = ref.watch(permanentlyBlockedAppsProvider(userId));

  return appsAsync.when(
    data: (apps) {
      return blockedAppsAsync.when(
        data: (blockedPackages) {
          // Filter out blocked apps and system apps
          final allowed = apps.where((app) {
            final isNotBlocked = !blockedPackages.contains(app.packageName);
            final isNotSystem = !app.isSystemApp;
            return isNotBlocked && isNotSystem;
          }).toList();
          
          // Sort alphabetically
          allowed.sort((a, b) => a.appName.compareTo(b.appName));
          
          return AsyncValue.data(allowed);
        },
        loading: () => const AsyncValue.loading(),
        error: (err, stack) => AsyncValue.error(err, stack),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});