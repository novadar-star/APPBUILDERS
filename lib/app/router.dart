import 'package:go_router/go_router.dart';
import 'package:snapfood/features/home/home_screen.dart';
import 'package:snapfood/features/scan/scan_screen.dart';
import 'package:snapfood/features/review/review_screen.dart';
import 'package:snapfood/features/results/results_screen.dart';
import 'package:snapfood/features/detail/detail_screen.dart';

final appRouter = GoRouter(
  routes: [
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
      builder: (context, state) => DetailScreen(id: state.pathParameters['id']!),
    ),
  ],
);
