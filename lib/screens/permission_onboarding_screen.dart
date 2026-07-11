import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/tokens.dart';

class PermissionOnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const PermissionOnboardingScreen({super.key, required this.onComplete});

  @override
  State<PermissionOnboardingScreen> createState() =>
      _PermissionOnboardingScreenState();
}

class _PermissionOnboardingScreenState extends State<PermissionOnboardingScreen> {
  int _currentStep = 0;
  bool _isRequesting = false;

  // Permissions needed for the app to function
  final List<_PermissionItem> _permissions = [
    _PermissionItem(
      icon: Icons.mic,
      title: 'Microphone',
      description: 'Needed for voice commands and live calls',
      permission: Permission.microphone,
    ),
    _PermissionItem(
      icon: Icons.camera_alt,
      title: 'Camera',
      description: 'Needed for video calls and image capture',
      permission: Permission.camera,
    ),
    _PermissionItem(
      icon: Icons.storage,
      title: 'Storage',
      description: 'Needed to save documents and attach files',
      permission: Permission.storage,
    ),
    _PermissionItem(
      icon: Icons.notifications,
      title: 'Notifications',
      description: 'Needed for reminders and task alerts',
      permission: Permission.notification,
    ),
  ];

  List<bool> _granted = [];

  @override
  void initState() {
    super.initState();
    _granted = List.filled(_permissions.length, false);
    // Auto-start requesting the first permission
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestCurrentPermission();
    });
  }

  Future<void> _requestCurrentPermission() async {
    if (_currentStep >= _permissions.length) {
      // All permissions requested
      widget.onComplete();
      return;
    }

    setState(() => _isRequesting = true);

    final perm = _permissions[_currentStep];
    final status = await perm.permission.request();

    if (mounted) {
      setState(() {
        _granted[_currentStep] = status.isGranted;
        _isRequesting = false;
        _currentStep++;
      });

      // Small delay so the user sees the result, then request next
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        _requestCurrentPermission();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: AppColors.gradientIdle,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentViolet.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              const Text(
                'Welcome to AURA',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'We need a few permissions to get started',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 48),

              // Permission list with status
              ..._permissions.asMap().entries.map((entry) {
                final index = entry.key;
                final perm = entry.value;
                final isDone = index < _currentStep;
                final isCurrent = index == _currentStep;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppColors.surfaceRaised
                          : AppColors.surfaceBase,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrent
                            ? AppColors.accentViolet.withOpacity(0.5)
                            : AppColors.borderHairline,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isDone
                                ? AppColors.accentSuccess.withOpacity(0.15)
                                : AppColors.accentViolet.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isDone
                                ? Icons.check_circle
                                : isCurrent && _isRequesting
                                    ? Icons.hourglass_empty
                                    : perm.icon,
                            color: isDone
                                ? AppColors.accentSuccess
                                : AppColors.accentViolet,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                perm.title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                perm.description,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isDone)
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.accentSuccess,
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 32),

              // Progress indicator
              if (_currentStep < _permissions.length)
                Column(
                  children: [
                    Text(
                      'Setting up ${_currentStep + 1} of ${_permissions.length}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 200,
                      child: LinearProgressIndicator(
                        value: _currentStep / _permissions.length,
                        backgroundColor: AppColors.surfaceOverlay,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.accentViolet,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionItem {
  final IconData icon;
  final String title;
  final String description;
  final Permission permission;

  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.permission,
  });
}
