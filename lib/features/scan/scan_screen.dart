// ScanScreen — T9
// Mock camera simulation. No real CameraImage is passed in debug mode;
// MockDetector.simulateFrame() is called directly on each timer tick.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapfood/app/providers.dart';
import 'package:snapfood/domain/accumulator.dart';
import 'package:snapfood/ml/mock_detector.dart';
import 'package:snapfood/shared/on_device_badge.dart';
import 'package:snapfood/shared/sample_notice.dart';

// ---------------------------------------------------------------------------
// ScanScreen
// ---------------------------------------------------------------------------

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  Timer? _timer;
  DetectionAccumulator? _accumulator;
  // Local copy of confirmed set so we can reflect removals instantly.
  Set<String> _detected = {};
  bool _accumulatorReady = false;

  @override
  void initState() {
    super.initState();
    // Start the simulation after the first frame so providers are available.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initScanner());
  }

  Future<void> _initScanner() async {
    final configAsync = ref.read(appConfigProvider);
    final scanCfg = configAsync.maybeWhen(
      data: (c) => c.scan,
      orElse: () => null,
    );

    final intervalMs = scanCfg?.intervalMs ?? 700;
    final windowSize = scanCfg?.windowSize ?? 5;
    final minHits = scanCfg?.minHits ?? 3;
    final minConfidence = scanCfg?.minConfidence ?? 0.6;

    _accumulator = DetectionAccumulator(
      windowSize: windowSize,
      minHits: minHits,
      minConfidence: minConfidence,
    );

    setState(() => _accumulatorReady = true);

    if (kDebugMode) {
      _timer = Timer.periodic(
        Duration(milliseconds: intervalMs),
        (_) => _onMockTick(),
      );
    }
  }

  Future<void> _onMockTick() async {
    final detector = ref.read(detectorProvider);
    if (detector is! MockDetector) return;
    final predictions = await detector.simulateFrame();
    if (!mounted) return;
    _accumulator?.addFrame(predictions);
    final newDetected = Set<String>.from(_accumulator?.detected ?? {});
    if (newDetected.length != _detected.length ||
        !newDetected.every(_detected.contains)) {
      setState(() => _detected = newDetected);
    }
  }

  /// Manually trigger one mock detection (for the debug button).
  Future<void> _addMockDetection() async {
    await _onMockTick();
  }

  void _removeIngredient(String id) {
    setState(() => _detected.remove(id));
    _accumulator?.reset();
    if (_detected.isNotEmpty) {
      // Re-seed the accumulator so removed items don't re-appear immediately.
    }
  }

  void _onDone() {
    // Persist to shared provider then navigate to review.
    ref.read(ownedIngredientsProvider.notifier).state = Set<String>.from(_detected);
    context.go('/review');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan ingredients'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: OnDeviceMiniConsumer(),
          ),
        ],
      ),
      body: _accumulatorReady
          ? _buildBody(context)
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SampleNotice(),
          const SizedBox(height: 12),

          // Dark camera viewfinder
          _MockCameraBox(),
          const SizedBox(height: 12),

          // Detected chips below viewfinder
          if (_detected.isNotEmpty) ...[
            Text(
              'Detected ingredients',
              style: theme.textTheme.labelMedium?.copyWith(
                color: const Color(0xFF596357),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            _DetectedChips(
              detected: _detected,
              onRemove: _removeIngredient,
            ),
            const SizedBox(height: 8),
          ],

          if (_detected.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No ingredients detected yet. Pan around or add manually.',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 12),

          // Debug button
          if (kDebugMode) ...[
            OutlinedButton.icon(
              onPressed: _addMockDetection,
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Add next MOCK detection'),
            ),
            const SizedBox(height: 10),
          ],

          // Done button
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _onDone,
              child: const Text(
                'Done — go to review',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // OnDevice badge
          const OnDeviceBadgeConsumer(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _MockCameraBox
// ---------------------------------------------------------------------------

class _MockCameraBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF1B2E22),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Corner brackets
          _buildCornerBracket(Alignment.topLeft, isTop: true, isLeft: true),
          _buildCornerBracket(Alignment.topRight, isTop: true, isLeft: false),
          _buildCornerBracket(Alignment.bottomLeft, isTop: false, isLeft: true),
          _buildCornerBracket(
              Alignment.bottomRight, isTop: false, isLeft: false),

          // MOCK CAMERA tag (debug only)
          if (kDebugMode)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE1C8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'MOCK CAMERA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Color(0xFF7A4A1E),
                  ),
                ),
              ),
            ),

          // Center label
          const Center(
            child: Text(
              'Point at your ingredients',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerBracket(
    Alignment alignment, {
    required bool isTop,
    required bool isLeft,
  }) {
    return Positioned(
      top: isTop ? 16 : null,
      bottom: isTop ? null : 16,
      left: isLeft ? 16 : null,
      right: isLeft ? null : 16,
      child: SizedBox(
        width: 24,
        height: 24,
        child: CustomPaint(
          painter: _CornerPainter(top: isTop, left: isLeft),
        ),
      ),
    );
  }
}

/// Single green corner bracket of the mock viewfinder.
class _CornerPainter extends CustomPainter {
  final bool top;
  final bool left;

  const _CornerPainter({required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final x = left ? 0.0 : size.width;
    final y = top ? 0.0 : size.height;
    final hx = left ? size.width : 0.0;
    final vy = top ? size.height : 0.0;

    canvas.drawLine(Offset(x, y), Offset(hx, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, vy), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}

// ---------------------------------------------------------------------------
// _DetectedChips
// ---------------------------------------------------------------------------

class _DetectedChips extends StatelessWidget {
  final Set<String> detected;
  final void Function(String id) onRemove;

  const _DetectedChips({required this.detected, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (detected.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: detected
          .map(
            (id) => InputChip(
              avatar: const Icon(Icons.check_circle,
                  size: 16, color: Color(0xFF1C684E)),
              label: Text(id),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => onRemove(id),
              backgroundColor: const Color(0xFFE5EEE5),
              labelStyle: const TextStyle(fontSize: 13),
            ),
          )
          .toList(),
    );
  }
}
