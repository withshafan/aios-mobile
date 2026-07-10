import 'package:google_generative_ai/google_generative_ai.dart';
import 'plugin_service.dart';
import '../models/plugin_info.dart';

class GeminiService {
  static const String apiKey = 'AQ.Ab8RN6KKbYNwtMLsyVu1mbIkLRvwoqpLMfPL0L5aDsa7XgDTig'; // Replace this
  late final GenerativeModel _model;
  final PluginService _pluginService;

  static const _createTaskFunction = FunctionDeclaration(
    'create_task',
    'Create a new task or reminder for the user',
    Schema(SchemaType.object, properties: {
      'title': Schema(SchemaType.string, description: 'Title of the task'),
      'description': Schema(SchemaType.string, description: 'Optional description'),
      'dueDate': Schema(SchemaType.string, description: 'Due date and time in ISO 8601 format (e.g. 2026-07-11T09:00:00)'),
    }, required: ['title', 'dueDate']),
  );

  static const _sendEmailFunction = FunctionDeclaration(
    'send_email',
    'Send an email to a recipient',
    Schema(SchemaType.object, properties: {
      'to': Schema(SchemaType.string, description: 'Recipient email address'),
      'subject': Schema(SchemaType.string, description: 'Subject of the email'),
      'body': Schema(SchemaType.string, description: 'Body text of the email'),
    }, required: ['to', 'subject', 'body']),
  );

  GeminiService(this._pluginService) {
    _model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);
  }

  List<Tool> _buildTools() {
    final functionDeclarations = <FunctionDeclaration>[
      _createTaskFunction,
      _sendEmailFunction,
    ];

    for (var plugin in _pluginService.plugins) {
      if (plugin.isEnabled) {
        final schemaProperties = <String, Schema>{};
        plugin.parameters.forEach((key, value) {
          schemaProperties[key] = Schema(SchemaType.string, description: value);
        });
        functionDeclarations.add(FunctionDeclaration(
          plugin.functionName,
          plugin.description,
          Schema(SchemaType.object, properties: schemaProperties),
        ));
      }
    }

    return [Tool(functionDeclarations: functionDeclarations)];
  }

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

    if (response.functionCalls.isNotEmpty) {
      final call = response.functionCalls.first;
      if (call.name == 'create_task') {
        final args = call.args as Map<String, dynamic>;
        return ChatResponse(
          text: response.text ?? "I've created the task.",
          taskToCreate: AiosTaskCommand(
            title: args['title'] as String,
            dueDate: DateTime.parse(args['dueDate'] as String),
            description: args['description'] as String?,
          ),
        );
      } else if (call.name == 'send_email') {
        final args = call.args as Map<String, dynamic>;
        return ChatResponse(
          text: response.text ?? "I've prepared an email.",
          emailToSend: EmailCommand(
            to: args['to'] as String,
            subject: args['subject'] as String,
            body: args['body'] as String,
          ),
        );
      } else {
        // Plugin
        final result = await _pluginService.executeFunction(
          call.name,
          call.args is Map<String, dynamic> ? call.args as Map<String, dynamic> : null,
        );
        return ChatResponse(text: response.text ?? result, pluginResult: result);
      }
    }

    return ChatResponse(text: response.text ?? 'I could not process that.');
  }
}

class ChatResponse {
  final String text;
  final AiosTaskCommand? taskToCreate;
  final String? pluginResult;
  final EmailCommand? emailToSend;

  ChatResponse({required this.text, this.taskToCreate, this.pluginResult, this.emailToSend});
}

class AiosTaskCommand {
  final String title;
  final DateTime dueDate;
  final String? description;

  AiosTaskCommand({required this.title, required this.dueDate, this.description});
}

class EmailCommand {
  final String to;
  final String subject;
  final String body;

  EmailCommand({required this.to, required this.subject, required this.body});
}
