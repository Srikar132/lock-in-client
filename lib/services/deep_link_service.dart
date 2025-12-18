import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lock_in/presentation/screens/group_detail_screen.dart';

/// Service to handle deep links for group invitations
class DeepLinkService {
  /// Handle incoming deep link
  static Future<void> handleDeepLink(
    BuildContext context,
    WidgetRef ref,
    String link,
  ) async {
    // Parse the link to extract group ID
    // Format: lockin://group/{groupId} or https://lockin.app/join/{groupId}
    
    String? groupId;
    
    if (link.contains('lockin://group/')) {
      groupId = link.split('lockin://group/').last;
    } else if (link.contains('/join/')) {
      groupId = link.split('/join/').last;
    }
    
    if (groupId != null && groupId.isNotEmpty) {
      // Navigate to group detail screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GroupDetailScreen(groupId: groupId!),
        ),
      );
      
      // Show a helpful message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.group, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Opening group invitation...'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF82D65D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
  
  /// Check if a string is a valid deep link
  static bool isValidDeepLink(String link) {
    return link.contains('lockin://group/') || link.contains('/join/');
  }
}
