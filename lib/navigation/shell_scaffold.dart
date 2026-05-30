import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/widgets/illustrations.dart';

class ShellScaffold extends ConsumerWidget {
  final Widget child;
  const ShellScaffold({super.key, required this.child});

  static const _tabRoutes = ['/', '/stats', '/settings'];

  int _indexFromLocation(String location) {
    if (location.startsWith('/stats')) return 1;
    if (location.startsWith('/settings')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t        = context.tokens;
    final active   = t.primary;
    final inactive = t.onSurfaceMuted;
    final location = GoRouterState.of(context).matchedLocation;
    final tabIndex = _indexFromLocation(location);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!context.mounted) return;
        final exit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Exit Baka?',
                style: TextStyle(fontFamily: 'PlayfairDisplay',
                  fontSize: 18, fontWeight: FontWeight.w600,
                  color: t.onBackground)),
            content: Text('Your journal will be waiting.',
                style: TextStyle(fontFamily: 'Caveat',
                  fontSize: 16, color: t.onSurfaceMuted)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('Stay',
                    style: TextStyle(fontFamily: 'Caveat',
                      fontSize: 16, color: t.onSurfaceMuted)),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text('Exit',
                    style: TextStyle(fontFamily: 'Caveat',
                      fontSize: 16, color: t.primary,
                      fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
        if (exit == true) SystemNavigator.pop();
      },
      child: Scaffold(
        body: child,

        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/new'),
          backgroundColor: t.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: const StadiumBorder(),
          icon: const QuillIcon(size: 20, color: Colors.white),
          label: const Text('Write',
              style: TextStyle(fontFamily: 'Caveat',
                fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

        bottomNavigationBar: NavigationBar(
          selectedIndex: tabIndex,
          onDestinationSelected: (i) => context.go(_tabRoutes[i]),
          backgroundColor: t.surfaceElev,
          indicatorColor: t.primaryContainer,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon:         AppIcon(AppIconData.book,  size: 24, color: inactive),
              selectedIcon: AppIcon(AppIconData.book,  size: 24, color: active),
              label: 'Pages',
            ),
            NavigationDestination(
              icon:         AppIcon(AppIconData.stats, size: 24, color: inactive),
              selectedIcon: AppIcon(AppIconData.stats, size: 24, color: active),
              label: 'Stats',
            ),
            NavigationDestination(
              icon:         AppIcon(AppIconData.cog,   size: 24, color: inactive),
              selectedIcon: AppIcon(AppIconData.cog,   size: 24, color: active),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
