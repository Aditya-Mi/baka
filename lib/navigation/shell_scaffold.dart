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
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!context.mounted) return;
        final exit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Exit Baka?'),
            content: const Text('Your journal will be waiting.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                style: TextButton.styleFrom(foregroundColor: t.onSurfaceMuted),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        if (exit == true) SystemNavigator.pop();
      },
      child: Scaffold(
        body: child,

        // Write is the Pages tab's primary action only — on Stats/Settings it
        // covered real controls (calendar, biometrics toggle).
        floatingActionButton: tabIndex != 0 ? null : FloatingActionButton.extended(
          onPressed: () => context.push('/new'),
          backgroundColor: t.primary,
          foregroundColor: onPrimary,
          elevation: 2,
          shape: const StadiumBorder(),
          icon: QuillIcon(size: 20, color: onPrimary),
          label: Text('Write',
              style: AppText.handAction(context).copyWith(color: onPrimary)),
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
