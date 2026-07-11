import 'package:flutter/foundation.dart';
import 'simple_ai_service.dart';
import 'browser_service.dart';

class TaskRunnerService extends ChangeNotifier {
  final SimpleAiService _aiService;
  final BrowserService _browserService;

  bool _isRunning = false;
  bool get isRunning => _isRunning;
  String _status = '';
  String get status => _status;

  TaskRunnerService(this._aiService, this._browserService);

  Future<void> executeGoal(String goal) async {
    _isRunning = true;
    _status = 'Planning...';
    notifyListeners();

    final responseText = await _aiService.sendMessage(
      userMessage: 'Break this goal into a step-by-step plan and then execute each step using available tools. Goal: $goal',
    );
    _status = responseText;
    
    // In a full implementation, we'd loop and let Gemini drive the browser/email tools.
    // For now we just record the initial plan/action.
    
    _isRunning = false;
    notifyListeners();
  }
}

