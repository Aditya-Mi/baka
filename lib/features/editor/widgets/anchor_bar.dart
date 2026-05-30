import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/models/anchor.dart';
import 'package:baka/widgets/weather_icon.dart';
import 'location_sheet.dart';
import 'photo_sheet.dart';
import 'weather_sheet.dart';

class AnchorBar extends StatelessWidget {
  final Anchor anchor;
  final ValueChanged<Anchor> onChanged;

  const AnchorBar({super.key, required this.anchor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.outline, width: 0.6)),
        color: t.background,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 10,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [

          // ── Location ──────────────────────────────────────────────────
          _Chip(
            onTap: () async {
              final result = await showLocationSheet(
                context, initial: anchor.location);
              if (result == null) return;
              onChanged(anchor.copyWith(
                location: result.isEmpty ? null : result));
            },
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                anchor.hasLocation
                    ? Icons.location_on_rounded
                    : Icons.location_on_outlined,
                size: 16,
                color: anchor.hasLocation ? t.primary : t.onSurfaceMuted,
              ),
              const SizedBox(width: 5),
              Text(
                anchor.hasLocation ? anchor.location! : 'Location',
                style: TextStyle(fontFamily: 'Caveat', fontSize: 14,
                    color: anchor.hasLocation ? t.primary : t.onSurfaceMuted),
              ),
            ]),
            active: anchor.hasLocation,
            t: t,
          ),

          // ── Weather ───────────────────────────────────────────────────
          _Chip(
            onTap: () async {
              final result = await showWeatherSheet(
                context,
                initialCondition: anchor.weatherCondition,
                initialTemp: anchor.weatherTemp,
              );
              if (result == null) return; // cancelled — keep existing
              if (result.isRemove) {
                onChanged(anchor.copyWith(weather: null, weatherTemp: null));
              } else {
                onChanged(anchor.copyWith(
                  weather: result.condition,
                  weatherTemp: result.temp,
                ));
              }
            },
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              anchor.hasWeather
                  ? WeatherIcon(anchor.weatherCondition!, size: 16, color: t.primary)
                  : Icon(Icons.wb_cloudy_outlined, size: 16, color: t.onSurfaceMuted),
              const SizedBox(width: 5),
              Text(
                anchor.hasWeather
                    ? (anchor.weatherTemp != null
                        ? '${anchor.weatherCondition!.label} · ${anchor.weatherTemp}°C'
                        : anchor.weatherCondition!.label)
                    : 'Weather',
                style: TextStyle(fontFamily: 'Caveat', fontSize: 14,
                    color: anchor.hasWeather ? t.primary : t.onSurfaceMuted),
              ),
            ]),
            active: anchor.hasWeather,
            t: t,
          ),

          // ── Photo ─────────────────────────────────────────────────────
          _PhotoChip(
            anchor: anchor,
            t: t,
            onTap: () async {
              final result = await showPhotoSheet(
                context, existingPath: anchor.photoPath);
              if (result == null) return;
              onChanged(anchor.copyWith(
                photoPath: result.isEmpty ? null : result));
            },
          ),
        ],
      ),
    );
  }
}

// ── Generic chip ──────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final Widget child;
  final bool active;
  final BakaTokens t;
  final VoidCallback onTap;
  const _Chip({required this.child, required this.active,
      required this.t, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active
                ? t.primary.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? t.primary.withValues(alpha: 0.35) : t.outline,
              width: 1,
            ),
          ),
          child: child,
        ),
      );
}

// ── Photo chip — shows thumbnail when set ─────────────────────────────────────

class _PhotoChip extends StatelessWidget {
  final Anchor anchor;
  final BakaTokens t;
  final VoidCallback onTap;
  const _PhotoChip({required this.anchor, required this.t, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (!anchor.hasPhoto) {
      return _Chip(
        onTap: onTap,
        active: false,
        t: t,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.image_outlined, size: 16, color: t.onSurfaceMuted),
          const SizedBox(width: 5),
          Text('Photo', style: TextStyle(fontFamily: 'Caveat',
              fontSize: 14, color: t.onSurfaceMuted)),
        ]),
      );
    }

    return FutureBuilder<String>(
      future: _resolve(anchor.photoPath!),
      builder: (_, snap) {
        final hasFile = snap.hasData && File(snap.data!).existsSync();
        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: t.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: t.primary.withValues(alpha: 0.35), width: 1),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (hasFile)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.file(File(snap.data!),
                      width: 24, height: 24, fit: BoxFit.cover),
                )
              else
                Icon(Icons.image_rounded, size: 16, color: t.primary),
              const SizedBox(width: 5),
              Text('Photo', style: TextStyle(fontFamily: 'Caveat',
                  fontSize: 14, color: t.primary)),
            ]),
          ),
        );
      },
    );
  }

  Future<String> _resolve(String rel) async {
    final docs = await getApplicationDocumentsDirectory();
    return '${docs.path}/$rel';
  }
}
