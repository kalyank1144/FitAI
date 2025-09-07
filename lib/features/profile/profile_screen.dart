import 'package:fitai/core/messaging/messaging_service.dart';
import 'package:fitai/features/activity/data/activity_repository.dart';
import 'package:fitai/features/auth/data/auth_repository.dart';
import 'package:fitai/features/profile/data/profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(fcmTokenProvider);
    final authRepo = ref.read(authRepositoryProvider);
    final profile = ref.watch(profileStreamProvider);
    final activityToday = ref.watch(activityTodayProvider);
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profile Header Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
          ),
          child: profile.when(
            loading: () => const Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  child: CircularProgressIndicator(),
                ),
                SizedBox(height: 12),
                Text('Loading profile...'),
              ],
            ),
            error: (e, _) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Icon(Icons.error_outline, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Profile Error',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Failed to load profile: $e',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            data: (profileData) => Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: profileData?['avatar_url'] != null 
                    ? NetworkImage(profileData!['avatar_url']) 
                    : null,
                  child: profileData?['avatar_url'] == null 
                    ? const Icon(Icons.person, size: 40) 
                    : null,
                ),
                const SizedBox(height: 12),
                Text(
                  profileData?['full_name'] ?? authRepo.currentUser?.email?.split('@').first ?? 'User',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  authRepo.currentUser?.email ?? '',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                const SizedBox(height: 16),
                // Today's Stats
                activityToday.when(
                  loading: () => const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(label: 'Steps', value: '---', icon: Icons.directions_walk),
                      _StatItem(label: 'Calories', value: '---', icon: Icons.local_fire_department),
                      _StatItem(label: 'Distance', value: '---', icon: Icons.route),
                    ],
                  ),
                  error: (e, _) => const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(label: 'Steps', value: 'Error', icon: Icons.directions_walk),
                      _StatItem(label: 'Calories', value: 'Error', icon: Icons.local_fire_department),
                      _StatItem(label: 'Distance', value: 'Error', icon: Icons.route),
                    ],
                  ),
                  data: (activity) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        label: 'Steps', 
                        value: activity?.steps?.toString() ?? '0', 
                        icon: Icons.directions_walk,
                      ),
                      _StatItem(
                        label: 'Calories', 
                        value: activity?.calories?.toInt().toString() ?? '0', 
                        icon: Icons.local_fire_department,
                      ),
                      _StatItem(
                        label: 'Distance', 
                        value: '0.0 km', 
                        icon: Icons.route,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(),
        const ListTile(title: Text('Goals'), subtitle: Text('Set your goals')),
        const ListTile(title: Text('Preferences'), subtitle: Text('Units, theme')),
        const ListTile(title: Text('Devices'), subtitle: Text('Connect wearables')),
        const ListTile(title: Text('Subscription'), subtitle: Text('Manage plan')),
        ListTile(
          title: const Text('Notifications'),
          subtitle: Text(token ?? 'Request permission and fetch token'),
          trailing: FilledButton(
            onPressed: () async {
              final t = await MessagingService().requestAndGetToken(ref);
              if (t != null) {
                await saveFcmToken(t);
              }
            },
            child: const Text('Enable'),
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          onTap: () async {
            final shouldSignOut = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Sign Out'),
                content: const Text('Are you sure you want to sign out?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            );
            
            if (shouldSignOut == true) {
              await authRepo.signOut();
            }
          },
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: Colors.blue,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }
}