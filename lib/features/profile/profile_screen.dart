import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/messaging/messaging_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(fcmTokenProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const ListTile(title: Text('Goals'), subtitle: Text('Set your goals')),
        const ListTile(title: Text('Preferences'), subtitle: Text('Units, theme')),
        const ListTile(title: Text('Devices'), subtitle: Text('Connect wearables')),
        const ListTile(title: Text('Subscription'), subtitle: Text('Manage plan')),
        ListTile(
          title: const Text('Notifications'),
          subtitle: Text(token ?? 'Request permission and fetch token'),
          trailing: FilledButton(
            onPressed: () async {
              await MessagingService().requestAndGetToken(ref);
            },
            child: const Text('Enable'),
          ),
        ),
      ],
    );
  }
}