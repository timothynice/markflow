import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme_controller.dart';
import '../theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ThemeController.instance;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isLight ? LightModeColors.appBar : DarkModeColors.appBar,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
          tooltip: 'Back',
        ),
        title: const Text('Settings'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Appearance',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: controller.mode,
                  builder: (context, mode, _) {
                    // If system mode, determine actual brightness from context
                    final effectiveBrightness = mode == ThemeMode.system
                        ? MediaQuery.platformBrightnessOf(context)
                        : (mode == ThemeMode.dark ? Brightness.dark : Brightness.light);
                    final isDark = effectiveBrightness == Brightness.dark;
                    return SwitchListTile.adaptive(
                      value: isDark,
                      onChanged: (v) => v ? controller.setDark() : controller.setLight(),
                      // Show only the dynamic text (Dark/Light) and remove the static label
                      title: Text(isDark ? 'Dark' : 'Light'),
                      contentPadding: EdgeInsets.zero,
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'More settings coming soon',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
