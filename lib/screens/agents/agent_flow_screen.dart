import 'package:flutter/material.dart';
import 'package:vani_app/config/theme.dart';
import 'package:vani_app/models/agent_model.dart';

class AgentFlowScreen extends StatefulWidget {
  final Agent agent;

  const AgentFlowScreen({super.key, required this.agent});

  @override
  State<AgentFlowScreen> createState() => _AgentFlowScreenState();
}

class _AgentFlowScreenState extends State<AgentFlowScreen> {
  @override
  Widget build(BuildContext context) {
    final agent = widget.agent;
    final nodes = [
      {
        'step': 1,
        'title': 'Start: Call Initiated',
        'subtitle': 'Inbound / Outbound call triggered on ${agent.phoneNumberId ?? "assigned phone"}',
        'icon': Icons.call_made,
        'color': AppTheme.primaryGreen,
        'detail': 'Greeting Line: "${agent.greetingLine ?? "Hello, how can I help you today?"}"',
      },
      {
        'step': 2,
        'title': 'Speech Recognition (ASR / STT)',
        'subtitle': 'Converts user spoken audio to text in real-time',
        'icon': Icons.mic,
        'color': Colors.blue,
        'detail': 'Language: ${agent.ttsLanguage.toUpperCase()} · Keywords: ${agent.asrVocabulary ?? "Default"}',
      },
      {
        'step': 3,
        'title': 'Knowledge Base & Context Lookup',
        'subtitle': 'Injects domain documents into context window',
        'icon': Icons.library_books,
        'color': Colors.purple,
        'detail': 'Attached KB IDs: ${agent.knowledgeBaseIds?.isNotEmpty == true ? agent.knowledgeBaseIds!.join(", ") : "None"}',
      },
      {
        'step': 4,
        'title': 'System Prompt & AI Logic',
        'subtitle': 'Evaluates user query against agent system prompt',
        'icon': Icons.psychology,
        'color': Colors.amber.shade800,
        'detail': 'Engine: ${agent.engineType} · Interruptions: ${agent.allowInterruptions ? "Enabled" : "Disabled"}',
      },
      {
        'step': 5,
        'title': 'Voice Synthesis (TTS / S2S)',
        'subtitle': 'Generates natural voice response audio stream',
        'icon': Icons.record_voice_over,
        'color': Colors.teal,
        'detail': 'Voice: ${agent.voice} · Speed: ${agent.ttsSpeed}x',
      },
      {
        'step': 6,
        'title': 'Post-Call Analysis',
        'subtitle': 'Extracts sentiment, summary, outcome & key points',
        'icon': Icons.analytics,
        'color': AppTheme.purple,
        'detail': 'Analysis Mode: Standard System Default',
      },
    ];

    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.darkGrey),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${agent.name} - Flow',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkGrey,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const Text(
              'Visual Conversation Flow Diagram',
              style: TextStyle(fontSize: 10, color: AppTheme.mediumGrey),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderGrey),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_tree, color: AppTheme.primaryGreen, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            agent.name,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.darkGrey),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Engine: ${agent.engineType} · Voice: ${agent.voice}',
                            style: const TextStyle(fontSize: 11, color: AppTheme.mediumGrey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Conversation Nodes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkGrey),
              ),
              const SizedBox(height: 12),

              // Flow Nodes Timeline
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: nodes.length,
                itemBuilder: (context, index) {
                  final node = nodes[index];
                  final isLast = index == nodes.length - 1;
                  final color = node['color'] as Color;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Step Indicator Column with line
                      Column(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${node['step']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          if (!isLast)
                            Container(
                              width: 2,
                              height: 60,
                              color: AppTheme.borderGrey,
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),

                      // Node Card Content
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.borderGrey),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(node['icon'] as IconData, size: 16, color: color),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      node['title'] as String,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.darkGrey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                node['subtitle'] as String,
                                style: const TextStyle(fontSize: 11, color: AppTheme.mediumGrey),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.lightGrey,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  node['detail'] as String,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppTheme.darkGrey),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
