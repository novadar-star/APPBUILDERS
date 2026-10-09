// OnboardingScreen — 5 pages, skippable, shows once.
// Driven entirely by [OnboardingStore] + [onboardingDoneNotifierProvider].
// Pages:
//   0  Welcome          — Nova idle → happy after 1 s
//   1  How it works     — Nova thinking → happy
//   2  Preferences      — diet chips, Nova happy on each tap
//   3  Camera           — Nova explains camera permission
//   4  All done         — Nova celebrating → go to home

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapfood/app/providers.dart';
import 'package:snapfood/app/theme.dart';
import 'package:snapfood/data/onboarding_store.dart';
import 'package:snapfood/data/preferences_store.dart';
import 'package:snapfood/domain/models.dart';
import 'package:snapfood/shared/nova/nova_state.dart';
import 'package:snapfood/shared/nova/nova_widget.dart';

// ---------------------------------------------------------------------------
// OnboardingScreen
// ---------------------------------------------------------------------------

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;
  static const _totalPages = 5;

  // Page 0: delayed nova state switch
  NovaState _page0Nova = NovaState.idle;
  Timer? _page0Timer;

  // Page 1: thinking → happy on tap
  NovaState _page1Nova = NovaState.thinking;

  // Page 2: preferences collected during onboarding
  final Set<Equipment> _selectedEquipment = {};
  int _extraBudget = 30;

  // Page 3: camera permission feedback
  NovaState _page3Nova = NovaState.idle;

  @override
  void initState() {
    super.initState();
    _startPage0();
  }

  void _startPage0() {
    _page0Nova = NovaState.idle;
    _page0Timer = Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => _page0Nova = NovaState.happy);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _page0Timer?.cancel();
    super.dispose();
  }

  Future<void> _goTo(int page) async {
    await _ctrl.animateToPage(
      page,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finish() async {
    HapticFeedback.lightImpact();
    await PreferencesStore().save(Preferences(
      equipment: _selectedEquipment.isEmpty
          ? {Equipment.riceCooker}
          : _selectedEquipment,
      extraBudgetPesos: _extraBudget,
    ));
    await OnboardingStore().markDone();
    ref.read(onboardingDoneNotifierProvider.notifier).state = true;
    if (mounted) context.go('/');
  }

  void _skip() {
    HapticFeedback.selectionClick();
    _finish();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: NovaColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar: skip + progress ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  // Progress dots
                  Expanded(
                    child: Row(
                      children: List.generate(_totalPages, (i) {
                        final active = i == _page;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.only(right: 6),
                          width: active ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active
                                ? NovaColors.green
                                : NovaColors.lineLight,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        );
                      }),
                    ),
                  ),
                  // Skip button
                  TextButton(
                    onPressed: _skip,
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.onSurfaceVariant,
                      textStyle: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),

            // ── Pages ────────────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _ctrl,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _page = p),
                children: [
                  _Page0(
                    novaState: _page0Nova,
                    onNext: () => _goTo(1),
                  ),
                  _Page1(
                    novaState: _page1Nova,
                    onThink: () =>
                        setState(() => _page1Nova = NovaState.thinking),
                    onHappy: () =>
                        setState(() => _page1Nova = NovaState.happy),
                    onNext: () => _goTo(2),
                  ),
                  _Page2(
                    selectedEquipment: _selectedEquipment,
                    extraBudget: _extraBudget,
                    onEquipmentChanged: (eq, selected) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (selected) {
                          _selectedEquipment.add(eq);
                        } else {
                          _selectedEquipment.remove(eq);
                        }
                      });
                    },
                    onBudgetChanged: (v) =>
                        setState(() => _extraBudget = v),
                    onNext: () => _goTo(3),
                  ),
                  _Page3(
                    novaState: _page3Nova,
                    onNovaStateChanged: (s) =>
                        setState(() => _page3Nova = s),
                    onNext: () => _goTo(4),
                  ),
                  _Page4(onFinish: _finish),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared layout helpers
// ---------------------------------------------------------------------------

class _PageShell extends StatelessWidget {
  final NovaWidget nova;
  final String heading;
  final String body;
  final String ctaLabel;
  final VoidCallback onCta;
  final List<Widget> extras;

  const _PageShell({
    required this.nova,
    required this.heading,
    required this.body,
    required this.ctaLabel,
    required this.onCta,
    this.extras = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 24),
          nova,
          const SizedBox(height: 28),
          Text(
            heading,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: NovaColors.brown,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.55,
            ),
          ),
          if (extras.isNotEmpty) ...[
            const SizedBox(height: 24),
            ...extras,
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onCta,
              style: FilledButton.styleFrom(
                backgroundColor: NovaColors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              child: Text(
                ctaLabel,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 0 — Welcome
// ---------------------------------------------------------------------------

class _Page0 extends StatelessWidget {
  final NovaState novaState;
  final VoidCallback onNext;

  const _Page0({required this.novaState, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      nova: NovaWidget(
        state: novaState,
        size: 200,
        caption: "Hi, I'm Nova. Show me your food.",
      ),
      heading: "Your food wizard\nis ready.",
      body: "Take a photo of your meal and I'll\ntell you what it is — and how to make it.",
      ctaLabel: "Let's go",
      onCta: onNext,
    );
  }
}

// ---------------------------------------------------------------------------
// Page 1 — How it works
// ---------------------------------------------------------------------------

class _Page1 extends StatelessWidget {
  final NovaState novaState;
  final VoidCallback onThink;
  final VoidCallback onHappy;
  final VoidCallback onNext;

  const _Page1({
    required this.novaState,
    required this.onThink,
    required this.onHappy,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 24),
          NovaWidget(state: novaState, size: 160),
          const SizedBox(height: 28),
          Text(
            "Here's how it works.",
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: NovaColors.brown,
            ),
          ),
          const SizedBox(height: 24),
          // Three-step flow cards
          _StepCard(
            number: 1,
            label: 'Snap',
            detail: 'Point your camera at any dish.',
            onTap: onThink,
          ),
          const SizedBox(height: 10),
          _StepCard(
            number: 2,
            label: 'I think',
            detail: "I'll figure out what it is — on your phone, no internet needed.",
            onTap: onThink,
          ),
          const SizedBox(height: 10),
          _StepCard(
            number: 3,
            label: 'Recipe',
            detail: "You get a recipe tailored to what you've got.",
            onTap: onHappy,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                backgroundColor: NovaColors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              child: const Text(
                'Got it',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int number;
  final String label;
  final String detail;
  final VoidCallback onTap;

  const _StepCard({
    required this.number,
    required this.label,
    required this.detail,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: NovaColors.stageLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NovaColors.lineLight),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: NovaColors.green,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: NovaColors.brown,
                    ),
                  ),
                  Text(
                    detail,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF8A7A62),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 2 — Preferences
// ---------------------------------------------------------------------------

class _Page2 extends StatelessWidget {
  final Set<Equipment> selectedEquipment;
  final int extraBudget;
  final void Function(Equipment, bool) onEquipmentChanged;
  final void Function(int) onBudgetChanged;
  final VoidCallback onNext;

  const _Page2({
    required this.selectedEquipment,
    required this.extraBudget,
    required this.onEquipmentChanged,
    required this.onBudgetChanged,
    required this.onNext,
  });

  String _label(Equipment e) {
    switch (e) {
      case Equipment.riceCooker:
        return 'Rice cooker';
      case Equipment.kettle:
        return 'Kettle';
      case Equipment.microwave:
        return 'Microwave';
      case Equipment.stove:
        return 'Stove';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final novaState = selectedEquipment.isNotEmpty
        ? NovaState.happy
        : NovaState.idle;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Center(
            child: NovaWidget(
              state: novaState,
              size: 120,
              caption: selectedEquipment.isEmpty
                  ? "What do you cook with?"
                  : "Nice. I'll keep that in mind.",
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'What do you have?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: NovaColors.brown,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Pick your cooking gear. I'll only suggest recipes you can actually make.",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF8A7A62),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Equipment chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Equipment.values.map((eq) {
              final selected = selectedEquipment.contains(eq);
              return FilterChip(
                label: Text(_label(eq)),
                selected: selected,
                onSelected: (val) => onEquipmentChanged(eq, val),
                selectedColor: NovaColors.green.withValues(alpha: 0.15),
                checkmarkColor: NovaColors.green,
                labelStyle: TextStyle(
                  color: selected ? NovaColors.darkGreen : NovaColors.brown,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                ),
                side: BorderSide(
                  color: selected ? NovaColors.green : NovaColors.lineLight,
                ),
                backgroundColor: NovaColors.stageLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),
          Text(
            'Extra ingredient budget',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: NovaColors.brown,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [0, 30, 50, 100].map((amount) {
              final selected = extraBudget == amount;
              return ChoiceChip(
                label: Text('₱$amount'),
                selected: selected,
                onSelected: (val) {
                  if (val) onBudgetChanged(amount);
                },
                selectedColor: NovaColors.green.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  color: selected ? NovaColors.darkGreen : NovaColors.brown,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                ),
                side: BorderSide(
                  color: selected ? NovaColors.green : NovaColors.lineLight,
                ),
                backgroundColor: NovaColors.stageLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }).toList(),
          ),

          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                backgroundColor: NovaColors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              child: const Text(
                'Save preferences',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 3 — Camera permission
// ---------------------------------------------------------------------------

class _Page3 extends StatelessWidget {
  final NovaState novaState;
  final void Function(NovaState) onNovaStateChanged;
  final VoidCallback onNext;

  const _Page3({
    required this.novaState,
    required this.onNovaStateChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isDenied = novaState == NovaState.error;

    return _PageShell(
      nova: NovaWidget(
        state: novaState,
        size: 160,
        caption: isDenied
            ? "No worries. You can enable it in Settings."
            : "I need your camera so I can see your food.",
      ),
      heading: isDenied
          ? "Camera access denied."
          : "One thing before we start.",
      body: isDenied
          ? "Go to Settings → SnapFood → Camera to turn it on. You can also use photo library mode."
          : "I use your camera to see your food. It never leaves your phone.",
      ctaLabel: isDenied ? "Continue anyway" : "Allow camera",
      onCta: () {
        // In a real app this calls permission_handler here.
        // For mock/debug: simulate granted by going to next page.
        onNovaStateChanged(NovaState.happy);
        Future.delayed(const Duration(milliseconds: 600), onNext);
      },
      extras: isDenied
          ? [
              OutlinedButton.icon(
                onPressed: () {
                  // In production: AppSettings.openAppSettings()
                  // For now, just move on.
                  onNext();
                },
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Open Settings'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: NovaColors.green,
                  side: const BorderSide(color: NovaColors.green),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ]
          : [],
    );
  }
}

// ---------------------------------------------------------------------------
// Page 4 — All done (celebrating)
// ---------------------------------------------------------------------------

class _Page4 extends StatelessWidget {
  final VoidCallback onFinish;

  const _Page4({required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      nova: const NovaWidget(
        state: NovaState.celebrating,
        size: 200,
        caption: "Let's cook.",
      ),
      heading: "You're all set.",
      body: "I'm excited. Let's find something delicious to make.",
      ctaLabel: "Start cooking",
      onCta: onFinish,
    );
  }
}
