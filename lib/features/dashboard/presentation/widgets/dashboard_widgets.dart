import 'package:flutter/material.dart';
import 'package:talex_platform/core/widgets/theme_toggle_button.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/constants/app_radii.dart';
import 'package:talex_platform/core/widgets/talex_logo.dart';
import 'package:talex_platform/core/widgets/talex_ui.dart';

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
    decoration: BoxDecoration(
      color: AppColors.bgAlt,
      border: Border(right: BorderSide(color: AppColors.border)),
    ),
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 26, 24, 30),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TalexLogo(width: 118, height: 34),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
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
          if (footerItems.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: TalexDivider(),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  for (final item in footerItems) _NavTile(item: item),
                ],
              ),
            ),
          ],
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
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Material(
      color: selected ? AppColors.surface2 : Colors.transparent,
      borderRadius: AppRadii.border,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.border,
        hoverColor: AppColors.surface,
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 3,
                height: selected ? 20 : 0,
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 11),
              Icon(
                item.icon,
                size: 20,
                color: selected ? AppColors.green : AppColors.textDimmer,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? AppColors.text : AppColors.textMuted,
                    fontSize: 14.5,
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
    height: 68,
    padding: const EdgeInsets.symmetric(horizontal: 24),
    decoration: BoxDecoration(
      color: AppColors.bg,
      border: Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: Row(
      children: [
        if (showMenu) ...[
          IconButton(onPressed: onMenu, icon: const Icon(Icons.menu)),
          const SizedBox(width: 4),
        ],
        Flexible(
          flex: 3,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SizedBox(
              height: 42,
              child: TextField(
                onSubmitted: onSearch,
                style: TextStyle(color: AppColors.text, fontSize: 14),
                decoration: InputDecoration(
                  hintText: searchHint,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border),
                    borderRadius: AppRadii.border,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
        const SizedBox(width: 16),
        ?trailing,
        const SizedBox(width: 10),
        const ThemeToggleButton(),
        const SizedBox(width: 2),
        IconButton(
          onPressed: onNotifications,
          icon: const Icon(Icons.notifications_none),
        ),
        // Botón de TaleXito oculto por ahora; descomentar para reactivarlo.
        // if (onAssistant != null) ...[
        //   const SizedBox(width: 6),
        //   Tooltip(
        //     message: assistantTooltip ?? '',
        //     child: TextButton.icon(
        //       onPressed: onAssistant,
        //       style: TextButton.styleFrom(
        //         foregroundColor: assistantOpen
        //             ? AppColors.green
        //             : AppColors.text,
        //         backgroundColor: assistantOpen
        //             ? AppColors.greenDim
        //             : AppColors.surface,
        //         side: BorderSide(
        //           color: assistantOpen
        //               ? AppColors.green.withValues(alpha: 0.4)
        //               : AppColors.border,
        //         ),
        //         padding: const EdgeInsets.symmetric(
        //           horizontal: 14,
        //           vertical: 12,
        //         ),
        //       ),
        //       icon: const TaleXitoMark(size: 20),
        //       label: Text(assistantLabel ?? 'TaleXito'),
        //     ),
        //   ),
        //   const SizedBox(width: 6),
        // ],
        PopupMenuButton<void>(
          tooltip: signOutLabel,
          offset: const Offset(0, 48),
          icon: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.blueDim,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderStrong),
            ),
            child: Icon(Icons.person, size: 18, color: AppColors.blue),
          ),
          itemBuilder: (_) => [
            PopupMenuItem(
              onTap: onSignOut,
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18, color: AppColors.textMuted),
                  const SizedBox(width: 10),
                  Text(signOutLabel),
                ],
              ),
            ),
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
    this.captionColor,
    this.tone = TalexTone.blue,
  });
  final String title, value, caption;
  final IconData icon;
  final Color? captionColor;
  final TalexTone tone;
  @override
  Widget build(BuildContext context) => TalexPanel(
    padding: const EdgeInsets.all(22),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 128),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TalexIconBadge(icon, tone: tone, size: 36),
            ],
          ),
          const SizedBox(height: 18),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 38,
                height: 1,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.6,
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
                color: (captionColor ?? AppColors.textMuted),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
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
  Widget build(BuildContext context) => TalexPanel(
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
          child: TalexSectionTitle(
            title,
            trailing: TextButton(onPressed: onViewAll, child: Text(viewAll)),
          ),
        ),
        const TalexDivider(),
        for (final (index, candidate) in candidates.indexed) ...[
          if (index > 0)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: TalexDivider(),
            ),
          InkWell(
            onTap: onCandidateTap == null
                ? null
                : () => onCandidateTap!(index),
            hoverColor: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.greenDim,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      candidate.initials,
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: Text(
                      candidate.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      candidate.assessment,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TalexPill(candidate.status),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.chevron_right, color: AppColors.textDimmer),
                ],
              ),
            ),
          ),
        ],
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
  Widget build(BuildContext context) => TalexPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
          child: TalexSectionTitle(title),
        ),
        const TalexDivider(),
        for (final action in actions)
          InkWell(
            onTap: action.onTap,
            hoverColor: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 18, 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TalexIconBadge(action.icon, size: 36),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          action.title,
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          action.subtitle,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13.5,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (action.onTap != null)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Icon(
                        Icons.chevron_right,
                        color: AppColors.textDimmer,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
