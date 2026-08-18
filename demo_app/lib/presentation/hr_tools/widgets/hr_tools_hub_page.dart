import 'package:hrms_demo/core/theme/app_colors.dart';
import 'package:hrms_demo/core/utils/navigation_helper.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/hr_tools/widgets/hr_tools_page.dart';
import 'package:hrms_demo/presentation/org_structure/widgets/org_structure_page.dart';
import 'package:hrms_demo/presentation/widgets/main_layout.dart';
import 'package:flutter/material.dart';

/// Landing/routing page for HR Tools. The sidebar tile opens THIS page, which
/// then links onward to the two tools. Keeps each tool a standalone page while
/// giving HR one place to choose from.
class HrToolsHubPage extends StatelessWidget {
  const HrToolsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    String p(String en, String arabic) => ar ? arabic : en;

    return MainLayout(
      title: l10n.hrTools,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.hrTools, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                _ToolCard(
                  icon: Icons.event_available_outlined,
                  color: AppColors.cat1Blue,
                  title: p('Bulk Leaves & Overtime', 'الإجازات والعمل الإضافي بالجملة'),
                  subtitle: p(
                    'Submit leaves or overtime for many employees at once',
                    'تقديم إجازات أو عمل إضافي لعدة موظفين دفعة واحدة',
                  ),
                  onTap:
                      () => NavigationHelper.pushWithSidebarSync(
                        context,
                        routeName: '/hr/bulk-requests',
                        page: const HrToolsPage(),
                      ),
                ),
                _ToolCard(
                  icon: Icons.account_tree_outlined,
                  color: AppColors.cat5Violet,
                  title: p('Org Structure Builder', 'منشئ الهيكل التنظيمي'),
                  subtitle: p(
                    'Manage locations, departments and position charts',
                    'إدارة المواقع والإدارات ومخططات المناصب',
                  ),
                  onTap:
                      () => NavigationHelper.pushWithSidebarSync(
                        context,
                        routeName: '/hr/org-structure',
                        page: const OrgStructurePage(),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<_ToolCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _hover ? widget.color : Colors.grey.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: _hover ? 0.18 : 0.08),
                blurRadius: _hover ? 10 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 24),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward,
                    size: 18,
                    color: _hover ? widget.color : Colors.grey.withValues(alpha: 0.5),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.inkPrimary),
              ),
              const SizedBox(height: 6),
              Text(widget.subtitle, style: const TextStyle(fontSize: 13, color: AppColors.inkMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
