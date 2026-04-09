import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/glass_card.dart';
import '../../logic/viewmodels/settings_viewmodel.dart';
import '../../utils/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = Provider.of<SettingsViewModel>(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(context.tr('settings'), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildProfileSection(theme, context),
            const SizedBox(height: 24),
            _buildSectionHeader(theme, context.tr('preferences')),
            const SizedBox(height: 12),
            _buildPreferencesSection(theme, context, vm),
            const SizedBox(height: 24),
            _buildSectionHeader(theme, context.tr('notifications')),
            const SizedBox(height: 12),
            _buildNotificationsSection(theme, context, vm),
            const SizedBox(height: 32),
            _buildLogoutButton(theme, context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.secondary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildProfileSection(ThemeData theme, BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.3),
            child: Icon(Icons.person_outline, size: 36, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AkKennesu', 
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 4),
                Text(
                  'OJT Trainee', 
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white54)
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white70),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit Profile coming soon...')),
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildPreferencesSection(ThemeData theme, BuildContext context, SettingsViewModel vm) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined, color: Colors.white70),
            title: Text(context.tr('dark_theme')),
            trailing: Switch.adaptive(
              value: vm.isDarkMode,
              activeColor: theme.colorScheme.primary,
              onChanged: (val) => vm.toggleDarkMode(val),
            ),
          ),
          const Divider(height: 1, color: Colors.white12, indent: 56, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.language_outlined, color: Colors.white70),
            title: Text(context.tr('language')),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(vm.selectedLanguage, style: const TextStyle(color: Colors.white54)),
                const Icon(Icons.chevron_right, color: Colors.white54),
              ],
            ),
            onTap: () => _showLanguagePicker(context, vm),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection(ThemeData theme, BuildContext context, SettingsViewModel vm) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined, color: Colors.white70),
            title: Text(context.tr('push_notifications')),
            trailing: Switch.adaptive(
              value: vm.pushNotifications,
              activeColor: theme.colorScheme.primary,
              onChanged: (val) => vm.togglePushNotifications(val),
            ),
          ),
          const Divider(height: 1, color: Colors.white12, indent: 56, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.timer_outlined, color: Colors.white70),
            title: Text(context.tr('daily_shift_reminders')),
            trailing: Switch.adaptive(
              value: vm.shiftReminders,
              activeColor: theme.colorScheme.primary,
              onChanged: (val) => vm.toggleShiftReminders(val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(ThemeData theme, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: OutlinedButton.icon(
        icon: const Icon(Icons.logout, color: Colors.redAccent),
        label: Text(context.tr('sign_out'), style: const TextStyle(color: Colors.redAccent, fontSize: 16)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.redAccent, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Log out triggered!')),
          );
        },
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, SettingsViewModel vm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(context.tr('select_language'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              _buildLangTile(context, vm, 'English'),
              _buildLangTile(context, vm, 'Spanish'),
              _buildLangTile(context, vm, 'Filipino'),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLangTile(BuildContext context, SettingsViewModel vm, String lang) {
    return ListTile(
      title: Text(lang),
      trailing: vm.selectedLanguage == lang ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: () {
        vm.setLanguage(lang);
        Navigator.pop(context);
      },
    );
  }
}
