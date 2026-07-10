import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String apiKey = 'AQ.Ab8RN6KKbYNwtMLsyVu1mbIkLRvwoqpLMfPL0L5aDsa7XgDTig'; // Replace this
  late final GenerativeModel _model;
  late final GenerativeModel _functionModel;

  // Define the create_task function for the AI
  static const _createTaskFunction = FunctionDeclaration(
    'create_task',
    'Create a new task or reminder for the user',
    Schema(SchemaType.object, properties: {
      'title': Schema(SchemaType.string, description: 'Title of the task'),
      'description': Schema(SchemaType.string, description: 'Optional description'),
      'dueDate': Schema(SchemaType.string, description: 'Due date and time in ISO 8601 format (e.g. 2026-07-11T09:00:00)'),
    }, required: ['title', 'dueDate']),
  );

  final _tools = [Tool(functionDeclarations: [_createTaskFunction])];

  GeminiService() {
    _model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);
    _functionModel = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      tools: _tools,
    );
  }

  /// Returns a message, and optionally a function call result (if task creation was detected).
  Future<ChatResponse> sendMessage(String prompt, List<String>? history) async {
    // Build history as Content objects
    final contents = <Content>[];
    if (history != null) {
      for (int i = 0; i < history.length; i++) {
        if (i % 2 == 0) {
          // User message
          contents.add(Content.text(history[i].replaceFirst('User: ', '')));
        } else {
          // AI message
          contents.add(Content.model([TextPart(history[i].replaceFirst('AI: ', ''))]));
        }
      }
    }
    // Append the new user message
    contents.add(Content.text(prompt));

    // First, try with function calling
    final chat = _functionModel.startChat(history: contents);
    final response = await chat.sendMessage(Content.text(prompt));

    // Check if there's a function call
    if (response.functionCalls.isNotEmpty) {
      final call = response.functionCalls.first;
      if (call.name == 'create_task') {
        final args = call.args as Map<String, dynamic>;
        final title = args['title'] as String;
        final dueDate = DateTime.parse(args['dueDate'] as String);
        final description = args['description'] as String?;

        // Return both the AI text and the task data separately
        return ChatResponse(
          text: response.text ?? "I've created the task \"$title\".",
          taskToCreate: AiosTaskCommand(title: title, dueDate: dueDate, description: description),
        );
      }
    }

    // Fallback: no function call, just text
    return ChatResponse(text: response.text ?? 'I could not process that.');
  }
}

class ChatResponse {
  final String text;
  final AiosTaskCommand? taskToCreate;

  ChatResponse({required this.text, this.taskToCreate});
}

class AiosTaskCommand {
  final String title;
  final DateTime dueDate;
  final String? description;

  AiosTaskCommand({required this.title, required this.dueDate, this.description});
}
