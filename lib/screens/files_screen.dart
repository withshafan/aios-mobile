import 'dart:io';
import 'package:flutter/material.dart';
import '../services/file_service.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final FileService _fileService = FileService();
  String _currentPath = '';
  List<FileSystemEntity> _items = [];
  bool _isLoading = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _hasPermission = await _fileService.requestPermissions();
    if (!_hasPermission) {
      setState(() => _isLoading = false);
      return;
    }
    final base = await _fileService.getBaseDirectory();
    _currentPath = base.path;
    await _refresh();
  }

  Future<void> _refresh() async {
    if (!_hasPermission) return;
    setState(() => _isLoading = true);
    _items = await _fileService.listFiles(_currentPath);
    setState(() => _isLoading = false);
  }

  void _openFolder(String path) {
    setState(() {
      _currentPath = path;
    });
    _refresh();
  }

  Future<void> _readFile(String path) async {
    try {
      final content = await _fileService.readFile(path);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(path.split('/').last),
          content: SingleChildScrollView(
            child: Text(content, style: const TextStyle(fontSize: 14, fontFamily: 'monospace')),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cannot read file: $e')));
    }
  }

  Future<void> _deleteEntity(String path) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete?'),
        content: Text('Delete ${path.split('/').last}?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _fileService.deleteEntity(path);
    _refresh();
  }

  Future<void> _createFile() async {
    final nameController = TextEditingController();
    final contentController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create new file'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'File name (e.g., note.txt)'),
            ),
            TextField(
              controller: contentController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Content'),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          TextButton(
            child: const Text('Create'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (result != true) return;
    await _fileService.createFile(
      _currentPath,
      nameController.text,
      contentController.text,
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!_hasPermission) {
      return Scaffold(
        appBar: AppBar(title: const Text('Files')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Storage permission required'),
              ElevatedButton(
                onPressed: _load,
                child: const Text('Grant permission'),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Files')),
      body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            _currentPath,
            style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              onPressed: _refresh,
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('New File'),
              onPressed: _createFile,
            ),
            if (_currentPath != '/')
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_upward),
                label: const Text('Up'),
                onPressed: () {
                  final parent = Directory(_currentPath).parent;
                  _openFolder(parent.path);
                },
              ),
          ],
        ),
        Expanded(
          child: _items.isEmpty
              ? const Center(child: Text('Empty folder'))
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (ctx, i) {
                    final item = _items[i];
                    final name = item.uri.pathSegments.last;
                    final isDir = item is Directory;
                    return ListTile(
                      leading: Icon(isDir ? Icons.folder : Icons.insert_drive_file),
                      title: Text(name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isDir)
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () => _readFile(item.path),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteEntity(item.path),
                          ),
                        ],
                      ),
                      onTap: isDir ? () => _openFolder(item.path) : () => _readFile(item.path),
                    );
                  },
                ),
        ),
      ],
    ),
    );
  }
}
