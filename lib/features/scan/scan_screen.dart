// ScanScreen — T6
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
    if (newDetected != _detected) {
      setState(() => _detected = newDetected);
    }
  }

  /// Manually trigger one mock detection (for the debug button).
  Future<void> _addMockDetection() async {
    await _onMockTick();
  }

  void _removeIngredient(String id) {
    setState(() => _detected.remove(id));
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MockCameraBox(),
          const SizedBox(height: 16),
          _DetectedChips(
            detected: _detected,
            onRemove: _removeIngredient,
          ),
          const SizedBox(height: 8),
          if (_detected.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No ingredients detected yet. Pan around or add manually.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 16),
          if (kDebugMode) ...[
            OutlinedButton.icon(
              onPressed: _addMockDetection,
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Add next MOCK detection'),
            ),
            const SizedBox(height: 10),
          ],
          FilledButton(
            onPressed: _onDone,
            child: const Text('Done — go to review'),
          ),
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
      height: 260,
      decoration: BoxDecoration(
        color: const Color(0xFF1B2E22),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Crosshair guides
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Corner(Alignment.topLeft),
                    const SizedBox(width: 60),
                    _Corner(Alignment.topRight),
                  ],
                ),
                const SizedBox(height: 60),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Corner(Alignment.bottomLeft),
                    const SizedBox(width: 60),
                    _Corner(Alignment.bottomRight),
                  ],
                ),
              ],
            ),
          ),
          // MOCK CAMERA tag
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Single corner bracket of the mock viewfinder.
class _Corner extends StatelessWidget {
  final Alignment alignment;

  const _Corner(this.alignment);

  @override
  Widget build(BuildContext context) {
    final bool top = alignment == Alignment.topLeft || alignment == Alignment.topRight;
    final bool left = alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;

    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _CornerPainter(top: top, left: left),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool top;
  final bool left;

  const _CornerPainter({required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white54
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

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
            (id) => Chip(
              label: Text(id),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => onRemove(id),
              backgroundColor: const Color(0xFFEDECE5),
              labelStyle: const TextStyle(fontSize: 13),
            ),
          )
          .toList(),
    );
  }
}
