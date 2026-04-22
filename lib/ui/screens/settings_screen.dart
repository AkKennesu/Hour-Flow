import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../logic/viewmodels/settings_viewmodel.dart';
import '../../logic/viewmodels/auth_viewmodel.dart';
import '../../utils/app_localizations.dart';

import 'profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = Provider.of<SettingsViewModel>(context);
    final auth = Provider.of<AuthViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('settings')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
            _buildProfileSection(theme, context, auth),
            const SizedBox(height: 32),
            _buildSectionHeader(theme, context.tr('preferences')),
            const SizedBox(height: 12),
            _buildPreferencesSection(theme, context, vm),
            const SizedBox(height: 32),
            _buildSectionHeader(theme, context.tr('notifications')),
            const SizedBox(height: 12),
            _buildNotificationsSection(theme, context, vm),
            const SizedBox(height: 48),
            _buildLogoutButton(theme, context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.3,
        ),
      ),
    );
  }

  Widget _buildProfileSection(ThemeData theme, BuildContext context, AuthViewModel auth) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primaryContainer,
                  image: auth.profileImageBase64 != null
                    ? DecorationImage(image: MemoryImage(base64Decode(auth.profileImageBase64!)), fit: BoxFit.cover)
                    : (auth.user?.photoURL != null 
                        ? DecorationImage(image: NetworkImage(auth.user!.photoURL!), fit: BoxFit.cover)
                        : null),
                ),
                child: (auth.profileImageBase64 == null && auth.user?.photoURL == null)
                  ? Icon(Icons.person_rounded, size: 36, color: theme.colorScheme.onPrimaryContainer)
                  : null,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.user?.displayName ?? 'Anonymous User', 
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        auth.userRole, 
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        )
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferencesSection(ThemeData theme, BuildContext context, SettingsViewModel vm) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.palette_rounded, color: theme.colorScheme.primary),
            title: const Text('App Appearance'),
            subtitle: Text(vm.themeMode == ThemeMode.system ? 'System' : (vm.themeMode == ThemeMode.light ? 'Light' : 'Dark')),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showThemePicker(context, vm),
          ),
          Divider(height: 1, indent: 56, endIndent: 16, color: theme.colorScheme.outlineVariant),
          ListTile(
            leading: Icon(Icons.language_rounded, color: theme.colorScheme.primary),
            title: Text(context.tr('language')),
            subtitle: Text(vm.selectedLanguage),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showLanguagePicker(context, vm),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection(ThemeData theme, BuildContext context, SettingsViewModel vm) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: Icon(Icons.notifications_active_rounded, color: theme.colorScheme.primary),
            title: Text(context.tr('push_notifications')),
            value: vm.pushNotifications,
            onChanged: (val) => vm.togglePushNotifications(val),
          ),
          Divider(height: 1, indent: 56, endIndent: 16, color: theme.colorScheme.outlineVariant),
          SwitchListTile(
            secondary: Icon(Icons.timer_rounded, color: theme.colorScheme.primary),
            title: Text(context.tr('daily_shift_reminders')),
            value: vm.shiftReminders,
            onChanged: (val) => vm.toggleShiftReminders(val),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(ThemeData theme, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilledButton.tonal(
        onPressed: () => context.read<AuthViewModel>().signOut(),
        style: FilledButton.styleFrom(
          backgroundColor: theme.colorScheme.errorContainer.withOpacity(0.4),
          foregroundColor: theme.colorScheme.error,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded),
            const SizedBox(width: 12),
            Text(context.tr('sign_out'), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, SettingsViewModel vm) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(context.tr('select_language'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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

  void _showThemePicker(BuildContext context, SettingsViewModel vm) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('App Appearance', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
              _buildThemeTile(context, vm, ThemeMode.system, 'System Default'),
              _buildThemeTile(context, vm, ThemeMode.light, 'Light Mode'),
              _buildThemeTile(context, vm, ThemeMode.dark, 'Dark Mode'),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeTile(BuildContext context, SettingsViewModel vm, ThemeMode mode, String label) {
    return ListTile(
      title: Text(label),
      trailing: vm.themeMode == mode ? Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary) : null,
      onTap: () {
        vm.setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildLangTile(BuildContext context, SettingsViewModel vm, String lang) {
    return ListTile(
      title: Text(lang),
      trailing: vm.selectedLanguage == lang ? Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary) : null,
      onTap: () {
        vm.setLanguage(lang);
        Navigator.pop(context);
      },
    );
  }
}
