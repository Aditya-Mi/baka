import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:baka/widgets/illustrations.dart' show QuillIcon;

// ─────────────────────────────────────────────────────────────────────────────
// AppIcon — Baka's one icon set. 24×24 grid, 1.75 stroke, round caps and
// joins, no fills. Each glyph is SVG path data, parsed once and cached.
// The quill delegates to the illustrated QuillIcon so Write and Edit match.
// ─────────────────────────────────────────────────────────────────────────────

enum AppIconData {
  // Navigate
  back, close, chevronRight, chevronDown, chevronUp, search, book, stats, cog,
  // Write
  quill, pencil, hash, mapPin, cloud, music, image, images, camera,
  calendar, clock, history,
  // Voice
  mic, micOff, play, stop, trash,
  // Settings
  user, contrast, sun, moon, typeIcon, bell, bellOff, lock, lockOpen, key,
  fingerprint, upload, download, share, folderOpen, info,
  // State
  check, checkCircle, alert, backspace, plus,
}

const _circle10 = 'M12 2a10 10 0 1 0 0 20a10 10 0 1 0 0-20';

const Map<AppIconData, String> _glyphs = {
  AppIconData.back:         'M15 18l-6-6 6-6',
  AppIconData.close:        'M18 6L6 18M6 6l12 12',
  AppIconData.chevronRight: 'M9 18l6-6-6-6',
  AppIconData.chevronDown:  'M6 9l6 6 6-6',
  AppIconData.chevronUp:    'M18 15l-6-6-6 6',
  AppIconData.search:       'M10.5 4a6.5 6.5 0 1 0 0 13a6.5 6.5 0 1 0 0-13M20 20l-4.5-4.5',
  AppIconData.book:         'M4 5q0-1 1-1h6q1 0 1 1v15q0-1-1-1H5q-1 0-1 1ZM20 5q0-1-1-1h-6q-1 0-1 1v15q0-1 1-1h6q1 0 1 1ZM6.5 8h3M6.5 11h3M14.5 8h3M14.5 11h3',
  AppIconData.stats:        'M4 12h3.5v8H4ZM10.25 7h3.5v13h-3.5ZM16.5 4H20v16h-3.5Z',
  AppIconData.cog:          'M12 9a3 3 0 1 0 0 6a3 3 0 1 0 0-6M12 2v3M12 19v3M2 12h3M19 12h3M5 5l2 2M17 17l2 2M19 5l-2 2M7 17l-2 2',

  AppIconData.pencil:       'M4 20v-3L16 5l3 3L7 20ZM13 8l3 3',
  AppIconData.hash:         'M4 9h16M4 15h16M10 3L8 21M16 3l-2 18',
  AppIconData.mapPin:       'M20 10c0 5-5.5 10.2-7.4 11.8a1 1 0 0 1-1.2 0C9.5 20.2 4 15 4 10a8 8 0 0 1 16 0M12 7a3 3 0 1 0 0 6a3 3 0 1 0 0-6',
  AppIconData.cloud:        'M17.5 19H9a7 7 0 1 1 6.7-9h1.8a4.5 4.5 0 1 1 0 9Z',
  AppIconData.music:        'M9 18V5l12-2v13M6 15a3 3 0 1 0 0 6a3 3 0 1 0 0-6M18 13a3 3 0 1 0 0 6a3 3 0 1 0 0-6',
  AppIconData.image:        'M5 3h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2ZM9 7a2 2 0 1 0 0 4a2 2 0 1 0 0-4M21 15l-3.1-3.1a2 2 0 0 0-2.8 0L6 21',
  AppIconData.images:       'M18 22H4a2 2 0 0 1-2-2V6M8 2h12a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2ZM12 6.5a1.5 1.5 0 1 0 0 3a1.5 1.5 0 1 0 0-3M22 13l-2.6-2.6a2 2 0 0 0-2.8 0L10 17',
  AppIconData.camera:       'M14.5 4h-5L7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3ZM12 10a3 3 0 1 0 0 6a3 3 0 1 0 0-6',
  AppIconData.calendar:     'M6 5h12a2.5 2.5 0 0 1 2.5 2.5v10A2.5 2.5 0 0 1 18 20H6a2.5 2.5 0 0 1-2.5-2.5v-10A2.5 2.5 0 0 1 6 5ZM3.5 10h17M8 3v4M16 3v4',
  AppIconData.clock:        'M12 3a9 9 0 1 0 0 18a9 9 0 1 0 0-18M12 7v5l3 2',
  AppIconData.history:      'M3 12a9 9 0 1 0 2.6-6.4L3 8M3 3v5h5M12 7v5l4 2',

  AppIconData.mic:          'M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3ZM19 10v2a7 7 0 0 1-14 0v-2M12 19v3',
  AppIconData.micOff:       'M2 2l20 20M18.9 13.2A7 7 0 0 0 19 12v-2M5 10v2a7 7 0 0 0 12 5M15 9.3V5a3 3 0 0 0-5.7-1.3M9 9v3a3 3 0 0 0 5.1 2.1M12 19v3',
  AppIconData.play:         'M7 4.5v15a1 1 0 0 0 1.5.9l12-7.5a1 1 0 0 0 0-1.8l-12-7.5A1 1 0 0 0 7 4.5Z',
  AppIconData.stop:         'M8 6h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2Z',
  AppIconData.trash:        'M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2M10 11v6M14 11v6',

  AppIconData.user:         'M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2M12 3a4 4 0 1 0 0 8a4 4 0 1 0 0-8',
  AppIconData.contrast:     '${_circle10}M12 18a6 6 0 0 0 0-12Z',
  AppIconData.sun:          'M12 8a4 4 0 1 0 0 8a4 4 0 1 0 0-8M12 2v2M12 20v2M2 12h2M20 12h2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4',
  AppIconData.moon:         'M12 3a6 6 0 0 0 9 9a9 9 0 1 1-9-9Z',
  AppIconData.typeIcon:     'M5 7V5h14v2M12 5v14M9 19h6',
  AppIconData.bell:         'M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9M10.3 21a2 2 0 0 0 3.4 0',
  AppIconData.bellOff:      'M8.7 3A6 6 0 0 1 18 8c0 2.2.3 3.8.7 5M17 17H3s3-2 3-9c0-.6.1-1.2.3-1.7M10.3 21a2 2 0 0 0 3.4 0M2 2l20 20',
  AppIconData.lock:         'M7 11h10a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2ZM7 11V7a5 5 0 0 1 10 0v4',
  AppIconData.lockOpen:     'M7 11h10a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2ZM7 11V7a5 5 0 0 1 9.9-1',
  AppIconData.key:          'M15.5 2.5a6 6 0 1 0 0 12a6 6 0 1 0 0-12M11.3 12.7L3 21M5.5 18.5l2 2M8 16l2 2M16.5 7.5h.01',
  AppIconData.fingerprint:  'M12 10a2 2 0 0 0-2 2c0 1-.1 2.5-.3 4M14 13.1c0 2.4 0 6.4-1 8.9M17.3 21c.1-.6.4-2.3.5-3M2 12a10 10 0 0 1 18-6M21.8 16c.2-2 .1-5.4 0-6M5 19.5C5.5 18 6 15 6 12a6 6 0 0 1 .3-2M8.7 22c.2-.7.5-1.3.6-2M9 6.8a6 6 0 0 1 9 5.2v2',
  AppIconData.upload:       'M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M17 8l-5-5-5 5M12 3v12',
  AppIconData.download:     'M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M7 10l5 5 5-5M12 15V3',
  AppIconData.share:        'M12 3v12M8 7l4-4 4 4M5 12v7a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-7',
  AppIconData.folderOpen:   'M6 14l1.5-2.9A2 2 0 0 1 9.2 10H20a2 2 0 0 1 1.9 2.5l-1.5 6a2 2 0 0 1-2 1.5H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h3.9a2 2 0 0 1 1.7.9l.8 1.2a2 2 0 0 0 1.7.9H18a2 2 0 0 1 2 2v2',
  AppIconData.info:         '${_circle10}M12 16v-4M12 8h.01',

  AppIconData.check:        'M20 6L9 17l-5-5',
  AppIconData.checkCircle:  '${_circle10}M8.5 12l2.5 2.5 5-5',
  AppIconData.alert:        '${_circle10}M12 8v4M12 16h.01',
  AppIconData.backspace:    'M10 5a2 2 0 0 0-1.3.5l-6.4 5.8a1 1 0 0 0 0 1.4l6.4 5.8A2 2 0 0 0 10 19h10a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2ZM12 9l6 6M18 9l-6 6',
  AppIconData.plus:         'M5 12h14M12 5v14',
};

class AppIcon extends StatelessWidget {
  final AppIconData icon;
  final double size;
  final Color color;
  final String? semanticLabel;
  const AppIcon(this.icon,
      {super.key, this.size = 24, required this.color, this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    final Widget glyph = icon == AppIconData.quill
        ? QuillIcon(size: size, color: color)
        : CustomPaint(
            size: Size(size, size),
            painter: _AppIconPainter(icon: icon, color: color),
          );
    return semanticLabel == null
        ? ExcludeSemantics(child: glyph)
        : Semantics(label: semanticLabel, child: ExcludeSemantics(child: glyph));
  }
}

class _AppIconPainter extends CustomPainter {
  final AppIconData icon;
  final Color color;
  const _AppIconPainter({required this.icon, required this.color});

  static const _vb = 24.0;
  static final _cache = <AppIconData, Path>{};

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / _vb, size.height / _vb);
    final path = _cache.putIfAbsent(icon, () => parseSvgPath(_glyphs[icon]!));
    canvas
      ..save()
      ..translate((size.width - _vb * s) / 2, (size.height - _vb * s) / 2)
      ..scale(s)
      ..drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 1.75
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_AppIconPainter o) => o.icon != icon || o.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// SVG path data → Path. Covers M L H V C S Q T A Z, absolute and relative.
// Shared with the self-drawing doodles.
// ─────────────────────────────────────────────────────────────────────────────

final _token = RegExp(r'[MLHVCSQTAZmlhvcsqtaz]|-?(?:\d+\.?\d*|\.\d+)(?:e-?\d+)?');

Path parseSvgPath(String d) {
  final tokens = _token.allMatches(d).map((m) => m.group(0)!).toList();
  final path = Path();
  var i = 0;
  var cmd = 'M';
  var cx = 0.0, cy = 0.0;       // current point
  var sx = 0.0, sy = 0.0;       // subpath start
  var lcx = 0.0, lcy = 0.0;     // last control point (for S / T)
  var prev = '';

  bool isCmd(String t) => RegExp(r'^[A-Za-z]$').hasMatch(t);
  double n() => double.parse(tokens[i++]);

  while (i < tokens.length) {
    if (isCmd(tokens[i])) cmd = tokens[i++];
    final rel = cmd == cmd.toLowerCase();
    final ox = rel ? cx : 0.0, oy = rel ? cy : 0.0;
    switch (cmd.toUpperCase()) {
      case 'M':
        cx = ox + n(); cy = oy + n();
        path.moveTo(cx, cy);
        sx = cx; sy = cy;
        // Further pairs after M are implicit L.
        cmd = rel ? 'l' : 'L';
      case 'L':
        cx = ox + n(); cy = oy + n();
        path.lineTo(cx, cy);
      case 'H':
        cx = ox + n();
        path.lineTo(cx, cy);
      case 'V':
        cy = oy + n();
        path.lineTo(cx, cy);
      case 'C':
        final x1 = ox + n(), y1 = oy + n();
        lcx = ox + n(); lcy = oy + n();
        cx = ox + n(); cy = oy + n();
        path.cubicTo(x1, y1, lcx, lcy, cx, cy);
      case 'S':
        final reflect = 'CS'.contains(prev);
        final x1 = reflect ? 2 * cx - lcx : cx, y1 = reflect ? 2 * cy - lcy : cy;
        lcx = ox + n(); lcy = oy + n();
        cx = ox + n(); cy = oy + n();
        path.cubicTo(x1, y1, lcx, lcy, cx, cy);
      case 'Q':
        lcx = ox + n(); lcy = oy + n();
        cx = ox + n(); cy = oy + n();
        path.quadraticBezierTo(lcx, lcy, cx, cy);
      case 'T':
        final reflect = 'QT'.contains(prev);
        lcx = reflect ? 2 * cx - lcx : cx; lcy = reflect ? 2 * cy - lcy : cy;
        cx = ox + n(); cy = oy + n();
        path.quadraticBezierTo(lcx, lcy, cx, cy);
      case 'A':
        final rx = n(), ry = n(), rot = n();
        final large = n() != 0, sweep = n() != 0;
        cx = ox + n(); cy = oy + n();
        path.arcToPoint(Offset(cx, cy),
            radius: Radius.elliptical(rx, ry),
            rotation: rot,
            largeArc: large,
            clockwise: sweep);
      case 'Z':
        path.close();
        cx = sx; cy = sy;
    }
    prev = cmd.toUpperCase();
  }
  return path;
}
