import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapfood/data/onboarding_store.dart';
import 'package:snapfood/features/home/home_screen.dart';
import 'package:snapfood/features/onboarding/onboarding_screen.dart';
import 'package:snapfood/features/scan/scan_screen.dart';
import 'package:snapfood/features/review/review_screen.dart';
import 'package:snapfood/features/results/results_screen.dart';
import 'package:snapfood/features/detail/detail_screen.dart';

// ---------------------------------------------------------------------------
// Router factory
// ---------------------------------------------------------------------------
// go_router's redirect is synchronous, so we pass the resolved [onboardingDone]
// value in from [ProviderScope] via [RouterNotifier]. The simplest approach
// without adding routerProvider complexity is to create the router once with
// a refresh listenable keyed to the [onboardingDoneNotifierProvider].

GoRouter buildRouter(WidgetRef ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      // Run the async check only once on cold start.
      final done = await OnboardingStore().isDone();
      if (!done && state.matchedLocation != '/onboarding') {
        return '/onboarding';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/scan',
        builder: (context, state) => const ScanScreen(),
      ),
      GoRoute(
        path: '/review',
        builder: (context, state) => const ReviewScreen(),
      ),
      GoRoute(
        path: '/results',
        builder: (context, state) => const ResultsScreen(),
      ),
      GoRoute(
        path: '/recipe/:id',
        builder: (context, state) =>
            DetailScreen(id: state.pathParameters['id']!),
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Static fallback router (used by AppShell before ProviderScope is available)
// ---------------------------------------------------------------------------
// AppShell now builds the router via [_RouterWidget] so Riverpod is available.
final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final done = await OnboardingStore().isDone();
    if (!done && state.matchedLocation != '/onboarding') {
      return '/onboarding';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/scan',
      builder: (context, state) => const ScanScreen(),
    ),
    GoRoute(
      path: '/review',
      builder: (context, state) => const ReviewScreen(),
    ),
    GoRoute(
      path: '/results',
      builder: (context, state) => const ResultsScreen(),
    ),
    GoRoute(
      path: '/recipe/:id',
      builder: (context, state) =>
          DetailScreen(id: state.pathParameters['id']!),
    ),
  ],
);
