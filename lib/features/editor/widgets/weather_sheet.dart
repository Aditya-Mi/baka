import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/models/anchor.dart';
import 'package:baka/widgets/weather_icon.dart';
import 'package:baka/core/fonts/font_theme.dart';

class WeatherResult {
  final WeatherCondition condition;
  final int? temp;
  final bool isRemove;
  const WeatherResult(this.condition, this.temp) : isRemove = false;
  const WeatherResult.remove()
      : condition = WeatherCondition.sunny, // unused placeholder
        temp = null,
        isRemove = true;
}

Future<WeatherResult?> showWeatherSheet(
  BuildContext context, {
  WeatherCondition? initialCondition,
  int? initialTemp,
}) {
  return showModalBottomSheet<WeatherResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _WeatherSheet(
      initialCondition: initialCondition,
      initialTemp: initialTemp,
    ),
  );
}

class _WeatherSheet extends StatefulWidget {
  final WeatherCondition? initialCondition;
  final int? initialTemp;
  const _WeatherSheet({this.initialCondition, this.initialTemp});

  @override
  State<_WeatherSheet> createState() => _WeatherSheetState();
}

class _WeatherSheetState extends State<_WeatherSheet> {
  WeatherCondition? _condition;
  late final TextEditingController _tempCtrl;

  @override
  void initState() {
    super.initState();
    _condition = widget.initialCondition;
    _tempCtrl  = TextEditingController(
      text: widget.initialTemp != null ? '${widget.initialTemp}' : '',
    );
  }

  @override
  void dispose() {
    _tempCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: t.surfaceElev,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: t.outline.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text("What's the weather?",
                style: TextStyle(fontFamily: context.fonts.display,
                  fontSize: 20, fontWeight: FontWeight.w600,
                  color: t.onBackground)),
            const SizedBox(height: 20),
            // Icon grid
            Wrap(
              spacing: 12, runSpacing: 12,
              children: WeatherCondition.values.map((c) {
                final selected = c == _condition;
                return GestureDetector(
                  onTap: () => setState(() => _condition = c),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: selected
                          ? t.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? t.primary : t.outline,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        WeatherIcon(c,
                            size: 28,
                            color: selected ? t.primary : t.onSurfaceMuted),
                        const SizedBox(height: 4),
                        Text(c.label,
                            style: TextStyle(fontFamily: context.fonts.accent,
                              fontSize: 11,
                              color: selected ? t.primary : t.onSurfaceMuted)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // Temperature
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tempCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^-?\d{0,3}')),
                    ],
                    cursorColor: t.primary,
                    style: TextStyle(fontFamily: context.fonts.body,
                      fontSize: 16, color: t.onBackground),
                    decoration: InputDecoration(
                      hintText: 'Temperature (optional)',
                      hintStyle: TextStyle(fontFamily: context.fonts.body,
                        fontSize: 16, fontStyle: FontStyle.italic,
                        color: t.onSurfaceMuted),
                      suffixText: '°C',
                      suffixStyle: TextStyle(fontFamily: context.fonts.body,
                        fontSize: 16, color: t.onSurfaceMuted),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (widget.initialCondition != null)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(const WeatherResult.remove()),
                    style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error),
                    child: Text('Remove',
                        style: TextStyle(fontFamily: context.fonts.accent, fontSize: 16)),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                      foregroundColor: t.onSurfaceMuted),
                  child: Text('Cancel',
                      style: TextStyle(fontFamily: context.fonts.accent, fontSize: 16)),
                ),
                const SizedBox(width: 8),
                Material(
                  color: _condition != null ? t.primary : t.outline,
                  borderRadius: BorderRadius.circular(50),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: _condition == null ? null : _submit,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Text('Set',
                          style: TextStyle(fontFamily: context.fonts.accent,
                            fontSize: 16, fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final temp = int.tryParse(_tempCtrl.text.trim());
    Navigator.of(context).pop(WeatherResult(_condition!, temp));
  }
}
