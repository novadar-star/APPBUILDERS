import 'package:flutter/material.dart';

/// Full card version of the on-device model status badge.
/// Mirrors [_ModelStatus] from the original single-file scaffold.
class OnDeviceBadge extends StatelessWidget {
  const OnDeviceBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEDECE5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.phonelink_setup, color: Color(0xFF596357)),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'On-device models · Setup required',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Vision and recipe adaptation models are not installed.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          _MockTag(),
        ],
      ),
    );
  }
}

/// Compact AppBar version of the on-device model status badge.
/// Mirrors [_MiniStatus] from the original single-file scaffold.
class OnDeviceMini extends StatelessWidget {
  const OnDeviceMini({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.phone_android, size: 16, color: Color(0xFF267450)),
        SizedBox(width: 4),
        Text(
          'ON DEVICE · MOCK',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

/// Internal amber/orange MOCK tag used by [OnDeviceBadge].
class _MockTag extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE1C8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'MOCK',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.25,
        ),
      ),
    );
  }
}
