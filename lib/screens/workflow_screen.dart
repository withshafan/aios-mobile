import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../theme/tokens.dart';
import '../theme/aura_theme.dart';
import '../models/workflow.dart';
import '../services/workflow_service.dart';

class WorkflowScreen extends StatefulWidget {
  const WorkflowScreen({super.key});

  @override
  State<WorkflowScreen> createState() => _WorkflowScreenState();
}

class _WorkflowScreenState extends State<WorkflowScreen> {
  final _nameController = TextEditingController();
  final _actionDataController = TextEditingController();
  String _actionType = 'create_task';
  bool _isActive = true;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  String? _editingId;

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _actionDataController.dispose();
    super.dispose();
  }

  // Open a time picker
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppColors.surfaceRaised,
              hourMinuteTextColor: AppColors.textPrimary,
              dialTextColor: AppColors.textPrimary,
              dayPeriodTextColor: AppColors.textPrimary,
              hourMinuteColor: AppColors.accentViolet,
              dayPeriodColor: AppColors.accentViolet,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  // Format time like "09:00 AM"
  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _resetForm() {
    _nameController.clear();
    _actionDataController.clear();
    setState(() {
      _editingId = null;
      _actionType = 'create_task';
      _isActive = true;
      _selectedTime = const TimeOfDay(hour: 9, minute: 0);
    });
  }

  void _editWorkflow(Workflow workflow) {
    _nameController.text = workflow.name;
    _actionDataController.text = workflow.actionData;
    // Parse triggerData like "09:00" into TimeOfDay
    final parts = workflow.triggerData.split(':');
    if (parts.length == 2) {
      final hour = int.tryParse(parts[0]) ?? 9;
      final minute = int.tryParse(parts[1]) ?? 0;
      _selectedTime = TimeOfDay(hour: hour, minute: minute);
    }
    setState(() {
      _editingId = workflow.id;
      _actionType = workflow.actionType;
      _isActive = workflow.isActive;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final actionData = _actionDataController.text.trim();
    if (name.isEmpty || actionData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // Convert time to "HH:mm" (24h) as triggerData
    final timeStr = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    final service = context.read<WorkflowService>();

    if (_editingId == null) {
      final workflow = Workflow(
        id: const Uuid().v4(),
        name: name,
        triggerType: 'time',
        triggerData: timeStr,
        actionType: _actionType,
        actionData: actionData,
        isActive: _isActive,
      );
      await service.addWorkflow(workflow);
    } else {
      final workflow = Workflow(
        id: _editingId!,
        name: name,
        triggerType: 'time',
        triggerData: timeStr,
        actionType: _actionType,
        actionData: actionData,
        isActive: _isActive,
      );
      await service.updateWorkflow(workflow);
    }
    _resetForm();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workflow saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final workflows = context.watch<WorkflowService>().workflows;
    final theme = Theme.of(context).extension<AuraTheme>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Workflows')),
      body: Column(
        children: [
          // Creation form
          Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _editingId == null ? 'Create Workflow' : 'Edit Workflow',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textPrimary),
                  ),
                  const SizedBox(height: space3),
                  // Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Workflow Name',
                      hintText: 'e.g., Morning reminder',
                      filled: true,
                      fillColor: AppColors.surfaceRaised,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusSm), borderSide: BorderSide.none),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: space3),
                  // Time picker
                  InkWell(
                    onTap: _pickTime,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Trigger Time',
                        filled: true,
                        fillColor: AppColors.surfaceRaised,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusSm), borderSide: BorderSide.none),
                        suffixIcon: const Icon(Icons.access_time, color: AppColors.accentViolet),
                      ),
                      child: Text(
                        _formatTime(_selectedTime),
                        style: TextStyle(color: theme.textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(height: space3),
                  // Action type dropdown
                  DropdownButtonFormField<String>(
                    value: _actionType,
                    decoration: InputDecoration(
                      labelText: 'Action',
                      filled: true,
                      fillColor: AppColors.surfaceRaised,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusSm), borderSide: BorderSide.none),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'create_task', child: Text('Create Task')),
                      DropdownMenuItem(value: 'notification', child: Text('Show Notification')),
                    ],
                    onChanged: (val) => setState(() => _actionType = val!),
                  ),
                  const SizedBox(height: space3),
                  // Action data
                  TextFormField(
                    controller: _actionDataController,
                    decoration: InputDecoration(
                      labelText: _actionType == 'create_task' ? 'Task title' : 'Notification text',
                      filled: true,
                      fillColor: AppColors.surfaceRaised,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusSm), borderSide: BorderSide.none),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: space3),
                  // Active switch
                  SwitchListTile(
                    title: const Text('Active'),
                    value: _isActive,
                    onChanged: (val) => setState(() => _isActive = val),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: space2),
                  // Buttons
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _save,
                        child: Text(_editingId == null ? 'Save' : 'Update'),
                      ),
                      if (_editingId != null)
                        TextButton(
                          onPressed: _resetForm,
                          child: const Text('Cancel'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          // Existing workflows list
          Expanded(
            child: workflows.isEmpty
                ? const Center(child: Text('No workflows yet'))
                : ListView.builder(
                    padding: const EdgeInsets.all(space4),
                    itemCount: workflows.length,
                    itemBuilder: (_, i) {
                      final wf = workflows[i];
                      // Convert triggerData "09:00" to human readable
                      String triggerLabel = wf.triggerData;
                      if (wf.triggerType == 'time') {
                        final parts = wf.triggerData.split(':');
                        if (parts.length == 2) {
                          final hour = int.tryParse(parts[0]) ?? 0;
                          final minute = int.tryParse(parts[1]) ?? 0;
                          final tod = TimeOfDay(hour: hour, minute: minute);
                          triggerLabel = _formatTime(tod);
                        }
                      }
                      return Card(
                        color: AppColors.surfaceRaised,
                        margin: const EdgeInsets.only(bottom: space2),
                        child: ListTile(
                          title: Text(wf.name),
                          subtitle: Text('$triggerLabel → ${wf.actionType}: ${wf.actionData}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(wf.isActive ? Icons.toggle_on : Icons.toggle_off),
                                onPressed: () => context.read<WorkflowService>().toggleActive(wf.id, wf.isActive),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editWorkflow(wf),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: AppColors.accentCritical),
                                onPressed: () => context.read<WorkflowService>().deleteWorkflow(wf.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
