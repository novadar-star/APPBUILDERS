import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:snapfood/shared/nova/nova_painter.dart';
import 'package:snapfood/shared/nova/nova_state.dart';

// ---------------------------------------------------------------------------
// NovaWidget
// ---------------------------------------------------------------------------
// Renders the Nova mascot for a given [NovaState].
//
// Usage:
//   NovaWidget(state: NovaState.idle, size: 160)
//   NovaWidget(state: NovaState.happy, size: 100, caption: "Got it!")
//
// State transitions automatically play the squash-and-stretch pop.
// Respects MediaQuery.disableAnimations (reduced motion).
// ---------------------------------------------------------------------------

class NovaWidget extends StatefulWidget {
  final NovaState state;

  /// Width and height of the Nova canvas. Defaults to 120.
  final double size;

  /// Optional caption rendered below Nova. When present, Nova's canvas is
  /// decorative (excludeSemantics) and the caption carries the a11y label.
  final String? caption;

  const NovaWidget({
    super.key,
    required this.state,
    this.size = 120,
    this.caption,
  });

  @override
  State<NovaWidget> createState() => _NovaWidgetState();
}

class _NovaWidgetState extends State<NovaWidget>
    with TickerProviderStateMixin {
  // ── Animation controllers ─────────────────────────────────────────────────

  // State-change squash & stretch pop (plays once on every state change)
  late final AnimationController _popCtrl;
  late final Animation<double> _popAnim;

  // Idle: slow breathe loop
  late final AnimationController _breatheCtrl;
  late final Animation<double> _breatheAnim;

  // Idle: blink (4.2s period, fast close at 93%)
  late final AnimationController _blinkCtrl;

  // Idle: pupil look-around
  late final AnimationController _lookCtrl;
  late final Animation<double> _lookAnim;

  // Thinking: sway
  late final AnimationController _swayCtrl;
  late final Animation<double> _swayAnim;

  // Happy: hop
  late final AnimationController _hopCtrl;
  late final Animation<double> _hopAnim;

  // Error: shake
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  // Celebrating: jump
  late final AnimationController _jumpCtrl;
  late final Animation<double> _jumpAnim;

  // Celebrating: mouth open/close
  late final AnimationController _mouthCtrl;
  late final Animation<double> _mouthAnim;

  // Scan ring rotation (thinking)
  late final AnimationController _scanCtrl;
  late final Animation<double> _scanAnim;

  // Leaf sway (always, speed varies by state)
  late final AnimationController _leafCtrl;
  late final Animation<double> _leafAnim;

  // Hat bounce (celebrating)
  late final AnimationController _hatCtrl;
  late final Animation<double> _hatAnim;

  // FX: sparkle pulse (happy / celebrating), thinking dots, error wob
  late final AnimationController _fxCtrl;

  // Arm angles driven by state (no controller — direct value)
  double _armLAngle = 0;
  double _armRAngle = 0;

  bool _initialApplied = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
    // _applyState deferred to didChangeDependencies so MediaQuery is available
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialApplied) {
      _initialApplied = true;
      _applyState(widget.state, initial: true);
    }
  }

  void _initControllers() {
    _popCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _popAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _popCtrl, curve: Curves.easeOut));

    _breatheCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3400));
    _breatheAnim = Tween<double>(begin: 0, end: 1)
        .animate(_breatheCtrl);

    _blinkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 4200));

    _lookCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 7000));
    // look: center → left → right → center
    _lookAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 0), weight: 40),
      TweenSequenceItem(
          tween: Tween<double>(begin: 0, end: -5)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 10),
      TweenSequenceItem(tween: Tween<double>(begin: -5, end: -5), weight: 15),
      TweenSequenceItem(
          tween: Tween<double>(begin: -5, end: 5)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 5, end: 5), weight: 15),
      TweenSequenceItem(
          tween: Tween<double>(begin: 5, end: 0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 5),
    ]).animate(_lookCtrl);

    _swayCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800));
    _swayAnim = Tween<double>(begin: -7, end: -2).animate(
        CurvedAnimation(parent: _swayCtrl, curve: Curves.easeInOut));

    _hopCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    // hop: 0 → −14 → 0  (Y offset, negative = up)
    _hopAnim = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween<double>(begin: 0, end: -14)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 45),
      TweenSequenceItem(
          tween: Tween<double>(begin: -14, end: 0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 55),
    ]).animate(_hopCtrl);

    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400));
    // shake: rapid X oscillation then slump (matchs CSS keyframes)
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: -8), weight: 4),
      TweenSequenceItem(tween: Tween<double>(begin: -8, end: 8), weight: 4),
      TweenSequenceItem(tween: Tween<double>(begin: 8, end: -6), weight: 4),
      TweenSequenceItem(tween: Tween<double>(begin: -6, end: 6), weight: 4),
      TweenSequenceItem(tween: Tween<double>(begin: 6, end: -3), weight: 4),
      TweenSequenceItem(tween: Tween<double>(begin: -3, end: 0), weight: 6),
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 3), weight: 62),
      TweenSequenceItem(tween: Tween<double>(begin: 3, end: 0), weight: 12),
    ]).animate(_shakeCtrl);

    _jumpCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 850));
    // jump: 0 → −6 → −52 → −6 → 0
    _jumpAnim = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween<double>(begin: 0, end: -6)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 20),
      TweenSequenceItem(
          tween: Tween<double>(begin: -6, end: -52)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 30),
      TweenSequenceItem(
          tween: Tween<double>(begin: -52, end: -6)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 30),
      TweenSequenceItem(
          tween: Tween<double>(begin: -6, end: 0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 20),
    ]).animate(CurvedAnimation(
        parent: _jumpCtrl,
        curve: const Cubic(0.3, 0, 0.4, 1)));

    _mouthCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _mouthAnim = Tween<double>(begin: 0.8, end: 1.1)
        .animate(CurvedAnimation(parent: _mouthCtrl, curve: Curves.easeInOut));

    _scanCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));
    _scanAnim = Tween<double>(begin: 0, end: 360)
        .animate(CurvedAnimation(parent: _scanCtrl, curve: Curves.linear));

    _leafCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000));
    _leafAnim = Tween<double>(begin: -5, end: 7)
        .animate(CurvedAnimation(parent: _leafCtrl, curve: Curves.easeInOut));

    _hatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 850));
    _hatAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: -8), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: -8, end: 0), weight: 50),
    ]).animate(
        CurvedAnimation(parent: _hatCtrl, curve: Curves.easeInOut));

    _fxCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));
  }

  bool get _reduceMotion =>
      MediaQuery.of(context).disableAnimations;

  void _applyState(NovaState state, {bool initial = false}) {
    // Stop all loops first
    _breatheCtrl.stop();
    _blinkCtrl.stop();
    _lookCtrl.stop();
    _swayCtrl.stop();
    _hopCtrl.stop();
    _shakeCtrl.stop();
    _jumpCtrl.stop();
    _mouthCtrl.stop();
    _scanCtrl.stop();
    _fxCtrl.stop();

    // Update arm angles
    switch (state) {
      case NovaState.idle:
        _armLAngle = 3;
        _armRAngle = -3;
        break;
      case NovaState.happy:
        _armLAngle = 42;
        _armRAngle = -42;
        break;
      case NovaState.thinking:
        _armLAngle = 0;
        _armRAngle = -155;
        break;
      case NovaState.error:
        _armLAngle = 18;
        _armRAngle = -18;
        break;
      case NovaState.celebrating:
        _armLAngle = 150;
        _armRAngle = -150;
        break;
    }

    if (!initial) {
      // Fire pop on every state change
      _popCtrl.forward(from: 0);
    }

    if (_reduceMotion) return; // static pose only in reduced motion

    // Update leaf speed based on state
    switch (state) {
      case NovaState.thinking:
        _leafCtrl.duration = const Duration(milliseconds: 1200);
        break;
      case NovaState.celebrating:
        _leafCtrl.duration = const Duration(milliseconds: 400);
        break;
      default:
        _leafCtrl.duration = const Duration(milliseconds: 3000);
    }
    _leafCtrl.repeat(reverse: true);

    switch (state) {
      case NovaState.idle:
        _breatheCtrl.repeat(reverse: true);
        _blinkCtrl.repeat();
        _lookCtrl.repeat();
        break;
      case NovaState.thinking:
        _swayCtrl.repeat(reverse: true);
        _scanCtrl.repeat();
        _fxCtrl.repeat(); // dots + question bob
        break;
      case NovaState.happy:
        _hopCtrl.repeat();
        _fxCtrl.repeat(); // sparkle
        break;
      case NovaState.error:
        _shakeCtrl.repeat();
        _fxCtrl.repeat(); // sweat + scrib
        break;
      case NovaState.celebrating:
        _jumpCtrl.repeat();
        _mouthCtrl.repeat(reverse: true);
        _hatCtrl.repeat(reverse: true);
        _fxCtrl.repeat(); // sparkle + confetti
        break;
    }
  }

  @override
  void didUpdateWidget(NovaWidget old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) {
      _applyState(widget.state);
    }
  }

  @override
  void dispose() {
    _popCtrl.dispose();
    _breatheCtrl.dispose();
    _blinkCtrl.dispose();
    _lookCtrl.dispose();
    _swayCtrl.dispose();
    _hopCtrl.dispose();
    _shakeCtrl.dispose();
    _jumpCtrl.dispose();
    _mouthCtrl.dispose();
    _scanCtrl.dispose();
    _leafCtrl.dispose();
    _hatCtrl.dispose();
    _fxCtrl.dispose();
    super.dispose();
  }

  // ── Derived blink progress ─────────────────────────────────────────────
  // CSS blink: 0..93% scaleY(1), 96% scaleY(.1), 100% scaleY(1)
  double get _blinkProgress {
    final t = _blinkCtrl.value; // 0..1 over 4200ms
    if (t < 0.93) return 0;
    if (t < 0.96) return (t - 0.93) / 0.03;
    return 1.0 - (t - 0.96) / 0.04;
  }

  @override
  Widget build(BuildContext context) {
    final canvas = AnimatedBuilder(
      animation: Listenable.merge([
        _popCtrl, _breatheCtrl, _blinkCtrl, _lookCtrl,
        _swayCtrl, _hopCtrl, _shakeCtrl, _jumpCtrl,
        _mouthCtrl, _scanCtrl, _leafCtrl, _hatCtrl, _fxCtrl,
      ]),
      builder: (context, _) {
        // Derive body Y offset
        double bodyY = 0;
        double bodyShakeX = 0;
        double bodySway = 0;
        double armL = _armLAngle;
        double armR = _armRAngle;

        switch (widget.state) {
          case NovaState.happy:
            bodyY = _hopAnim.value;
            break;
          case NovaState.thinking:
            bodySway = _swayAnim.value;
            break;
          case NovaState.error:
            bodyShakeX = _shakeAnim.value;
            break;
          case NovaState.celebrating:
            bodyY = _jumpAnim.value;
            // Waving arms
            armL = 132 + math.sin(_fxCtrl.value * math.pi * 2) * 16.5;
            armR = -(132 + math.sin(_fxCtrl.value * math.pi * 2) * 16.5);
            break;
          case NovaState.idle:
            break;
        }

        // Thinking: arm scratch on right
        if (widget.state == NovaState.thinking) {
          armR = -150 + math.sin(_fxCtrl.value * math.pi * 2) * 7;
        }

        return CustomPaint(
          painter: NovaPainter(
            state: widget.state,
            breathe: _breatheAnim.value,
            blinkProgress: _blinkProgress,
            lookX: widget.state == NovaState.idle ? _lookAnim.value : 0,
            popProgress: _popAnim.value,
            bodyOffsetY: bodyY,
            bodySway: bodySway,
            bodyShakeX: bodyShakeX,
            armLAngle: armL,
            armRAngle: armR,
            scanDash: widget.state == NovaState.thinking ? _scanAnim.value : 0,
            leafAngle: _leafAnim.value,
            hatOffsetY: widget.state == NovaState.celebrating
                ? _hatAnim.value
                : 0,
            confettiT: _fxCtrl.value,
            mouthScale: widget.state == NovaState.celebrating
                ? _mouthAnim.value
                : 1.0,
            sparkleT: _fxCtrl.value,
            dotT: _fxCtrl.value,
          ),
          size: Size(widget.size, widget.size * 330 / 300),
        );
      },
    );

    final novaCanvas = SizedBox(
      width: widget.size,
      height: widget.size * 330 / 300,
      child: canvas,
    );

    if (widget.caption != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(child: novaCanvas),
          const SizedBox(height: 8),
          Text(
            widget.caption!,
            textAlign: TextAlign.center,
            semanticsLabel: widget.caption,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Semantics(
      label: 'Nova, SnapFood\'s food wizard chef mascot',
      child: ExcludeSemantics(child: novaCanvas),
    );
  }
}
