import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys used to persist quiet-hours settings in [SharedPreferences].
abstract final class QuietHoursPrefs {
  /// Whether quiet hours are enabled.
  static const String enabled = 'quiet_hours_enabled';

  /// Start time as minutes since midnight (default 22:00 → 1320).
  static const String start = 'quiet_hours_start';

  /// End time as minutes since midnight (default 07:00 → 420).
  static const String end = 'quiet_hours_end';
}

/// Settings screen for configuring notification quiet hours.
///
/// Route: `/settings/notifications`
class NotificationSettingsScreen extends StatefulWidget {
  /// Creates a [NotificationSettingsScreen].
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _quietEnabled = false;

  /// Start time as minutes since midnight (default 22:00).
  int _startMinutes = 1320;

  /// End time as minutes since midnight (default 07:00).
  int _endMinutes = 420;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _quietEnabled = prefs.getBool(QuietHoursPrefs.enabled) ?? false;
      _startMinutes = prefs.getInt(QuietHoursPrefs.start) ?? 1320;
      _endMinutes = prefs.getInt(QuietHoursPrefs.end) ?? 420;
      _isLoading = false;
    });
  }

  Future<void> _setEnabled(bool value) async {
    setState(() => _quietEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(QuietHoursPrefs.enabled, value);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _minutesToTimeOfDay(_startMinutes),
      helpText: 'Quiet hours start',
    );
    if (picked == null || !mounted) return;
    final minutes = picked.hour * 60 + picked.minute;
    setState(() => _startMinutes = minutes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(QuietHoursPrefs.start, minutes);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _minutesToTimeOfDay(_endMinutes),
      helpText: 'Quiet hours end',
    );
    if (picked == null || !mounted) return;
    final minutes = picked.hour * 60 + picked.minute;
    setState(() => _endMinutes = minutes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(QuietHoursPrefs.end, minutes);
  }

  static TimeOfDay _minutesToTimeOfDay(int minutes) {
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  static String _formatMinutes(int minutes) {
    final tod = _minutesToTimeOfDay(minutes);
    final h = tod.hour.toString().padLeft(2, '0');
    final m = tod.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: ListView(
        children: [
          // ----------------------------------------------------------------
          // Quiet hours toggle
          // ----------------------------------------------------------------
          SwitchListTile(
            title: const Text('Enable quiet hours'),
            subtitle: const Text(
              'Suppress location reminders during a scheduled window',
            ),
            value: _quietEnabled,
            onChanged: _setEnabled,
          ),

          const Divider(),

          // ----------------------------------------------------------------
          // Start / End time pickers (only interactive when enabled)
          // ----------------------------------------------------------------
          ListTile(
            enabled: _quietEnabled,
            leading: const Icon(Icons.bedtime_outlined),
            title: const Text('Start time'),
            subtitle: const Text('Notifications suppressed after this time'),
            trailing: Text(
              _formatMinutes(_startMinutes),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: _quietEnabled
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.38),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            onTap: _quietEnabled ? _pickStartTime : null,
          ),
          ListTile(
            enabled: _quietEnabled,
            leading: const Icon(Icons.wb_sunny_outlined),
            title: const Text('End time'),
            subtitle: const Text('Notifications resume after this time'),
            trailing: Text(
              _formatMinutes(_endMinutes),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: _quietEnabled
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.38),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            onTap: _quietEnabled ? _pickEndTime : null,
          ),

          // ----------------------------------------------------------------
          // Informational note about overnight ranges
          // ----------------------------------------------------------------
          if (_quietEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(
                _startMinutes > _endMinutes
                    ? 'Quiet hours wrap overnight: '
                        '${_formatMinutes(_startMinutes)} → '
                        '${_formatMinutes(_endMinutes)} (next day).'
                    : 'Quiet hours: ${_formatMinutes(_startMinutes)} → '
                        '${_formatMinutes(_endMinutes)}.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
