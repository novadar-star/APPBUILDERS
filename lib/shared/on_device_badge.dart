import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapfood/app/providers.dart';
import 'package:snapfood/ml/model_store.dart';

// ---------------------------------------------------------------------------
// BadgeModelStatus
// ---------------------------------------------------------------------------
enum BadgeModelStatus { setupRequired, loading, ready, mock }

// ---------------------------------------------------------------------------
// OnDeviceBadge — full card version
// ---------------------------------------------------------------------------
class OnDeviceBadge extends StatelessWidget {
  final BadgeModelStatus visionStatus;
  final BadgeModelStatus llmStatus;

  const OnDeviceBadge({
    super.key,
    this.visionStatus = BadgeModelStatus.setupRequired,
    this.llmStatus = BadgeModelStatus.setupRequired,
  });

  @override
  Widget build(BuildContext context) {
    final hasMock =
        visionStatus == BadgeModelStatus.mock || llmStatus == BadgeModelStatus.mock;
    final hasSetupRequired = visionStatus == BadgeModelStatus.setupRequired ||
        llmStatus == BadgeModelStatus.setupRequired;
    final isLoading = visionStatus == BadgeModelStatus.loading ||
        llmStatus == BadgeModelStatus.loading;
    final bothReady =
        visionStatus == BadgeModelStatus.ready && llmStatus == BadgeModelStatus.ready;

    final String label;
    final Color iconColor;

    if (hasMock) {
      label = 'On-device models · MOCK';
      iconColor = const Color(0xFFB07B3A);
    } else if (hasSetupRequired) {
      label = 'On-device models · Setup required';
      iconColor = const Color(0xFF596357);
    } else if (isLoading) {
      label = 'On-device models · Loading...';
      iconColor = const Color(0xFF596357);
    } else if (bothReady) {
      label = 'On-device models · Ready';
      iconColor = const Color(0xFF267450);
    } else {
      label = 'On-device models · Setup required';
      iconColor = const Color(0xFF596357);
    }

    final String subtitle;
    if (bothReady) {
      subtitle = 'Vision and recipe adaptation models are ready.';
    } else if (isLoading) {
      subtitle = 'Loading models, please wait.';
    } else {
      subtitle = 'Vision and recipe adaptation models are not installed.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEDECE5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.phonelink_setup, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(subtitle, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          if (hasMock) const _MockTag(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// OnDeviceMini — compact AppBar version
// ---------------------------------------------------------------------------
class OnDeviceMini extends StatelessWidget {
  final BadgeModelStatus visionStatus;
  final BadgeModelStatus llmStatus;

  const OnDeviceMini({
    super.key,
    this.visionStatus = BadgeModelStatus.setupRequired,
    this.llmStatus = BadgeModelStatus.setupRequired,
  });

  @override
  Widget build(BuildContext context) {
    final hasMock =
        visionStatus == BadgeModelStatus.mock || llmStatus == BadgeModelStatus.mock;
    final bothReady =
        visionStatus == BadgeModelStatus.ready && llmStatus == BadgeModelStatus.ready;

    final String tag;
    final Color color;

    if (hasMock) {
      tag = 'ON DEVICE · MOCK';
      color = const Color(0xFFB07B3A);
    } else if (bothReady) {
      tag = 'ON DEVICE · READY';
      color = const Color(0xFF267450);
    } else {
      tag = 'ON DEVICE · SETUP REQD';
      color = const Color(0xFF596357);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.phone_android, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          tag,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Consumer variants — read live providers
// ---------------------------------------------------------------------------

BadgeModelStatus _mapModelStatus(ModelStatus status) {
  switch (status) {
    case ModelStatus.ready:
      return BadgeModelStatus.ready;
    case ModelStatus.loading:
      return BadgeModelStatus.loading;
    case ModelStatus.present:
      return BadgeModelStatus.ready;
    case ModelStatus.missing:
    case ModelStatus.failed:
      return BadgeModelStatus.setupRequired;
  }
}

class OnDeviceBadgeConsumer extends ConsumerWidget {
  const OnDeviceBadgeConsumer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visionAsync = ref.watch(visionModelStatusProvider);
    final llmAsync = ref.watch(llmModelStatusProvider);

    final visionBadge = visionAsync.when(
      data: (s) => _mapModelStatus(s.status),
      loading: () => BadgeModelStatus.loading,
      error: (_, __) => BadgeModelStatus.setupRequired,
    );

    final llmBadge = llmAsync.when(
      data: (s) => _mapModelStatus(s.status),
      loading: () => BadgeModelStatus.loading,
      error: (_, __) => BadgeModelStatus.setupRequired,
    );

    return OnDeviceBadge(visionStatus: visionBadge, llmStatus: llmBadge);
  }
}

class OnDeviceMiniConsumer extends ConsumerWidget {
  const OnDeviceMiniConsumer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visionAsync = ref.watch(visionModelStatusProvider);
    final llmAsync = ref.watch(llmModelStatusProvider);

    final visionBadge = visionAsync.when(
      data: (s) => _mapModelStatus(s.status),
      loading: () => BadgeModelStatus.loading,
      error: (_, __) => BadgeModelStatus.setupRequired,
    );

    final llmBadge = llmAsync.when(
      data: (s) => _mapModelStatus(s.status),
      loading: () => BadgeModelStatus.loading,
      error: (_, __) => BadgeModelStatus.setupRequired,
    );

    return OnDeviceMini(visionStatus: visionBadge, llmStatus: llmBadge);
  }
}

// ---------------------------------------------------------------------------
// Internal widgets
// ---------------------------------------------------------------------------

class _MockTag extends StatelessWidget {
  const _MockTag();

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
