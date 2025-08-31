import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ListTile(title: Text('Goals'), subtitle: Text('Set your goals')),
        ListTile(title: Text('Preferences'), subtitle: Text('Units, theme')),
        ListTile(title: Text('Devices'), subtitle: Text('Connect wearables')),
        ListTile(title: Text('Subscription'), subtitle: Text('Manage plan')),
        ListTile(title: Text('Settings'), subtitle: Text('Notifications, privacy')),
      ],
    );
  }
}