import 'package:google_generative_ai/google_generative_ai.dart';
import 'plugin_service.dart';
import '../models/plugin_info.dart';

class GeminiService {
  static const String apiKey = 'AQ.Ab8RN6KKbYNwtMLsyVu1mbIkLRvwoqpLMfPL0L5aDsa7XgDTig'; // Replace this
  late final GenerativeModel _model;
  final PluginService _pluginService;

  // Built-in task creation function
  static const _createTaskFunction = FunctionDeclaration(
    'create_task',
    'Create a new task or reminder for the user',
    Schema(SchemaType.object, properties: {
      'title': Schema(SchemaType.string, description: 'Title of the task'),
      'description': Schema(SchemaType.string, description: 'Optional description'),
      'dueDate': Schema(SchemaType.string, description: 'Due date and time in ISO 8601 format (e.g. 2026-07-11T09:00:00)'),
    }, required: ['title', 'dueDate']),
  );

  GeminiService(this._pluginService) {
    _model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);
  }

  /// Build tools list from built-in tasks + enabled plugins
  List<Tool> _buildTools() {
    final functionDeclarations = <FunctionDeclaration>[_createTaskFunction];

    for (var plugin in _pluginService.plugins) {
      if (plugin.isEnabled) {
        final schemaProperties = <String, Schema>{};
        plugin.parameters.forEach((key, value) {
          schemaProperties[key] = Schema(SchemaType.string, description: value);
        });
        final declaration = FunctionDeclaration(
          plugin.functionName,
          plugin.description,
          Schema(SchemaType.object, properties: schemaProperties),
        );
        functionDeclarations.add(declaration);
      }
    }

    return [Tool(functionDeclarations: functionDeclarations)];
  }

  /// Returns a ChatResponse with text and optional task/plugin result
  Future<ChatResponse> sendMessage(String prompt, List<String>? history) async {
    final contents = <Content>[];
    if (history != null) {
      for (int i = 0; i < history.length; i++) {
        if (i % 2 == 0) {
          contents.add(Content.text(history[i].replaceFirst('User: ', '')));
        } else {
          contents.add(Content.model([TextPart(history[i].replaceFirst('AI: ', ''))]));
        }
      }
    }
    contents.add(Content.text(prompt));

    final tools = _buildTools();
    final functionModel = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      tools: tools,
    );

    final chat = functionModel.startChat(history: contents);
    final response = await chat.sendMessage(Content.text(prompt));

    // Handle function calls
    if (response.functionCalls.isNotEmpty) {
      final call = response.functionCalls.first;
      if (call.name == 'create_task') {
        final args = call.args as Map<String, dynamic>;
        final title = args['title'] as String;
        final dueDate = DateTime.parse(args['dueDate'] as String);
        final description = args['description'] as String?;
        return ChatResponse(
          text: response.text ?? "I've created the task \"$title\".",
          taskToCreate: AiosTaskCommand(title: title, dueDate: dueDate, description: description),
        );
      } else {
        // Plugin function call
        final result = await _pluginService.executeFunction(
          call.name,
          call.args is Map<String, dynamic> ? call.args as Map<String, dynamic> : null,
        );
        return ChatResponse(
          text: response.text ?? result,
          pluginResult: result,
        );
      }
    }

    return ChatResponse(text: response.text ?? 'I could not process that.');
  }
}

class ChatResponse {
  final String text;
  final AiosTaskCommand? taskToCreate;
  final String? pluginResult;

  ChatResponse({required this.text, this.taskToCreate, this.pluginResult});
}

class AiosTaskCommand {
  final String title;
  final DateTime dueDate;
  final String? description;

  AiosTaskCommand({required this.title, required this.dueDate, this.description});
}
