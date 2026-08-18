import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_state.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/schedule_constants.dart';
import 'package:flutter/material.dart';

class ScheduleLegend extends StatelessWidget {
  final ScheduleState state;

  const ScheduleLegend({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final filteredIds = state.filteredTeam.map((e) => e.id).whereType<int>().toSet();
    final liveCount =
        state.schedule.values.where((s) => !s.isLeave && s.isPublished && filteredIds.contains(s.employeeId)).length;

    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: SC.lineColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Items wrap to next line on narrow windows rather than overflowing
          Wrap(
            spacing: 0,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _LegendItem(color: SC.blue, label: l10n.scheduleLegendMorning),
              _LegendItem(color: SC.teal, label: l10n.scheduleLegendAfternoon),
              _LegendItem(color: SC.purple, label: l10n.scheduleLegendNight),
              _LegendItem(color: SC.orange, label: l10n.scheduleLegendOvernight),
              _LegendItem(color: SC.rose, label: l10n.scheduleLegendLeave),
              _LegendItem(color: SC.slate, label: l10n.scheduleOffTypeDayOff),
              if (state.viewMode != ScheduleViewMode.colleagues) ...[
                _LegendItem(color: SC.amber, label: l10n.scheduleLegendDraft, line: true),
                _LegendItem(color: SC.amber, label: l10n.scheduleLegendConflict, circle: true),
              ],
            ],
          ),
          Spacer(),
          if (state.viewMode != ScheduleViewMode.colleagues) _LivePulse(count: liveCount),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool line;
  final bool circle;

  const _LegendItem({required this.color, required this.label, this.line = false, this.circle = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (circle)
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle))
          else if (line)
            Container(color: Colors.orange, height: 2, width: 22)
          else
            Container(
              width: 22,
              height: 8,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.25),
                border: Border(left: BorderSide(color: color, width: 3)),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 11, color: SC.muted)),
        ],
      ),
    );
  }
}

class _LivePulse extends StatefulWidget {
  final int count;
  const _LivePulse({required this.count});

  @override
  State<_LivePulse> createState() => _LivePulseState();
}

class _LivePulseState extends State<_LivePulse> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _anim = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _anim,
          builder:
              (_, __) => Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: SC.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: SC.green.withValues(alpha: _anim.value * 0.6),
                      blurRadius: 6 + _anim.value * 6,
                      spreadRadius: _anim.value * 4,
                      blurStyle: BlurStyle.inner,
                    ),
                  ],
                ),
              ),
        ),
        const SizedBox(width: 5),
        Text(
          AppLocalizations.of(context)!.scheduleLegendPublished(widget.count),
          style: const TextStyle(fontSize: 11, color: SC.green, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// class _DashPainter extends CustomPainter {
//   final Color color;
//   _DashPainter(this.color);

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint =
//         Paint()
//           ..color = color
//           ..strokeWidth = 1.5
//           ..style = PaintingStyle.stroke;
//     const dashWidth = 4.0;
//     const dashSpace = 3.0;
//     double x = 0;
//     final y = size.height / 2;
//     while (x < size.width) {
//       canvas.drawLine(Offset(x, y), Offset(x + dashWidth, y), paint);
//       x += dashWidth + dashSpace;
//     }
//   }

//   @override
//   bool shouldRepaint(_DashPainter old) => old.color != color;
// }
