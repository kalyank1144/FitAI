import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'data/profile_repository.dart';
import 'profile_edit_screen.dart';
import 'account_settings_screen.dart';
import 'preferences_screen.dart';
import 'progress_tracking_screen.dart';
import 'data_management_screen.dart';
import '../auth/data/auth_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _getGoalDisplayText(String? goal) {
    switch (goal) {
      case 'lose':
        return 'Lose Weight';
      case 'maintain':
        return 'Maintain';
      case 'gain':
        return 'Gain Weight';
      case 'muscle':
        return 'Build Muscle';
      case 'endurance':
        return 'Endurance';
      default:
        return 'Not Set';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRepo = ref.watch(authRepositoryProvider);
    final profileState = ref.watch(profileStreamProvider);
    final currentUser = authRepo.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: currentUser != null
          ? _buildProfileContent(context, profileState, ref)
          : _buildNotLoggedInState(context),
    );
  }

  Widget _buildProfileContent(BuildContext context, AsyncValue<UserProfile?> profileState, WidgetRef ref) {
    return profileState.when(
      data: (profile) => profile != null
          ? _buildProfileData(context, profile, ref)
          : _buildNoProfileState(context),
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(context, 'Error loading profile: ${error.toString()}', ref),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading profile...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error, [WidgetRef? ref]) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.alertCircle,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: ref != null ? () {
                ref.invalidate(profileStreamProvider);
                ref.invalidate(authRepositoryProvider);
              } : null,
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotLoggedInState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.userX,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Not Logged In',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please log in to view your profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoProfileState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.user,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Profile Data',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete your profile to get started',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileEditScreen(),
                  ),
                );
              },
              icon: const Icon(LucideIcons.userPlus),
              label: const Text('Create Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileData(BuildContext context, UserProfile profile, WidgetRef ref) {
    return ListView(
      children: [
        // Profile Header Card
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ProfileEditScreen(),
                      ),
                    );
                  },
                  child: Stack(
                    children: [
                       CircleAvatar(
                         radius: 40,
                         backgroundColor: Colors.grey[300],
                         backgroundImage: profile.avatarUrl != null
                             ? CachedNetworkImageProvider(profile.avatarUrl!)
                             : null,
                         child: profile.avatarUrl == null
                             ? const Icon(
                                 LucideIcons.user,
                                 size: 32,
                               )
                             : null,
                       ),
                       Positioned(
                         bottom: 0,
                         right: 0,
                         child: Container(
                           padding: const EdgeInsets.all(4),
                           decoration: BoxDecoration(
                             color: Theme.of(context).primaryColor,
                             shape: BoxShape.circle,
                           ),
                           child: const Icon(
                             LucideIcons.edit2,
                             size: 12,
                             color: Colors.white,
                           ),
                         ),
                       ),
                     ],
                   ),
                 ),
                 const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ProfileEditScreen(),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Text(
                        profile.fullName ?? 'Tap to set name',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        profile.gender ?? 'Not specified',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      if (profile.bio != null && profile.bio!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            profile.bio!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(
                    icon: LucideIcons.scale,
                    label: 'Weight',
                    value: profile.weight != null ? '${profile.weight} kg' : '--',
                  ),
                  _StatItem(
                    icon: LucideIcons.ruler,
                    label: 'Height',
                    value: profile.height != null ? '${profile.height} cm' : '--',
                  ),
                  _StatItem(
                    icon: LucideIcons.target,
                    label: 'Goal',
                    value: _getGoalDisplayText(profile.fitnessGoal),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
        const SizedBox(height: 16),
        
        // List Items
        ListTile(
          leading: const Icon(LucideIcons.target),
          title: const Text('Progress Tracking'),
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ProgressTrackingScreen(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(LucideIcons.settings),
          title: const Text('Preferences'),
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const PreferencesScreen(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(LucideIcons.database),
          title: const Text('Data Management'),
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const DataManagementScreen(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(LucideIcons.creditCard),
          title: const Text('Subscription'),
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: () {
            // Navigate to subscription screen
          },
        ),
        ListTile(
          leading: const Icon(LucideIcons.userCog),
          title: const Text('Account Settings'),
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AccountSettingsScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        
        // Sign Out Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton(
            onPressed: () async {
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
                try {
                  await ref.read(authRepositoryProvider).signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/signin');
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to sign out: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
