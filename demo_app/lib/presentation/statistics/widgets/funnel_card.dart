import 'package:hrms_demo/core/theme/app_colors.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/statistics/widgets/stat_widgets.dart';
import 'package:flutter/material.dart';

/// [label] is display-ready — the caller localizes the raw stage key.
typedef FunnelDatum = ({String label, int count});

/// An ordered approval funnel. Each stage is a centered bar whose width is
/// proportional to the top stage, with the count and conversion-from-top %.
/// Ordinal ramp (blue, light→dark) carries stage order — validated to stay ≥2:1
/// on the light surface (starts no lighter than sequential step 250).
class FunnelCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<FunnelDatum> stages;
  final double? width;

  const FunnelCard({super.key, required this.title, required this.icon, required this.stages, this.width});

  // Ordinal ramp — steps 250..700 of the sequential blue (skip the two lightest
  // so every stage clears the 2:1 contrast floor).
  static const List<Color> _ramp = [
    Color(0xFF6DA7EC),
    Color(0xFF3987E5),
    Color(0xFF256ABF),
    Color(0xFF184F95),
    Color(0xFF0D366B),
  ];

  @override
  Widget build(BuildContext context) {
    final top = stages.isEmpty ? 0 : stages.first.count;
    return ChartCard(
      title: title,
      icon: icon,
      width: width,
      height: (stages.length * 52 + 30).clamp(160, 400).toDouble(),
      child:
          stages.isEmpty || top == 0
              ? ChartEmptyState(message: AppLocalizations.of(context)!.statsNoData)
              : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < stages.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 90,
                            child: Text(
                              stages[i].label,
                              style: const TextStyle(fontSize: 12, color: AppColors.inkSecondary),
                            ),
                          ),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, c) {
                                final frac = (stages[i].count / top).clamp(0.04, 1.0);
                                return Align(
                                  alignment: Alignment.center,
                                  child: Container(
                                    height: 30,
                                    width: c.maxWidth * frac,
                                    decoration: BoxDecoration(
                                      color: _ramp[i % _ramp.length],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${stages[i].count}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(
                            width: 46,
                            child: Text(
                              '${(stages[i].count / top * 100).toStringAsFixed(0)}%',
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontSize: 11, color: AppColors.inkMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
    );
  }
}
