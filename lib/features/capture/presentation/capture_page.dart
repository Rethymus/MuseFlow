import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Capture page placeholder for Phase 1.
///
/// Displays a centered title. Full implementation in Plan 03.
class CapturePage extends ConsumerWidget {
  const CapturePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_outline,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              '捕捉器',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              '灵感碎片捕捉功能即将上线',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
