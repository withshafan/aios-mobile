import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'theme/tokens.dart';
import 'theme/aura_theme.dart';
import 'services/auth_service.dart';
import 'services/memory_service.dart';
import 'services/task_service.dart';
import 'services/document_service.dart';
import 'services/plugin_service.dart';
import 'services/workflow_service.dart';
import 'services/browser_service.dart';
import 'services/analytics_service.dart';
import 'services/approval_service.dart';
import 'services/cognitive_state_service.dart';
import 'services/life_timeline_service.dart';
import 'services/attention_service.dart';
import 'services/circuit_breaker_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/onboarding_service.dart';
import 'screens/splash_screen.dart';
import 'services/connected_services_service.dart';
import 'services/agent_team_service.dart';

void main() async {
  debugPrint('===== START main() =====');
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('Binding ensured.');

  try {
    debugPrint('Calling Firebase.initializeApp()...');
    await Firebase.initializeApp();
    debugPrint('Firebase initialized successfully.');
  } catch (e, stack) {
    debugPrint('Firebase init FAILED: $e\n$stack');
    // Continue anyway? Or rethrow? For now, rethrow.
    rethrow;
  }

  debugPrint('Setting up providers...');
  runApp(const MyApp());
  debugPrint('runApp() called.');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('Building MyApp...');
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          debugPrint('Creating AuthService...');
          return AuthService();
        }),
        ChangeNotifierProvider(create: (_) {
          debugPrint('Creating MemoryService...');
          return MemoryService();
        }),
        ChangeNotifierProvider(create: (_) {
          debugPrint('Creating TaskService...');
          return TaskService();
        }),
        ChangeNotifierProxyProvider<TaskService, WorkflowService>(
          create: (ctx) {
            debugPrint('Creating WorkflowService...');
            return WorkflowService(ctx.read<TaskService>());
          },
          update: (ctx, taskService, previous) {
            return previous ?? WorkflowService(taskService);
          },
        ),
        ChangeNotifierProvider(create: (_) {
          debugPrint('Creating DocumentService...');
          return DocumentService();
        }),
        ChangeNotifierProvider(create: (_) {
          debugPrint('Creating PluginService...');
          return PluginService();
        }),
        ChangeNotifierProvider(create: (_) {
          debugPrint('Creating BrowserService...');
          return BrowserService();
        }),
        ChangeNotifierProvider(create: (_) {
          debugPrint('Creating AnalyticsService...');
          return AnalyticsService();
        }),
        ChangeNotifierProvider(create: (_) {
          debugPrint('Creating ApprovalService...');
          return ApprovalService();
        }),
        ChangeNotifierProvider(create: (_) {
          debugPrint('Creating CognitiveStateService...');
          return CognitiveStateService();
        }),
        ChangeNotifierProvider(create: (_) {
          debugPrint('Creating LifeTimelineService...');
          return LifeTimelineService();
        }),
        ChangeNotifierProvider(create: (_) {
          debugPrint('Creating AttentionService...');
          return AttentionService();
        }),
        ChangeNotifierProvider(create: (_) {
          debugPrint('Creating CircuitBreakerService...');
          return CircuitBreakerService();
        }),
        Provider(create: (_) {
          debugPrint('Creating ConnectedServicesService...');
          return ConnectedServicesService();
        }),
        Provider(create: (_) {
          debugPrint('Creating AgentTeamService...');
          return AgentTeamService();
        }),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'AURA AIOS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.bgCanvas,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accentViolet,
            secondary: AppColors.accentCyan,
            surface: AppColors.surfaceBase,
            error: AppColors.accentCritical,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.surfaceBase,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
          ),
          extensions: [AuraTheme.dark()],
        ),
        home: const AuthGate(),
      ),
    );
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _ready = false;
  late StreamSubscription<User?> _authSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = context.read<AuthService>();
    _authSub = auth.authStateChanges().listen((_) {
      if (mounted) setState(() => _ready = true);
      _authSub.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const SplashScreen();
    }
    final auth = context.watch<AuthService>();
    if (auth.user == null) {
      return const LoginScreen();
    }
    return FutureBuilder<bool>(
      future: OnboardingService.isOnboardingComplete(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snap.data == false) {
          return const OnboardingScreen();
        }
        // Seed services after frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            context.read<ApprovalService>().seedDefaults();
            context.read<ConnectedServicesService>().seedDefaults();
            context.read<AgentTeamService>().seedTeam();
          } catch (e) {
            debugPrint('Seed error: $e');
          }
        });
        return const HomeScreen();
      },
    );
  }
}
