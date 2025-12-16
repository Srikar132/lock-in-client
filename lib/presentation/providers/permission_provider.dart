import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lock_in/services/permissions_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lock_in/presentation/providers/auth_provider.dart';
import 'package:lock_in/data/repositories/user_repository.dart';

// Permission state
class PermissionState {
  final bool usagePermission;
  final bool overlayPermission;
  final bool notificationPermission;
  final bool accessibilityPermission;
  final bool backgroundPermission;
  final bool displayPopupPermission;

  PermissionState({
    this.usagePermission = false,
    this.overlayPermission = false,
    this.notificationPermission = false,
    this.accessibilityPermission = false,
    this.backgroundPermission = false,
    this.displayPopupPermission = false,
  });

  bool get allGranted =>
      usagePermission && 
      overlayPermission && 
      notificationPermission && 
      accessibilityPermission && 
      backgroundPermission && 
      displayPopupPermission;

  PermissionState copyWith({
    bool? usagePermission,
    bool? overlayPermission,
    bool? notificationPermission,
    bool? accessibilityPermission,
    bool? backgroundPermission,
    bool? displayPopupPermission,
  }) {
    return PermissionState(
      usagePermission: usagePermission ?? this.usagePermission,
      overlayPermission: overlayPermission ?? this.overlayPermission,
      notificationPermission:
          notificationPermission ?? this.notificationPermission,
      accessibilityPermission:
          accessibilityPermission ?? this.accessibilityPermission,
      backgroundPermission: backgroundPermission ?? this.backgroundPermission,
      displayPopupPermission: displayPopupPermission ?? this.displayPopupPermission,
    );
  }
}

// Permission notifier
class PermissionNotifier extends Notifier<PermissionState> {
  late UserRepository _userRepository;
  // here also get acces to currentUser
  

  @override
  PermissionState build() {
    _userRepository = ref.read(userRepositoryProvider);
    return PermissionState();
  }

  // Check all permissions
  Future<void> checkPermissions() async {
    final usageGranted = await PermissionService.hasUsageStatsPermission();
    final overlayGranted = await PermissionService.hasOverlayPermission();
    final notificationGranted = await Permission.notification.isGranted;
    final accessibilityGranted = await PermissionService.hasAccessibilityPermission();
    final backgroundGranted = await PermissionService.hasBackgroundPermission();
    final displayPopupGranted = await PermissionService.hasDisplayPopupPermission();

    state = state.copyWith(
      usagePermission: usageGranted,
      overlayPermission: overlayGranted,
      notificationPermission: notificationGranted,
      accessibilityPermission: accessibilityGranted,
      backgroundPermission: backgroundGranted,
      displayPopupPermission: displayPopupGranted,
    );
  }

  // Request usage permission
  Future<void> requestUsagePermission() async {
    await PermissionService.requestUsageStatsPermission();
    final granted = await PermissionService.hasUsageStatsPermission();
    state = state.copyWith(usagePermission: granted);
  }

  // Request overlay permission
  Future<void> requestOverlayPermission() async {
    await PermissionService.requestOverlayPermission();
    final granted = await PermissionService.hasOverlayPermission();
    state = state.copyWith(overlayPermission: granted);
  }

  // Request Background permission
  Future<void> requestBackgroundPermission() async {
    await PermissionService.requestBackgroundPermission();
    final granted = await PermissionService.hasBackgroundPermission();
    state = state.copyWith(backgroundPermission: granted);
  }

  // Request notification permission
  Future<void> requestNotificationPermission() async {
    await Permission.notification.request();
    final granted = await Permission.notification.isGranted;
    state = state.copyWith(notificationPermission: granted);
  }

  // Request display popup permission
  Future<void> requestDisplayPopupPermission() async {
    await PermissionService.requestDisplayPopupPermission();
    final granted = await PermissionService.hasDisplayPopupPermission();
    state = state.copyWith(displayPopupPermission: granted);
  }

  // Request accessibility permission
  Future<void> requestAccessibilityPermission() async {
    await PermissionService.requestAccessibilityPermission();
    final granted = await PermissionService.hasAccessibilityPermission();
    state = state.copyWith(accessibilityPermission: granted);
  }

  // Complete permissions setup
  Future<void> completePermissions(String userId) async {
    try {
      await _userRepository.updatePermissionStatus(userId, true);
    } catch (e) {
      debugPrint('Error completing permissions: $e');
      rethrow;
    }
  }
}

// Permission provider
final permissionProvider =
    NotifierProvider<PermissionNotifier, PermissionState>(() {
      return PermissionNotifier();
    });
