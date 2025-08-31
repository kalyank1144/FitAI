import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});
  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int index = 0;
  final pages = const [
    _ObPage(title: 'Goals', subtitle: 'Get stronger, leaner, healthier'),
    _ObPage(title: 'Experience', subtitle: 'Beginner, Intermediate, Advanced'),
    _ObPage(title: 'Equipment', subtitle: 'Home, Gym, Mixed'),
    _ObPage(title: 'Schedule', subtitle: 'Choose your days'),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(child: pages[index]),
              Row(
                children: [
                  TextButton(onPressed: () => context.go('/'), child: const Text('Skip')),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      if (index < pages.length - 1) {
                        setState(() => index++);
                      } else {
                        context.go('/');
                      }
                    },
                    child: Text(index == pages.length - 1 ? 'Start' : 'Next'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Health Connect + Paywall preview later')
            ],
          ),
        ),
      ),
    );
  }
}

class _ObPage extends StatelessWidget {
  const _ObPage({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 8),
        Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
        const Spacer(),
        const Placeholder(fallbackHeight: 200),
      ],
    );
  }
}