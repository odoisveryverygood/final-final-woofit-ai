import 'package:flutter/material.dart';

import 'agents/agent_controller.dart';
import 'agents/openai_client.dart';
import 'secrets.dart';

class AgentTestPage extends StatefulWidget {
  const AgentTestPage({super.key});

  @override
  State<AgentTestPage> createState() => _AgentTestPageState();
}

class _AgentTestPageState extends State<AgentTestPage> {
  final _controller = TextEditingController(text: "How long should my husky walk today?");
  String _output = "";
  bool _loading = false;

  late final AgentController agentController;

  @override
  void initState() {
    super.initState();
    agentController = AgentController(
      openAIClient: OpenAIClient(apiKey: openAIApiKey),
    );
  }

  Future<void> _runTest() async {
    setState(() {
      _loading = true;
      _output = "";
    });

    try {
      final resp = await agentController.handleMessage(
        userMessage: _controller.text.trim(),
        dogName: "Luna",
        hasImage: false,
        dogProfile: {
          "breed": "Husky",
          "age_years": 3,
          "weight_lbs": 45,
          "goal": "general health"
        },
        recentActivity: {
          "last_7_days_steps": [8200, 7600, 9100, 4000, 3900, 4200, 4100],
          "trend_note": "activity dropped past 4 days"
        },
      );

      setState(() {
        _output =
            "Agent: ${resp.agent}\n\nMessage:\n${resp.message}\n\nData:\n${resp.data}\n\nRAW:\n${resp.raw}";
      });
    } catch (e) {
      setState(() {
        _output = "ERROR:\n$e";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Agent Test")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Test message",
                border: OutlineInputBorder(),
              ),
              minLines: 1,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _runTest,
              child: Text(_loading ? "Running..." : "Run Agent Test"),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_output),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
