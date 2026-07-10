import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:graphview/GraphView.dart';
import 'package:graphview/forcedirected/FruchtermanReingoldAlgorithm.dart';
import 'package:graphview/forcedirected/FruchtermanReingoldConfiguration.dart';
import '../theme/tokens.dart';
import '../services/memory_service.dart';

class KnowledgeGraphScreen extends StatefulWidget {
  const KnowledgeGraphScreen({super.key});

  @override
  State<KnowledgeGraphScreen> createState() => _KnowledgeGraphScreenState();
}

class _KnowledgeGraphScreenState extends State<KnowledgeGraphScreen> {
  late Graph graph;
  late FruchtermanReingoldAlgorithm algorithm;
  List<Node> nodes = [];

  @override
  void initState() {
    super.initState();
    graph = Graph()..isTree = false;
    algorithm = FruchtermanReingoldAlgorithm(
      FruchtermanReingoldConfiguration(),
    );
  }

  void _buildGraph(List<String> messages) {
    graph = Graph()..isTree = false;
    nodes.clear();
    final nodeMap = <String, Node>{};
    // Simple example: every unique word over 4 chars becomes a node
    final words = messages.join(' ').split(' ').where((w) => w.length > 4).toSet().take(20).toList();
    for (var word in words) {
      final node = Node.Id(word);
      nodes.add(node);
      nodeMap[word] = node;
      graph.addNode(node);
    }
    // Connect random nodes for demo
    for (int i = 0; i < nodes.length - 1; i++) {
      graph.addEdge(nodes[i], nodes[i + 1]);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final memory = context.watch<MemoryService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Knowledge Graph'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final messages = memory.messages.map((m) => m.content).toList();
              _buildGraph(messages);
            },
          ),
        ],
      ),
      body: nodes.isEmpty
          ? Center(
              child: ElevatedButton(
                onPressed: () {
                  final messages = memory.messages.map((m) => m.content).toList();
                  _buildGraph(messages);
                },
                child: const Text('Generate Graph'),
              ),
            )
          : InteractiveViewer(
              constrained: false,
              boundaryMargin: const EdgeInsets.all(100),
              minScale: 0.1,
              maxScale: 3.0,
              child: GraphView(
                graph: graph,
                algorithm: algorithm,
                paint: Paint()
                  ..color = AppColors.accentViolet.withOpacity(0.4)
                  ..strokeWidth = 1.5
                  ..style = PaintingStyle.stroke,
                builder: (Node node) {
                  final key = node.key!.value as String;
                  return GestureDetector(
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(key))),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accentViolet,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        key.length > 15 ? '${key.substring(0, 15)}...' : key,
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
