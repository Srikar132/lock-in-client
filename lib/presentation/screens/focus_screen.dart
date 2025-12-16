import 'package:flutter/material.dart';
import 'package:lock_in/core/constants/images.dart';

class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Background Image Layer
          Positioned.fill(
            child: Image.asset(kHomeBackgroundImage, fit: BoxFit.cover),
          ),

        // 2. Transparent InkWell & Column Layer
        Positioned.fill(
          child: Material(
            // Material widget is needed for the InkWell ripple to show
            color: Colors.transparent,
            child: InkWell(
              // The onTap callback is required for the InkWell to be clickable
              onTap: () {
                // print("InkWell tapped!");
                // Add your tap handling logic here
              },
              onLongPress:() {},
              // Optional: Customize the splash color
              splashColor: Colors.white.withAlpha(30),
              highlightColor: Colors.white.withAlpha(10),
              child: const Column(
                // Align content in the center of the column
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                 
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}