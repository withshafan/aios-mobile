import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:provider/provider.dart';
import '../services/memory_service.dart'; 

class KnowledgeGraphScreen extends StatelessWidget {
  const KnowledgeGraphScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final memory = context.watch<MemoryService>();
    final graph = Graph()..isTree = false;
    final Map<String, Node> nodes = {};

    // Build graph from recent topics (simplistic example)
    for (var msg in memory.messages) {
      if (!nodes.containsKey(msg.content)) {
        final node = Node.Id(msg.content);
        nodes[msg.content] = node;
        graph.addNode(node);
      }
      // create relationships (random for demo; real would use NLP)
      if (nodes.length > 1) {
        final keys = nodes.keys.toList();
        graph.addEdge(nodes[keys.first]!, nodes[keys.last]!);
      }
    }

    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(100),
      minScale: 0.1,
      maxScale: 5.0,
      child: GraphView(
        graph: graph,
        algorithm: FruchtermanReingoldAlgorithm(),
        paint: Paint()
          ..color = Colors.green
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
        builder: (Node node) {
          final key = node.key!.value as String;
          return GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(key))),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(key.length > 20 ? '${key.substring(0, 20)}...' : key,
                  style: const TextStyle(fontSize: 10, color: Colors.white)),
            ),
          );
        },
      ),
    );
  }
}
