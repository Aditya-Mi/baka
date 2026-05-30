import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:baka/core/auth/auth_provider.dart';
import 'package:baka/core/notifications/notification_service.dart';
import 'package:baka/core/notifications/reminder_provider.dart';
import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/core/theme/theme_provider.dart';
import 'package:baka/core/fonts/font_provider.dart';
import 'package:baka/features/lock/lock_screen.dart';
import 'package:baka/features/home/home_screen.dart';
import 'package:baka/features/editor/new_entry_screen.dart';
import 'package:baka/features/editor/edit_entry_screen.dart';
import 'package:baka/features/detail/entry_detail_screen.dart';
import 'package:baka/features/search/search_screen.dart';
import 'package:baka/features/tags/tags_screen.dart';
import 'package:baka/features/settings/settings_screen.dart';
import 'package:baka/features/stats/stats_screen.dart';
import 'package:baka/navigation/shell_scaffold.dart';

final _routerKey = GlobalKey<NavigatorState>();

GoRouter buildRouter() {
  return GoRouter(
    navigatorKey: _routerKey,
    initialLocation: '/',
    redirect: (context, state) {
      final auth   = ProviderScope.containerOf(context).read(authProvider);
      // Wait for storage read — blank screen shows instead (no redirect yet)
      if (!auth.isInitialized) return null;

      final atLock = state.matchedLocation == '/lock';
      if (!auth.configured && !atLock) return '/lock';
      if (auth.configured && auth.isLocked && !atLock) return '/lock';
      if (auth.configured && !auth.isLocked && atLock) return '/';
      return null;
    },
    routes: [
      // Full-screen routes (outside shell, no bottom nav)
      GoRoute(path: '/lock', builder: (_, __) => const LockScreen()),
      GoRoute(
        path: '/new',
        builder: (_, state) => NewEntryScreen(
          source: state.uri.queryParameters['source'],
          date: state.uri.queryParameters['date'],
        ),
      ),
      GoRoute(
        path: '/edit/:id',
        builder: (_, state) => EditEntryScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/entry/:id',
        builder: (_, state) => EntryDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
      GoRoute(path: '/tags',   builder: (_, __) => const TagsScreen()),
      GoRoute(
        path: '/tags/:tag',
        builder: (_, state) => TagsScreen(filterTag: state.pathParameters['tag']),
      ),
      // Shell routes (have bottom nav)
      ShellRoute(
        builder: (_, __, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(path: '/',         builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/stats',    builder: (_, __) => const StatsScreen()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        ],
      ),
    ],
  );
}

class App extends ConsumerWidget {
  final String? coldLaunchPayload;
  const App({super.key, this.coldLaunchPayload});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _AppRoot(coldLaunchPayload: coldLaunchPayload);
  }
}

class _AppRoot extends ConsumerStatefulWidget {
  final String? coldLaunchPayload;
  const _AppRoot({this.coldLaunchPayload});

  @override
  ConsumerState<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<_AppRoot> with WidgetsBindingObserver {
  DateTime? _pausedAt;
  late final GoRouter _router;
  bool _pendingNewEntry = false;

  // ThemeData cache — only rebuilt when fontKey actually changes,
  // not on every auth/route rebuild.
  String?   _cachedFontKey;
  ThemeData? _lightTheme;
  ThemeData? _darkTheme;

  ThemeData _light(String fontKey) {
    if (_cachedFontKey != fontKey || _lightTheme == null) {
      _cachedFontKey = fontKey;
      _lightTheme = AppTheme.light(fontKey: fontKey);
      _darkTheme  = AppTheme.dark(fontKey: fontKey);
    }
    return _lightTheme!;
  }

  ThemeData _dark(String fontKey) {
    _light(fontKey); // ensures both are built together
    return _darkTheme!;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _router = buildRouter();

    // Wire foreground/background notification tap → open new entry
    NotificationService.instance.onNotificationTap = (payload) {
      if (payload == 'open_new_entry' && mounted) {
        _router.push('/new?source=notification');
      }
    };

    // Cold-launch payload: queue navigation, fire after auth fully unlocks
    if (widget.coldLaunchPayload == 'open_new_entry') {
      _pendingNewEntry = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reschedule daily reminder on every app open (rotates notification body)
    ref.read(reminderProvider.notifier).refreshScheduleOnOpen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedAt != null &&
          DateTime.now().difference(_pausedAt!) > const Duration(minutes: 2)) {
        ref.read(authProvider.notifier).lock();
        _router.refresh();
      }
      _pausedAt = null;
      // Reschedule on resume too (rotates body)
      ref.read(reminderProvider.notifier).refreshScheduleOnOpen();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (_, next) {
      _router.refresh();
      // Fire pending notification navigation once auth is fully unlocked
      if (_pendingNewEntry && next.isInitialized && !next.isLocked) {
        _pendingNewEntry = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _router.push('/new?source=notification');
        });
      }
    });

    final auth      = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);
    final fontKey   = ref.watch(fontProvider);

    final light = _light(fontKey);
    final dark  = _dark(fontKey);

    // Blank screen while auth state loads from storage — prevents lock screen flash.
    // The Offstage widget pre-warms font metrics for all key font/weight combos
    // so first navigation to each screen doesn't trigger metric computation.
    if (!auth.isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: light,
        darkTheme: dark,
        themeMode: themeMode,
        home: const Scaffold(
          body: Stack(children: [
            SizedBox.shrink(),
            Offstage(child: _FontWarmup()),
          ]),
        ),
      );
    }

    return MaterialApp.router(
      title: 'Baka Journal',
      debugShowCheckedModeBanner: false,
      theme: light,
      darkTheme: dark,
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}

/// Renders key font+weight combinations off-screen during the auth init gap.
/// Pre-computes glyph metrics so first navigation to each screen is instant.
class _FontWarmup extends StatelessWidget {
  const _FontWarmup();

  static TextStyle _s(String family, double size,
      [FontWeight w = FontWeight.w400]) =>
      TextStyle(fontFamily: family, fontSize: size, fontWeight: w);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Caveat — used in almost every widget
        Text('warm', style: _s('Caveat', 14)),
        Text('warm', style: _s('Caveat', 16)),
        Text('warm', style: _s('Caveat', 18)),
        Text('warm', style: _s('Caveat', 28, FontWeight.w700)),
        Text('warm', style: _s('Caveat', 30, FontWeight.w700)),
        Text('warm', style: _s('Caveat', 40, FontWeight.w700)),
        // PlayfairDisplay — headers, AppBar titles
        Text('warm', style: _s('PlayfairDisplay', 18, FontWeight.w600)),
        Text('warm', style: _s('PlayfairDisplay', 20, FontWeight.w600)),
        Text('warm', style: _s('PlayfairDisplay', 22, FontWeight.w600)),
        // Lora — body text in editor and detail
        Text('warm', style: _s('Lora', 16)),
        Text('warm', style: _s('Lora', 17)),
        const Text('warm', style: TextStyle(
            fontFamily: 'Lora', fontSize: 17, fontStyle: FontStyle.italic)),
        // CourierPrime — counters
        Text('warm', style: _s('CourierPrime', 12)),
      ],
    );
  }
}
