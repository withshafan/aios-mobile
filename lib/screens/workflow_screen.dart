import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/workflow.dart';
import '../services/workflow_service.dart';

class WorkflowScreen extends StatefulWidget {
  const WorkflowScreen({super.key});

  @override
  State<WorkflowScreen> createState() => _WorkflowScreenState();
}

class _WorkflowScreenState extends State<WorkflowScreen> {
  final _nameController = TextEditingController();
  final _timeController = TextEditingController();
  final _actionDataController = TextEditingController();
  String _actionType = 'create_task';
  bool _isActive = true;
  String? _editingId;

  @override
  void dispose() {
    _nameController.dispose();
    _timeController.dispose();
    _actionDataController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _nameController.clear();
    _timeController.clear();
    _actionDataController.clear();
    setState(() {
      _editingId = null;
      _actionType = 'create_task';
      _isActive = true;
    });
  }

  void _editWorkflow(Workflow workflow) {
    _nameController.text = workflow.name;
    _timeController.text = workflow.triggerData;
    _actionDataController.text = workflow.actionData;
    setState(() {
      _editingId = workflow.id;
      _actionType = workflow.actionType;
      _isActive = workflow.isActive;
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final time = _timeController.text.trim();
    final actionData = _actionDataController.text.trim();
    if (name.isEmpty || time.isEmpty || actionData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }
    // Validate time format HH:mm
    if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(time)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Time must be in HH:mm format (e.g., 09:00)')),
      );
      return;
    }

    final service = context.read<WorkflowService>();
    if (_editingId == null) {
      // Add new
      final workflow = Workflow(
        id: const Uuid().v4(),
        name: name,
        triggerType: 'time',
        triggerData: time,
        actionType: _actionType,
        actionData: actionData,
        isActive: _isActive,
      );
      await service.addWorkflow(workflow);
    } else {
      // Update
      final workflow = Workflow(
        id: _editingId!,
        name: name,
        triggerType: 'time',
        triggerData: time,
        actionType: _actionType,
        actionData: actionData,
        isActive: _isActive,
      );
      await service.updateWorkflow(workflow);
    }
    _resetForm();
  }

  @override
  Widget build(BuildContext context) {
    final workflows = context.watch<WorkflowService>().workflows;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            _editingId == null ? 'Create Workflow' : 'Edit Workflow',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Workflow Name',
              hintText: 'e.g., Morning reminder',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _timeController,
            decoration: const InputDecoration(
              labelText: 'Trigger Time (HH:mm)',
              hintText: '09:00',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _actionType,
            decoration: const InputDecoration(
              labelText: 'Action',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'create_task', child: Text('Create Task')),
              DropdownMenuItem(value: 'notification', child: Text('Show Notification')),
            ],
            onChanged: (val) => setState(() => _actionType = val!),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _actionDataController,
            decoration: InputDecoration(
              labelText: _actionType == 'create_task' ? 'Task title' : 'Notification text',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Active'),
            value: _isActive,
            onChanged: (val) => setState(() => _isActive = val),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(onPressed: _save, child: Text(_editingId == null ? 'Save' : 'Update')),
              if (_editingId != null)
                ElevatedButton(onPressed: _resetForm, child: const Text('Cancel')),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: workflows.length,
              itemBuilder: (_, i) {
                final wf = workflows[i];
                return ListTile(
                  title: Text(wf.name),
                  subtitle: Text(
                    '${wf.triggerType}: ${wf.triggerData} → ${wf.actionType}: ${wf.actionData}',
                  ),
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
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => context.read<WorkflowService>().deleteWorkflow(wf.id),
                      ),
                    ],
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
