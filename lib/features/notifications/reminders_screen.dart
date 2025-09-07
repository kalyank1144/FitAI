import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});
  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  bool enabled = false;
  TimeOfDay time = const TimeOfDay(hour: 18, minute: 0);
  final plugin = FlutterLocalNotificationsPlugin();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: ListView(
        children: [
          SwitchListTile(
            value: enabled,
            onChanged: (v) async {
              setState(() => enabled = v);
              if (v) {
                await schedule();
              } else {
                await plugin.cancelAll();
              }
            },
            title: const Text('Daily workout reminder'),
          ),
          ListTile(
            title: const Text('Time'),
            subtitle: Text(time.format(context)),
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: time);
              if (picked != null) setState(() => time = picked);
              if (enabled) await schedule();
            },
          ),
        ],
      ),
    );
  }

  Future<void> schedule() async {
    final details = const NotificationDetails(
      android: AndroidNotificationDetails('reminders', 'Reminders', importance: Importance.high),
      iOS: DarwinNotificationDetails(),
    );
    final now = TimeOfDay.now();
    final scheduleTime = DateTime.now().copyWith(hour: time.hour, minute: time.minute, second: 0).add(
      Duration(days: (time.hour < now.hour || (time.hour == now.hour && time.minute <= now.minute)) ? 1 : 0),
    );
    await plugin.zonedSchedule(
      1001,
      'Workout time',
      "Let's keep the streak!",
      scheduleTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}