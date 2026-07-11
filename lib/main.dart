import 'dart:async';
import 'package:flutter/material.dart';
import 'services/simple_ai_service.dart';
import 'services/simple_ai_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/tokens.dart';
import 'theme/aura_theme.dart';
import 'theme/nova_theme.dart';
import 'services/auth_service.dart';
import 'services/memory_service.dart';
import 'services/task_service.dart';
import 'services/task_runner_service.dart';
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
import 'screens/permission_onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding_screen.dart';
import 'services/onboarding_service.dart';
import 'screens/splash_screen.dart';
import 'services/connected_services_service.dart';
import 'services/agent_team_service.dart';
import 'services/voice_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  try {
    await Firebase.initializeApp();
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
    runApp(const FirebaseInitErrorScreen());
    return; // Stop execution – do NOT rethrow
  }

  final prefs = await SharedPreferences.getInstance();
  final selectedModel = prefs.getString('selected_model');

  runApp(MyApp(selectedModel: selectedModel));
}

class FirebaseInitErrorScreen extends StatelessWidget {
  const FirebaseInitErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Failed to connect to Firebase.\n\n'
              'Check that google-services.json is placed in android/app/ and matches your app\'s package name.\n\n'
              'Restart the app after fixing the file.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final String? selectedModel;
  const MyApp({super.key, this.selectedModel});

  @override
  Widget build(BuildContext context) {
    debugPrint('Building MyApp...');
    return MultiProvider(
      providers: [
        Provider<SimpleAiService>(
          create: (_) => SimpleAiService(),
        ),
        ChangeNotifierProvider(create: (_) {
          debugPrint('Creating AuthService...');
          return AuthService();
        }),
        ChangeNotifierProvider(create: (_) => VoiceService()),
        ChangeNotifierProvider(create: (_) {
          debugPrint('Creating MemoryService...');
          return MemoryService();
        }),
        ChangeNotifierProvider(create: (_) {
          debugPrint('Creating TaskService...');
          return TaskService();
        }),
        ChangeNotifierProxyProvider2<SimpleAiService, BrowserService, TaskRunnerService>(
          create: (ctx) => TaskRunnerService(ctx.read<SimpleAiService>(), ctx.read<BrowserService>()),
          update: (ctx, ai, browser, previous) => previous ?? TaskRunnerService(ai, browser),
        ),
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
        title: 'AURA',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
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
  bool _permissionsDone = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = context.read<AuthService>();

    // Check if permissions were already granted in a previous session
    final prefs = await SharedPreferences.getInstance();
    final permsDone = prefs.getBool('permissions_onboarded') ?? false;

    if (mounted) {
      setState(() {
        _ready = true;
        _permissionsDone = permsDone;
      });
    }

    // Listen for auth state changes
    auth.authStateChanges().listen((_) {
      if (mounted) setState(() {});
    });
  }

  void _onPermissionsComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permissions_onboarded', true);
    if (mounted) {
      setState(() => _permissionsDone = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SplashScreen();

    final auth = context.watch<AuthService>();

    if (auth.user == null) return const LoginScreen();

    // Show permission onboarding first, then regular onboarding
    if (!_permissionsDone) {
      return PermissionOnboardingScreen(
        onComplete: _onPermissionsComplete,
      );
    }

    // Existing onboarding check
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

