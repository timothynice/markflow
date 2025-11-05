import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../routes/go_router_config.dart';
import '../theme.dart';

class ResponsiveNav extends StatelessWidget {
  const ResponsiveNav({super.key, this.showMenuButton = true});

  // Controls whether the three-line hamburger menu is shown on mobile/tablet
  final bool showMenuButton;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= Breakpoints.lg;
        final isTablet = constraints.maxWidth >= Breakpoints.md;

        return Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Logo/Brand
              _buildLogo(context),

              if (isDesktop) ...[
                const SizedBox(width: 32),
                // Desktop Navigation Items
                _buildDesktopNavItems(context),
                const Spacer(),
                // Desktop Actions
                _buildDesktopActions(context),
              ] else if (isTablet) ...[
                const Spacer(),
                // Hamburger Menu for tablet
                if (showMenuButton) _buildMobileMenuButton(context),
              ] else ...[
                const Spacer(),
                // Mobile Actions
                _buildMobileActions(context),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogo(BuildContext context) {
    return InkWell(
      onTap: () {
        // Navigate to home when logo is clicked
        context.go(AppRoutes.home);
      },
      borderRadius: BorderRadius.circular(6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.light
                  ? LightModeColors.brandIcon
                  : DarkModeColors.brandIcon,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: Text(
                '///',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Markflow',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopNavItems(BuildContext context) {
    // Desktop nav items removed - using split view layout instead
    return const SizedBox.shrink();
  }

  Widget _buildNavItem(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: InkWell(
        onTap: () {
          // Handle navigation
          _handleNavigation(context, title);
        },
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(
                context,
              ).textTheme.bodyLarge?.color?.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopActions(BuildContext context) {
    return Row(children: [
      _buildIconButton(
        context,
        Icons.settings,
        'Settings',
        () => context.go(AppRoutes.settings),
      ),
    ]);
  }

  Widget _buildMobileActions(BuildContext context) {
    return Row(children: [
      _buildIconButton(context, Icons.settings, null, () => context.go(AppRoutes.settings)),
      if (showMenuButton) ...[
        const SizedBox(width: 8),
        _buildMobileMenuButton(context),
      ],
    ]);
  }

  Widget _buildMobileMenuButton(BuildContext context) {
    return IconButton(
      onPressed: () {
        // Open the app drawer on mobile/tablet
        final scaffoldState = Scaffold.maybeOf(context);
        if (scaffoldState != null) {
          scaffoldState.openDrawer();
        }
      },
      icon: const Icon(Icons.menu, size: 20),
    );
  }

  Widget _buildIconButton(
    BuildContext context,
    IconData icon,
    String? label,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, String title) {
    // Navigation handler (currently unused in desktop split view)
  }

}
