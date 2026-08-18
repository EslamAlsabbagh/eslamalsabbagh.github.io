import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/schedule_constants.dart';
import 'package:flutter/material.dart';

/// Employee avatar circle that renders initials with a deterministic colour.
class MobileAvatar extends StatelessWidget {
  final UserModel employee;
  final double size;
  final bool ring; // green ring for live "on shift"

  const MobileAvatar({super.key, required this.employee, this.size = 36, this.ring = false});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final idx = (employee.id ?? 0) % 9;
    final color = SC.avatarColor(idx);
    final nickname = employee.getLocalizedNickname(locale) ?? employee.getLocalizedName(locale);
    final initials = SC.avatarInitials(nickname.isNotEmpty ? nickname : '?');

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(initials, style: TextStyle(color: Colors.white, fontSize: size * 0.38, fontWeight: FontWeight.w700)),
    );

    if (ring) {
      avatar = Container(
        width: size + 4,
        height: size + 4,
        decoration: const BoxDecoration(color: Color(0xFF1EB476), shape: BoxShape.circle),
        padding: const EdgeInsets.all(2),
        child: avatar,
      );
    }

    return avatar;
  }
}
