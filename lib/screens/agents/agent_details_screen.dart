import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vani_app/config/theme.dart';
import 'package:vani_app/models/agent_model.dart';
import 'package:vani_app/presentation/providers/agents_provider.dart';
import 'package:vani_app/screens/agents/create_edit_agent_screen.dart';

class AgentDetailsScreen extends ConsumerStatefulWidget {
  final Agent agent;

  const AgentDetailsScreen({super.key, required this.agent});

  @override
  ConsumerState<AgentDetailsScreen> createState() => _AgentDetailsScreenState();
}

class _AgentDetailsScreenState extends ConsumerState<AgentDetailsScreen> {
  late Agent _currentAgent;

  @override
  void initState() {
    super.initState();
    _currentAgent = widget.agent;
  }

  @override
  Widget build(BuildContext context) {
    final agentsState = ref.watch(agentsProvider);

    // Update current agent if it exists in the state
    final updatedAgent = agentsState.agents.firstWhere(
      (agent) => agent.id == _currentAgent.id,
      orElse: () => _currentAgent,
    );
    _currentAgent = updatedAgent;

    final phoneNumber = agentsState.getPhoneNumber(_currentAgent);
    final realtimePrompt =
        _currentAgent.s2sPromptConfig?['system_prompt'] as String? ??
        _currentAgent.s2sPromptConfig?['prompt'] as String? ??
        _currentAgent.s2sPromptConfig?['systemPrompt'] as String? ??
        '';

    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.darkGrey),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _currentAgent.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.darkGrey,
          ),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _currentAgent.isActive
                  ? const Color(0x1F10B981) // light green opacity
                  : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _currentAgent.isActive
                    ? AppTheme.primaryGreen.withOpacity(0.3)
                    : AppTheme.borderGrey,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentAgent.isActive
                        ? AppTheme.primaryGreen
                        : AppTheme.mediumGrey,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _currentAgent.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _currentAgent.isActive
                        ? AppTheme.primaryGreen
                        : AppTheme.mediumGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Configuration Details Cards
                _buildDetailSection('Basic Information', [
                  _buildDetailRow('Agent ID', _currentAgent.id),
                  _buildDetailRow('User ID', _currentAgent.userId),
                  _buildDetailRow('Phone Number', phoneNumber),
                ]),

                _buildDetailSection('Voice Configuration', [
                  _buildDetailRow('Voice Engine', _currentAgent.engineType),
                  _buildDetailRow('Voice Profile', _currentAgent.voice),
                  _buildDetailRow('TTS Provider', _currentAgent.ttsProvider),
                  _buildDetailRow('TTS Language', _currentAgent.ttsLanguage),
                  _buildDetailRow(
                    'TTS Speed',
                    _currentAgent.ttsSpeed.toString(),
                  ),
                  if (_currentAgent.speechToSpeechProvider != null)
                    _buildDetailRow(
                      'S2S Provider',
                      _currentAgent.speechToSpeechProvider!,
                    ),
                  if (_currentAgent.geminiLiveVoice != null)
                    _buildDetailRow(
                      'Gemini Live Voice',
                      _currentAgent.geminiLiveVoice!,
                    ),
                  if (_currentAgent.geminiLiveLanguage != null)
                    _buildDetailRow(
                      'Gemini Live Language',
                      _currentAgent.geminiLiveLanguage!,
                    ),
                  if (_currentAgent.asrVocabulary != null &&
                      _currentAgent.asrVocabulary!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'ASR Vocabulary Keywords',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.mediumGrey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildDetailText(_currentAgent.asrVocabulary!),
                  ],
                ]),

                _buildDetailSection('Call Settings', [
                  _buildDetailRow(
                    'Allow Interruptions',
                    _currentAgent.allowInterruptions ? 'Yes' : 'No',
                  ),
                  _buildDetailRow(
                    'Background Music',
                    _currentAgent.backgroundMusic ? 'Yes' : 'No',
                  ),
                  _buildDetailRow(
                    'Debug Logging',
                    _currentAgent.debugLogging ? 'Yes' : 'No',
                  ),
                  _buildDetailRow(
                    'Hard End Call',
                    '${_currentAgent.hardEndCallMinutes} minutes',
                  ),
                  _buildDetailRow(
                    'Cache Hit Rate',
                    '${(_currentAgent.cacheHitRate * 100).toStringAsFixed(1)}%',
                  ),
                ]),

                _buildDetailSection('Greeting Configuration', [
                  _buildDetailRow(
                    'Greeting Type',
                    _currentAgent.greetingType.toUpperCase(),
                  ),
                  if (_currentAgent.greetingLine != null &&
                      _currentAgent.greetingLine!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _buildDetailText(_currentAgent.greetingLine!),
                  ],
                ]),

                if (_currentAgent.localFallbackPrompt != null &&
                    _currentAgent.localFallbackPrompt!.trim().isNotEmpty)
                  _buildDetailSection('Local Fallback Prompt', [
                    _buildDetailText(_currentAgent.localFallbackPrompt!),
                  ]),

                if (_currentAgent.agentPrompt != null &&
                    _currentAgent.agentPrompt!.trim().isNotEmpty)
                  _buildDetailSection('Classic Agent Prompt', [
                    _buildDetailText(_currentAgent.agentPrompt!),
                  ]),

                if (realtimePrompt.trim().isNotEmpty)
                  _buildDetailSection('Realtime Prompt', [
                    _buildDetailText(realtimePrompt),
                  ]),

                if (_currentAgent.analysisPrompt != null &&
                    _currentAgent.analysisPrompt!.trim().isNotEmpty)
                  _buildDetailSection('Analysis Prompt', [
                    _buildDetailText(_currentAgent.analysisPrompt!),
                  ]),

                if (_currentAgent.transcriptionLanguages != null &&
                    _currentAgent.transcriptionLanguages!.isNotEmpty)
                  _buildDetailSection('Transcription Languages', [
                    _buildDetailText(
                      _currentAgent.transcriptionLanguages!.join(', '),
                    ),
                  ]),

                if (_currentAgent.knowledgeBaseIds != null &&
                    _currentAgent.knowledgeBaseIds!.isNotEmpty)
                  _buildDetailSection('Attached Knowledge Bases', [
                    _buildDetailText(
                      _currentAgent.knowledgeBaseIds!.join(', '),
                    ),
                  ]),

                _buildDetailSection('Video Avatar', [
                  _buildDetailRow(
                    'Avatar Enabled',
                    _currentAgent.enableVideoAvatar ? 'Yes' : 'No',
                  ),
                  if (_currentAgent.simliFaceId != null &&
                      _currentAgent.simliFaceId!.isNotEmpty)
                    _buildDetailRow(
                      'Simli Face ID',
                      _currentAgent.simliFaceId!,
                    ),
                ]),

                _buildDetailSection('Timestamps', [
                  _buildDetailRow('Created At', _currentAgent.createdAt),
                  _buildDetailRow('Updated At', _currentAgent.updatedAt),
                ]),

                const SizedBox(height: 16),

                // Action Buttons: Edit and Delete
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CreateEditAgentScreen(agent: _currentAgent),
                            ),
                          ).then((_) {
                            ref.read(agentsProvider.notifier).loadAgents();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text(
                          'Edit Configuration',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showDeleteConfirmation,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppTheme.errorRed.withOpacity(0.1),
                          side: const BorderSide(color: AppTheme.errorRed),
                          foregroundColor: AppTheme.errorRed,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text(
                          'Delete Agent',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkGrey,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.mediumGrey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.darkGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailText(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.lightGrey,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppTheme.darkGrey,
          height: 1.4,
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Agent'),
        content: Text(
          'Are you sure you want to delete "${_currentAgent.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(agentsProvider.notifier).deleteAgent(_currentAgent.id);
              Navigator.pop(context); // Go back to agents list
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
