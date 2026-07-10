import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/memory_service.dart';
import 'services/task_service.dart';
import 'services/document_service.dart';
import 'services/workflow_service.dart';
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
      ],
      child: MaterialApp(
        title: 'AIOS Mobile',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const AuthGate(),
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
