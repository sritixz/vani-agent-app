import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vani_app/config/theme.dart';
import 'package:vani_app/models/analysis_config_model.dart';
import 'package:vani_app/presentation/providers/agents_provider.dart';

class AgentAnalysisConfigScreen extends ConsumerStatefulWidget {
  final String agentPrompt;
  final Map<String, dynamic>? existingConfig;

  const AgentAnalysisConfigScreen({
    super.key,
    required this.agentPrompt,
    this.existingConfig,
  });

  @override
  ConsumerState<AgentAnalysisConfigScreen> createState() => _AgentAnalysisConfigScreenState();
}

class _AgentAnalysisConfigScreenState extends ConsumerState<AgentAnalysisConfigScreen> {
  bool _isGenerating = false;
  
  final TextEditingController _sentimentRulesController = TextEditingController();
  final TextEditingController _outcomeGuidanceController = TextEditingController();
  final TextEditingController _keyPointsGuidanceController = TextEditingController();
  final TextEditingController _actionItemsGuidanceController = TextEditingController();
  
  final List<Map<String, String>> _customFields = [];

  @override
  void initState() {
    super.initState();
    
    // Load existing config if available
    if (widget.existingConfig != null) {
      _sentimentRulesController.text = widget.existingConfig!['sentiment_rules'] ?? '';
      _outcomeGuidanceController.text = widget.existingConfig!['outcome_guidance'] ?? '';
      _keyPointsGuidanceController.text = widget.existingConfig!['key_points_guidance'] ?? '';
      _actionItemsGuidanceController.text = widget.existingConfig!['action_items_guidance'] ?? '';
      
      if (widget.existingConfig!['custom_fields'] != null) {
        final customFieldsList = widget.existingConfig!['custom_fields'] as List<dynamic>;
        for (var field in customFieldsList) {
          _customFields.add({
            'name': field['name'] as String,
            'type': field['type'] as String,
            'description': field['description'] as String,
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _sentimentRulesController.dispose();
    _outcomeGuidanceController.dispose();
    _keyPointsGuidanceController.dispose();
    _actionItemsGuidanceController.dispose();
    super.dispose();
  }

  Future<void> _generateConfig() async {
    if (widget.agentPrompt.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agent prompt is required to generate config'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final configData = await ref
          .read(agentsProvider.notifier)
          .generateAnalysisConfig(widget.agentPrompt);
      
      final suggestion = AnalysisConfigSuggestion.fromJson(configData);
      
      setState(() {
        _sentimentRulesController.text = suggestion.sentimentRules;
        _outcomeGuidanceController.text = suggestion.outcomeGuidance;
        _keyPointsGuidanceController.text = suggestion.keyPointsGuidance;
        _actionItemsGuidanceController.text = suggestion.actionItemsGuidance;
        
        // Add suggested custom fields
        for (var field in suggestion.suggestedCustomFields) {
          _customFields.add({
            'name': field.name,
            'type': field.type,
            'description': field.description,
          });
        }
        
        _isGenerating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Analysis config generated successfully'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate config: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  void _addCustomField() {
    setState(() {
      _customFields.add({
        'name': '',
        'type': 'string',
        'description': '',
      });
    });
  }

  void _removeCustomField(int index) {
    setState(() {
      _customFields.removeAt(index);
    });
  }

  Map<String, dynamic> _buildConfig() {
    return {
      'sentiment_rules': _sentimentRulesController.text.trim(),
      'outcome_guidance': _outcomeGuidanceController.text.trim(),
      'key_points_guidance': _keyPointsGuidanceController.text.trim(),
      'action_items_guidance': _actionItemsGuidanceController.text.trim(),
      'custom_fields': _customFields.where((field) => field['name']!.isNotEmpty).toList(),
    };
  }

  void _saveConfig() {
    final config = _buildConfig();
    Navigator.pop(context, config);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Analysis Configuration'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [


              // Generate Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generateConfig,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.auto_awesome, color: Colors.white),
                  label: Text(
                    _isGenerating ? 'Generating...' : 'Generate Config from Agent Prompt',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.surfaceCard,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sentiment Rules
              _buildSectionTitle('Sentiment Rules'),
              const SizedBox(height: 8),
              const Text(
                'Define how sentiment should be analyzed in conversations',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.mediumGrey,
                ),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _sentimentRulesController,
                hint: 'e.g., Analyze customer satisfaction, frustration levels...',
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Outcome Guidance
              _buildSectionTitle('Outcome Guidance'),
              const SizedBox(height: 8),
              const Text(
                'Define what constitutes a successful outcome',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.mediumGrey,
                ),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _outcomeGuidanceController,
                hint: 'e.g., Issue resolved, appointment scheduled...',
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Key Points Guidance
              _buildSectionTitle('Key Points Guidance'),
              const SizedBox(height: 8),
              const Text(
                'Define what key points should be extracted',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.mediumGrey,
                ),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _keyPointsGuidanceController,
                hint: 'e.g., Customer concerns, product mentioned...',
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Action Items Guidance
              _buildSectionTitle('Action Items Guidance'),
              const SizedBox(height: 8),
              const Text(
                'Define what action items should be identified',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.mediumGrey,
                ),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _actionItemsGuidanceController,
                hint: 'e.g., Follow-up required, escalation needed...',
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Custom Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Custom Fields'),
                  TextButton.icon(
                    onPressed: _addCustomField,
                    icon: const Icon(
                      Icons.add_circle_outline,
                      size: 18,
                      color: AppTheme.primaryGreen,
                    ),
                    label: const Text(
                      'Add Field',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Define custom fields to extract from conversations',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.mediumGrey,
                ),
              ),
              const SizedBox(height: 12),

              if (_customFields.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderGrey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'No custom fields defined',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.mediumGrey,
                      ),
                    ),
                  ),
                )
              else
                ..._customFields.asMap().entries.map((entry) {
                  final index = entry.key;
                  final field = entry.value;
                  return _buildCustomFieldCard(index, field);
                }),

              const SizedBox(height: 32),

              // Save Button
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.borderGrey),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkGrey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveConfig,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Save Config',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.surfaceCard,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppTheme.darkGrey,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 14,
          color: AppTheme.mediumGrey,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.borderGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.borderGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildCustomFieldCard(int index, Map<String, String> field) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderGrey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Field ${index + 1}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkGrey,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
                onPressed: () => _removeCustomField(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: field['name'],
            decoration: const InputDecoration(
              labelText: 'Field Name',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (value) {
              setState(() {
                _customFields[index]['name'] = value;
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: field['type'],
            decoration: const InputDecoration(
              labelText: 'Field Type',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: ['string', 'number', 'boolean', 'array']
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _customFields[index]['type'] = value;
                });
              }
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: field['description'],
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            maxLines: 2,
            onChanged: (value) {
              setState(() {
                _customFields[index]['description'] = value;
              });
            },
          ),
        ],
      ),
    );
  }
}
