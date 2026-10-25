import 'package:flutter/material.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/constants/app_radii.dart';
import 'package:talex_platform/core/widgets/talex_logo.dart';

class DashboardNavItem {
  const DashboardNavItem(this.label, this.icon);
  final String label;
  final IconData icon;
}

class DashboardSidebar extends StatelessWidget {
  const DashboardSidebar({
    super.key,
    required this.items,
    required this.footerItems,
    this.selectedIndex = 0,
    this.onSelected,
    this.width = 256,
  });
  final List<DashboardNavItem> items, footerItems;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;
  final double width;
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    color: AppColors.sidebarBackground,
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 14, bottom: 8),
            child: TalexLogo(width: 190, height: 58),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ...items.indexed.map(
                  (entry) => _NavTile(
                    item: entry.$2,
                    selected: entry.$1 == selectedIndex,
                    onTap: () => onSelected?.call(entry.$1),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.softBorder),
          ...footerItems.map((item) => _NavTile(item: item)),
          const SizedBox(height: 18),
        ],
      ),
    ),
  );
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.item, this.selected = false, this.onTap});
  final DashboardNavItem item;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
    child: Material(
      color: selected ? const Color(0xFFEAE8EB) : Colors.transparent,
      borderRadius: AppRadii.border,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.border,
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            border: selected
                ? const Border(
                    left: BorderSide(
                      color: AppColors.dashboardAccent,
                      width: 2,
                    ),
                  )
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 21,
                color: selected
                    ? AppColors.dashboardAccent
                    : AppColors.subtitle,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: selected ? AppColors.ink : AppColors.subtitle,
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class DashboardTopBar extends StatelessWidget {
  const DashboardTopBar({
    super.key,
    required this.searchHint,
    required this.signOutLabel,
    this.onMenu,
    this.onSignOut,
    this.onSearch,
    this.onNotifications,
    this.onAssistant,
    this.assistantTooltip,
    this.assistantLabel,
    this.assistantOpen = false,
    this.trailing,
    this.showMenu = false,
  });
  final String searchHint, signOutLabel;
  final String? assistantTooltip, assistantLabel;
  final VoidCallback? onMenu, onSignOut, onNotifications, onAssistant;
  final bool assistantOpen;
  final ValueChanged<String>? onSearch;
  final Widget? trailing;
  final bool showMenu;
  @override
  Widget build(BuildContext context) => Container(
    height: 64,
    padding: const EdgeInsets.symmetric(horizontal: 24),
    decoration: const BoxDecoration(
      color: AppColors.background,
      border: Border(bottom: BorderSide(color: AppColors.softBorder)),
    ),
    child: Row(
      children: [
        if (showMenu)
          IconButton(onPressed: onMenu, icon: const Icon(Icons.menu)),
        Expanded(
          child: TextField(
            onSubmitted: onSearch,
            decoration: InputDecoration(
              hintText: searchHint,
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFFF4F2F3),
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: AppRadii.border,
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(width: 16),
        ?trailing,
        IconButton(
          onPressed: onNotifications,
          icon: const Icon(Icons.notifications_none),
        ),
        if (onAssistant != null) ...[
          const SizedBox(width: 8),
          Tooltip(
            message: assistantTooltip ?? '',
            child: TextButton.icon(
              onPressed: onAssistant,
              style: TextButton.styleFrom(
                foregroundColor: assistantOpen
                    ? AppColors.brandBlue
                    : AppColors.ink,
                backgroundColor: assistantOpen
                    ? AppColors.brandBlue.withValues(alpha: 0.1)
                    : const Color(0xFFF4F2F3),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              icon: const TaleXitoMark(size: 22),
              label: Text(assistantLabel ?? 'TaleXito'),
            ),
          ),
        ],
        IconButton(onPressed: () {}, icon: const Icon(Icons.help_outline)),
        PopupMenuButton<void>(
          icon: const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFD7DEE5),
            child: Icon(Icons.person, size: 18, color: AppColors.ink),
          ),
          itemBuilder: (_) => [
            PopupMenuItem(onTap: onSignOut, child: Text(signOutLabel)),
          ],
        ),
      ],
    ),
  );
}

class DashboardMetricCard extends StatelessWidget {
  const DashboardMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    this.captionColor = AppColors.subtitle,
  });
  final String title, value, caption;
  final IconData icon;
  final Color captionColor;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 148),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFC9CBD1)),
      borderRadius: AppRadii.border,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.subtitle,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(icon, color: AppColors.muted, size: 20),
          ],
        ),
        const SizedBox(height: 12),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 36,
              height: 1,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.2,
            ),
          ),
        ),
        if (caption.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: captionColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    ),
  );
}

class CandidateMatch {
  const CandidateMatch(this.initials, this.name, this.assessment, this.status);
  final String initials, name, assessment, status;
}

class TopMatchesCard extends StatelessWidget {
  const TopMatchesCard({
    super.key,
    required this.title,
    required this.viewAll,
    required this.candidates,
    this.onViewAll,
    this.onCandidateTap,
  });
  final String title, viewAll;
  final List<CandidateMatch> candidates;
  final VoidCallback? onViewAll;
  final ValueChanged<int>? onCandidateTap;
  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(onPressed: onViewAll, child: Text(viewAll)),
            ],
          ),
        ),
        const Divider(height: 1),
        ...candidates.asMap().entries.map(
          (entry) => Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onCandidateTap == null
                  ? null
                  : () => onCandidateTap!(entry.key),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF0EEF0))),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E3E5),
                        borderRadius: AppRadii.border,
                      ),
                      child: Text(entry.value.initials),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Text(
                        entry.value.name,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        entry.value.assessment,
                        style: const TextStyle(color: AppColors.subtitle),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0EFFF),
                            borderRadius: AppRadii.border,
                          ),
                          child: Text(
                            entry.value.status,
                            style: const TextStyle(
                              color: AppColors.dashboardAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Icon(Icons.chevron_right, color: AppColors.accent),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class PendingActionItem {
  const PendingActionItem(this.title, this.subtitle, this.icon, {this.onTap});
  final String title, subtitle;
  final IconData icon;
  final VoidCallback? onTap;
}

class PendingActionsCard extends StatelessWidget {
  const PendingActionsCard({
    super.key,
    required this.title,
    required this.actions,
  });
  final String title;
  final List<PendingActionItem> actions;
  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Divider(height: 1),
        ...actions.map(
          (action) => InkWell(
            onTap: action.onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 20, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(action.icon, color: AppColors.accent, size: 20),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          action.title,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          action.subtitle,
                          style: const TextStyle(
                            color: AppColors.subtitle,
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (action.onTap != null)
                    const Icon(Icons.chevron_right, color: AppColors.accent),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFC9CBD1)),
      borderRadius: AppRadii.border,
    ),
    child: child,
  );
}
