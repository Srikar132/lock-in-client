

// Simple FutureProvider that calls your static method
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lock_in/data/models/installed_app_model.dart';
import 'package:lock_in/services/native_service.dart';
import 'package:flutter_riverpod/legacy.dart';


final installedAppsProvider = FutureProvider.autoDispose<List<InstalledApp>>((ref) async {
  // You can add logic here to filter system apps if needed
  final apps = await NativeService.getInstalledApps();
  return apps;
});

// 2. Family Provider for Icons (Caches icons individually)
final appIconProvider = FutureProvider.family<Uint8List?, String>((ref, packageName) async {
  return await NativeService.getAppIcon(packageName);
});

// 2. State for Blocked Package Names (Set for O(1) lookups)
final blockedAppsProvider = StateProvider<Set<String>>((ref) => {});

// 3. Search Query State
final appSearchQueryProvider = StateProvider<String>((ref) => '');



// 4. Filtered & Grouped Apps (The Brain)
final groupedAppsProvider = Provider<Map<String, List<InstalledApp>>>((ref) {
  final appsAsync = ref.watch(installedAppsProvider);
  final query = ref.watch(appSearchQueryProvider).toLowerCase();

  return appsAsync.maybeWhen(
    data: (apps) {
      // Filter by search & User apps only (optional)
      final filtered = apps.where((app) {
        final matchesSearch = app.appName.toLowerCase().contains(query);
        final isNotSystem = !app.isSystemApp; // Optional: hide system apps
        return matchesSearch && isNotSystem;
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