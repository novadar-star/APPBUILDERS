// NOTE: AndroidManifest.xml needs <uses-permission android:name="android.permission.CAMERA"/> once android/ is generated.
// ScanScreen — T9
// Real CameraPreview with MockDetector frame simulation in debug mode.

import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapfood/app/providers.dart';
import 'package:snapfood/domain/accumulator.dart';
import 'package:snapfood/ml/mock_detector.dart';
import 'package:snapfood/shared/nova/nova_state.dart';
import 'package:snapfood/shared/nova/nova_widget.dart';
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
  // Track which ids have already been animated.
  final Set<String> _animatedIds = {};

  // Camera fields
  CameraController? _cameraController;
  String? _cameraError;

  // Nova viewfinder state
  NovaState _novaViewfinderState = NovaState.idle;
  Timer? _novaHappyTimer;

  @override
  void initState() {
    super.initState();
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

    await _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraError = 'No camera available.');
        return;
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras[0],
      );
      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() {});
    } on CameraException catch (e) {
      if (!mounted) return;
      if (e.code == 'CameraAccessDenied') {
        setState(() => _cameraError =
            'Camera permission denied. Please allow camera access in Settings.');
      } else {
        setState(() => _cameraError =
            e.description ?? 'Camera unavailable. Please restart the app.');
      }
    }
  }

  Future<void> _onMockTick() async {
    final detector = ref.read(detectorProvider);
    if (detector is! MockDetector) return;
    final predictions = await detector.simulateFrame();
    if (!mounted) return;
    _accumulator?.addFrame(predictions);
    final newDetected = Set<String>.from(_accumulator?.detected ?? {});
    final oldLen = _detected.length;
    if (newDetected.length != _detected.length ||
        !newDetected.every(_detected.contains)) {
      setState(() => _detected = newDetected);
    }
    // Update Nova viewfinder state when a new ingredient is detected
    if (newDetected.length > oldLen) {
      setState(() => _novaViewfinderState = NovaState.happy);
      _novaHappyTimer?.cancel();
      _novaHappyTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _novaViewfinderState = NovaState.idle);
      });
    }
  }

  Future<void> _addMockDetection() async {
    await _onMockTick();
  }

  void _removeIngredient(String id) {
    setState(() {
      _detected.remove(id);
      _animatedIds.remove(id);
    });
    _accumulator?.reset();
  }

  void _onDone() {
    ref.read(ownedIngredientsProvider.notifier).state =
        Set<String>.from(_detected);
    context.go('/review');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cameraController?.dispose();
    _novaHappyTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Ingredients'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: OnDeviceMiniConsumer(),
          ),
        ],
      ),
      body: _accumulatorReady
          ? _buildBody(context)
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NovaWidget(state: NovaState.thinking, size: 100),
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        // ── Main content ──────────────────────────────────────────────────
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SampleNotice(),
                const SizedBox(height: 12),

                // Real camera viewfinder
                _buildViewfinder(context),
                const SizedBox(height: 12),

                // Photo fallback button
                TextButton.icon(
                  onPressed: () async {
                    final picker = ref.read(photoPickerProvider);
                    final path = await picker.pickPhoto();
                    if (path == null) return;
                    final detector = ref.read(detectorProvider);
                    final predictions =
                        await detector.predictFromFile(path);
                    if (!mounted) return;
                    // Simulate multi-frame confirmation
                    _accumulator?.addFrame(predictions);
                    _accumulator?.addFrame(predictions);
                    _accumulator?.addFrame(predictions);
                    final newDetected =
                        Set<String>.from(_accumulator?.detected ?? {});
                    setState(() => _detected = newDetected);
                  },
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('use a photo instead'),
                ),

                // Debug button
                if (kDebugMode) ...[
                  OutlinedButton.icon(
                    onPressed: _addMockDetection,
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Add next MOCK detection'),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),

        // ── Detected ingredients bottom sheet ─────────────────────────────
        if (_detected.isNotEmpty)
          DraggableScrollableSheet(
            initialChildSize: 0.25,
            minChildSize: 0.15,
            maxChildSize: 0.6,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'spotted so far',
                      style: theme.textTheme.titleSmall?.copyWith(
                        letterSpacing: 1.2,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _detected.map((id) {
                        final isNew = !_animatedIds.contains(id);
                        if (isNew) {
                          // Schedule marking as animated after build
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() => _animatedIds.add(id));
                            }
                          });
                        }
                        return AnimatedOpacity(
                          opacity: isNew ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                          child: InputChip(
                            avatar: Icon(Icons.check_circle,
                                size: 16, color: colorScheme.primary),
                            label: Text(id),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () => _removeIngredient(id),
                            backgroundColor: colorScheme.primaryContainer,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),

        // ── Done CTA pinned at bottom ─────────────────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _onDone,
                  child: const Text(
                    'Use This Photo',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // _buildViewfinder — real CameraPreview with Nova overlay
  // ---------------------------------------------------------------------------

  Widget _buildViewfinder(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final br = BorderRadius.circular(16);
    final accentColor = colorScheme.primary;

    final cameraReady = _cameraController != null &&
        _cameraController!.value.isInitialized;

    return Container(
      height: 280,
      decoration: BoxDecoration(
        // Keep dark fallback background while initializing; transparent once ready
        color: cameraReady ? Colors.transparent : colorScheme.inverseSurface,
        borderRadius: br,
      ),
      child: ClipRRect(
        borderRadius: br,
        child: Stack(
          children: [
            // ── Camera preview fill ────────────────────────────────────
            if (cameraReady)
              Positioned.fill(
                child: CameraPreview(_cameraController!),
              ),

            // ── Error state ────────────────────────────────────────────
            if (_cameraError != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _cameraError!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onInverseSurface,
                    ),
                  ),
                ),
              ),

            // ── Nova idle overlay (before camera ready, no error) ──────
            if (!cameraReady && _cameraError == null && _detected.isEmpty)
              Positioned.fill(
                child: Center(
                  child: NovaWidget(
                    state: NovaState.idle,
                    size: 80,
                    caption: 'Point me at your plate.',
                  ),
                ),
              ),

            // ── Camera initializing text (not empty, not ready yet) ────
            if (!cameraReady && _cameraError == null && _detected.isNotEmpty)
              Center(
                child: Text(
                  'Camera initializing…',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onInverseSurface,
                  ),
                ),
              ),

            // ── Corner brackets ────────────────────────────────────────
            _buildCornerBracket(
              Alignment.topLeft,
              isTop: true,
              isLeft: true,
              color: accentColor,
            ),
            _buildCornerBracket(
              Alignment.topRight,
              isTop: true,
              isLeft: false,
              color: accentColor,
            ),
            _buildCornerBracket(
              Alignment.bottomLeft,
              isTop: false,
              isLeft: true,
              color: accentColor,
            ),
            _buildCornerBracket(
              Alignment.bottomRight,
              isTop: false,
              isLeft: false,
              color: accentColor,
            ),

            // ── MOCK CAMERA badge (debug only) ─────────────────────────
            if (kDebugMode)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'MOCK CAMERA',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),

            // ── Nova overlay when camera is running ────────────────────
            if (cameraReady)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: NovaWidget(
                    state: _novaViewfinderState,
                    size: 80,
                    caption: _novaViewfinderState == NovaState.happy
                        ? null
                        : 'Point me at your plate.',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerBracket(
    Alignment alignment, {
    required bool isTop,
    required bool isLeft,
    required Color color,
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
          painter: _CornerPainter(top: isTop, left: isLeft, color: color),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CornerPainter
// ---------------------------------------------------------------------------

/// Single accent-colored corner bracket of the camera viewfinder.
class _CornerPainter extends CustomPainter {
  final bool top;
  final bool left;
  final Color color;

  const _CornerPainter({
    required this.top,
    required this.left,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
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
  bool shouldRepaint(_CornerPainter old) =>
      old.color != color || old.top != top || old.left != left;
}
