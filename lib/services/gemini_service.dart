import 'package:google_generative_ai/google_generative_ai.dart';
import 'plugin_service.dart';
import 'analytics_service.dart';
import 'system_prompt_service.dart';
import 'planner_service.dart';
import '../models/plugin_info.dart';

class GeminiService {
  static const String apiKey = 'AQ.Ab8RN6KKbYNwtMLsyVu1mbIkLRvwoqpLMfPL0L5aDsa7XgDTig'; // Replace this
  late final GenerativeModel _model;
  final PluginService _pluginService;
  final AnalyticsService _analyticsService;
  final SystemPromptService _systemPromptService;
  final PlannerService _plannerService;

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

  static const _openWebsiteFunction = FunctionDeclaration(
    'open_website',
    'Open a website in the in-app browser',
    Schema(SchemaType.object, properties: {
      'url': Schema(SchemaType.string, description: 'The website URL (e.g., https://google.com)'),
    }, required: ['url']),
  );

  static const _createCalendarEventFunction = FunctionDeclaration(
    'create_calendar_event',
    'Create a Google Calendar event',
    Schema(SchemaType.object, properties: {
      'summary': Schema(SchemaType.string, description: 'Event title'),
      'start': Schema(SchemaType.string, description: 'Start date/time in ISO 8601 format (e.g. 2026-07-11T09:00:00)'),
      'end': Schema(SchemaType.string, description: 'End date/time in ISO 8601 format'),
      'description': Schema(SchemaType.string, description: 'Optional description'),
    }, required: ['summary', 'start', 'end']),
  );

  static const _addPlanStepFunction = FunctionDeclaration(
    'add_plan_step',
    'Add a step to the execution plan',
    Schema(SchemaType.object, properties: {
      'description': Schema(SchemaType.string, description: 'Step description'),
    }, required: ['description']),
  );

  static const _completePlanStepFunction = FunctionDeclaration(
    'complete_plan_step',
    'Mark a plan step as completed (provide the step description to match)',
    Schema(SchemaType.object, properties: {
      'description': Schema(SchemaType.string, description: 'Exact description of step to complete'),
    }, required: ['description']),
  );

  GeminiService(this._pluginService, this._analyticsService, this._systemPromptService, this._plannerService);

  List<Tool> _buildTools() {
    final functionDeclarations = <FunctionDeclaration>[
      _createTaskFunction,
      _sendEmailFunction,
      _openWebsiteFunction,
      _createCalendarEventFunction,
      _addPlanStepFunction,
      _completePlanStepFunction,
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
    final systemInstruction = Content.text(_systemPromptService.currentPrompt);
    
    final functionModel = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      tools: tools,
      systemInstruction: systemInstruction,
    );

    final chat = functionModel.startChat(history: contents);
    final response = await chat.sendMessage(Content.text(prompt));

    final inputTokens = _analyticsService.estimateTokens(prompt);
    final outputTokens = _analyticsService.estimateTokens(response.text ?? '');
    await _analyticsService.logMessage(inputTokens, outputTokens);

    if (response.functionCalls.isNotEmpty) {
      final call = response.functionCalls.first;
      if (call.name == 'create_task') {
        final args = call.args as Map<String, dynamic>;
        await _analyticsService.logMessage(0, 0, agentName: 'task');
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
        await _analyticsService.logMessage(0, 0, agentName: 'email');
        return ChatResponse(
          text: response.text ?? "I've prepared an email.",
          emailToSend: EmailCommand(
            to: args['to'] as String,
            subject: args['subject'] as String,
            body: args['body'] as String,
          ),
        );
      } else if (call.name == 'open_website') {
        final args = call.args as Map<String, dynamic>;
        await _analyticsService.logMessage(0, 0, agentName: 'browser');
        return ChatResponse(
          text: response.text ?? "Opening ${args['url']}.",
          browserUrl: args['url'] as String,
        );
      } else if (call.name == 'create_calendar_event') {
        final args = call.args as Map<String, dynamic>;
        await _analyticsService.logMessage(0, 0, agentName: 'calendar');
        return ChatResponse(
          text: response.text ?? "I've scheduled the event.",
          calendarEvent: CalendarEventCommand(
            summary: args['summary'] as String,
            start: DateTime.parse(args['start'] as String),
            end: DateTime.parse(args['end'] as String),
            description: args['description'] as String?,
          ),
        );
      } else if (call.name == 'add_plan_step') {
        final args = call.args as Map<String, dynamic>;
        final description = args['description'] as String;
        await _plannerService.addTask(description);
        await _analyticsService.logMessage(0, 0, agentName: 'planner');
        return ChatResponse(
          text: response.text ?? "Added plan step.",
          plannerAction: PlannerAction(type: 'add', description: description),
        );
      } else if (call.name == 'complete_plan_step') {
        final args = call.args as Map<String, dynamic>;
        final description = args['description'] as String;
        final tasks = _plannerService.tasks;
        for (var task in tasks) {
          if (task['description'] == description) {
            await _plannerService.updateStatus(task['id'], 'completed');
            break;
          }
        }
        await _analyticsService.logMessage(0, 0, agentName: 'planner');
        return ChatResponse(
          text: response.text ?? "Completed plan step.",
          plannerAction: PlannerAction(type: 'complete', description: description),
        );
      } else {
        final result = await _pluginService.executeFunction(
          call.name,
          call.args is Map<String, dynamic> ? call.args as Map<String, dynamic> : null,
        );
        await _analyticsService.logMessage(0, 0, agentName: 'plugin');
        return ChatResponse(text: response.text ?? result, pluginResult: result);
      }
    }

    return ChatResponse(text: response.text ?? 'I could not process that.');
  }
}

class PlannerAction {
  final String type; // 'add' or 'complete'
  final String description;
  PlannerAction({required this.type, required this.description});
}

class ChatResponse {
  final String text;
  final AiosTaskCommand? taskToCreate;
  final String? pluginResult;
  final EmailCommand? emailToSend;
  final String? browserUrl;
  final CalendarEventCommand? calendarEvent;
  final PlannerAction? plannerAction;

  ChatResponse({
    required this.text,
    this.taskToCreate,
    this.pluginResult,
    this.emailToSend,
    this.browserUrl,
    this.calendarEvent,
    this.plannerAction,
  });
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

class CalendarEventCommand {
  final String summary;
  final DateTime start;
  final DateTime end;
  final String? description;

  CalendarEventCommand({required this.summary, required this.start, required this.end, this.description});
}
