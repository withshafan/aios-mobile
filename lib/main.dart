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
import 'services/system_prompt_service.dart';
import 'services/planner_service.dart';
import 'services/goal_service.dart';

import 'services/cognitive_state_service.dart';
import 'services/world_model_service.dart';
import 'services/life_timeline_service.dart';
import 'services/attention_service.dart';
import 'services/strategic_mission_service.dart';
import 'services/curiosity_service.dart';
import 'services/opportunity_service.dart';
import 'services/coach_service.dart';
import 'services/emotional_service.dart';
import 'services/trust_service.dart';
import 'services/reality_verification_service.dart';
import 'services/maintenance_service.dart';
import 'services/connected_services_service.dart';
import 'services/multi_llm_service.dart';
import 'services/agent_team_service.dart';
import 'services/self_programming_service.dart';
import 'services/audit_service.dart';
import 'services/circuit_breaker_service.dart';
import 'services/webhook_service.dart';
import 'services/collaboration_service.dart';
import 'services/audit_service.dart';
import 'services/circuit_breaker_service.dart';
import 'services/webhook_service.dart';
import 'services/collaboration_service.dart';
import 'services/task_runner_service.dart';
import 'services/gemini_service.dart';

import 'screens/chat_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/onboarding_service.dart';
import 'services/approval_service.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => MemoryService()),
        ChangeNotifierProvider(create: (_) => TaskService()),
        ChangeNotifierProxyProvider<TaskService, WorkflowService>(
          create: (ctx) => WorkflowService(ctx.read<TaskService>()),
          update: (ctx, taskService, previous) => previous ?? WorkflowService(taskService),
        ),
        ChangeNotifierProvider(create: (_) => DocumentService()),
        ChangeNotifierProvider(create: (_) => PluginService()),
        ChangeNotifierProvider(create: (_) => BrowserService()),
        ChangeNotifierProvider(create: (_) => AnalyticsService()),
        ChangeNotifierProvider(create: (_) => SystemPromptService()),
        ChangeNotifierProvider(create: (_) => PlannerService()),
        ChangeNotifierProvider(create: (_) => GoalService()),
        Provider<CognitiveStateService>(create: (_) => CognitiveStateService()),
        Provider<WorldModelService>(create: (_) => WorldModelService()),
        Provider<LifeTimelineService>(create: (_) => LifeTimelineService()),
        Provider<AttentionService>(create: (_) => AttentionService()),
        Provider<StrategicMissionService>(create: (_) => StrategicMissionService()),
        Provider<CuriosityService>(create: (_) => CuriosityService()),
        Provider<OpportunityService>(create: (_) => OpportunityService()),
        Provider<CoachService>(create: (_) => CoachService()),
        Provider<EmotionalService>(create: (_) => EmotionalService()),
        Provider<TrustService>(create: (_) => TrustService()),
        Provider<RealityVerificationService>(create: (_) => RealityVerificationService()),
        Provider<MaintenanceService>(create: (_) => MaintenanceService()),
        Provider<ConnectedServicesService>(create: (_) => ConnectedServicesService()),
        Provider<MultiLLMService>(create: (_) => MultiLLMService()),
        Provider<AgentTeamService>(create: (_) => AgentTeamService()),
        Provider<SelfProgrammingService>(create: (_) => SelfProgrammingService()),
        Provider<AuditService>(create: (_) => AuditService()),
        ChangeNotifierProvider(create: (_) => ApprovalService()),
        Provider<CircuitBreakerService>(create: (_) => CircuitBreakerService()),
        Provider<WebhookService>(create: (_) => WebhookService()),
        Provider<CollaborationService>(create: (_) => CollaborationService()),
        ProxyProvider2<PluginService, AnalyticsService, GeminiService>(
          create: (ctx) => GeminiService(
            ctx.read<PluginService>(),
            ctx.read<AnalyticsService>(),
          ),
          update: (_, p, a, prev) => prev ?? GeminiService(p, a),
        ),
        ChangeNotifierProxyProvider2<GeminiService, BrowserService, TaskRunnerService>(
          create: (ctx) => TaskRunnerService(ctx.read<GeminiService>(), ctx.read<BrowserService>()),
          update: (_, g, b, prev) => prev ?? TaskRunnerService(g, b),
        ),
      ],
      child: Builder(
        builder: (context) => MaterialApp(
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
            useMaterial3: true,
            textTheme: Theme.of(context).textTheme.apply(
              fontSizeFactor: MediaQuery.textScalerOf(context).scale(1.0),
            ),
          ),
          navigatorKey: navigatorKey,
          initialRoute: '/',
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/':
                return MaterialPageRoute(builder: (_) => const AuthGate());
              case '/home':
                return MaterialPageRoute(builder: (_) => const HomeScreen());
              case '/chat':
                return MaterialPageRoute(builder: (_) => const HomeScreen());
              case '/dashboard':
                return MaterialPageRoute(builder: (_) => const HomeScreen());
              default:
                return MaterialPageRoute(builder: (_) => const HomeScreen());
            }
          },
          home: const AuthGate(),
        ),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _seeded = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (auth.user == null) {
      _seeded = false;
      return const LoginScreen();
    }

    if (!_seeded) {
      _seeded = true;
      context.read<ApprovalService>().seedDefaults();
    }

    return FutureBuilder<bool>(
      future: OnboardingService.isOnboardingComplete(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.data == false) {
          return const OnboardingScreen();
        }
        return const HomeScreen();
      },
    );
  }
}
