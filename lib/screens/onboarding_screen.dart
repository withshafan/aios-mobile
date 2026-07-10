import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../services/onboarding_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      title: 'Welcome to AURA',
      description: 'Your AI Operating System',
      icon: Icons.auto_awesome,
      gradientColors: AppColors.gradientIdle,
    ),
    _OnboardingPage(
      title: 'Delegate & Automate',
      description: 'Let agents handle tasks while you focus on what matters',
      icon: Icons.smart_toy,
      gradientColors: AppColors.gradientActive,
    ),
    _OnboardingPage(
      title: 'Full Control',
      description: 'Approve actions, review audit logs, stay in command',
      icon: Icons.security,
      gradientColors: AppColors.gradientSuccess,
    ),
  ];

  void _completeOnboarding() async {
    await OnboardingService.setOnboardingComplete();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: _pages.map((page) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: page.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(page.icon, size: 100, color: Colors.white),
                    const SizedBox(height: space8),
                    Text(page.title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: space4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: space8),
                      child: Text(page.description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: Colors.white70)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Dots indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? Colors.white : Colors.white38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: space6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: space8),
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.accentViolet,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
                    ),
                    child: Text(_currentPage == _pages.length - 1 ? 'Get Started' : 'Continue'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;

  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientColors,
  });
}
