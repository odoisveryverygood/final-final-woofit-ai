import 'package:flutter/material.dart';

import 'agents/agent_controller.dart';
import 'agents/openai_client.dart';
import 'secrets.dart';


class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _text = TextEditingController();
  bool _loading = false;

  // Simple chat history: user + assistant messages
  final List<Map<String, String>> _messages = [];

  late final AgentController _agent;

  @override
  void initState() {
    super.initState();
    _agent = AgentController(
      openAIClient: OpenAIClient(apiKey: openAIApiKey),
    );
  }

  Future<void> _send() async {
    final msg = _text.text.trim();
    if (msg.isEmpty || _loading) return;

    setState(() {
      _loading = true;
      _messages.add({"role": "user", "text": msg});
      _text.clear();
    });

    try {
      final resp = await _agent.handleMessage(
        userMessage: msg,
        dogName: "Luna",
        hasImage: false,
        // You can wire real data later; for now keep it minimal:
        dogProfile: {
          "breed": "Husky",
          "age_years": 3,
          "weight_lbs": 45,
          "goal": "general health",
        },
        recentActivity: null,
      );

      // Show the human-readable part first (ignore JSON noise for now)
      setState(() {
        _messages.add({"role": "assistant", "text": resp.message});
      });
    } catch (e) {
      setState(() {
        _messages.add({"role": "assistant", "text": "Error: $e"});
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("WoofFit AI")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final isUser = m["role"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Text(m["text"] ?? ""),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    minLines: 1,
                    maxLines: 4,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: "Ask about exercise, meals, or symptoms…",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _loading ? null : _send,
                  child: Text(_loading ? "..." : "Send"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
