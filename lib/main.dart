import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
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
import 'services/task_runner_service.dart';
import 'services/gemini_service.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

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
        Provider<CircuitBreakerService>(create: (_) => CircuitBreakerService()),
        Provider<WebhookService>(create: (_) => WebhookService()),
        Provider<CollaborationService>(create: (_) => CollaborationService()),
        ProxyProvider4<PluginService, AnalyticsService, SystemPromptService, PlannerService, GeminiService>(
          create: (ctx) => GeminiService(
            ctx.read<PluginService>(),
            ctx.read<AnalyticsService>(),
            ctx.read<SystemPromptService>(),
            ctx.read<PlannerService>(),
          ),
          update: (_, p, a, s, pl, prev) => prev ?? GeminiService(p, a, s, pl),
        ),
        ChangeNotifierProxyProvider2<GeminiService, BrowserService, TaskRunnerService>(
          create: (ctx) => TaskRunnerService(ctx.read<GeminiService>(), ctx.read<BrowserService>()),
          update: (_, g, b, prev) => prev ?? TaskRunnerService(g, b),
        ),
      ],
      child: Builder(
        builder: (context) => MaterialApp(
          title: 'AIOS Mobile',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            textTheme: Theme.of(context).textTheme.apply(
              fontSizeFactor: MediaQuery.textScalerOf(context).scale(1.0),
            ),
          ),
          home: const AuthGate(),
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (auth.user == null) {
      return const LoginScreen();
    }
    return const HomeScreen();
  }
}
