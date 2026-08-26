import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vani_app/config/theme.dart';
import 'package:vani_app/data/services/campaigns_api_service.dart';
import 'package:vani_app/data/services/agents_api_service.dart';
import 'package:vani_app/models/campaign_model.dart';
import 'package:vani_app/models/agent_model.dart';

// Provider to fetch agents list
final agentsListProvider = FutureProvider.autoDispose<List<Agent>>((ref) async {
  final service = ref.watch(agentsApiServiceProvider);
  return service.getAgents();
});

class UpdateCampaignScreen extends ConsumerStatefulWidget {
  final Campaign campaign;

  const UpdateCampaignScreen({super.key, required this.campaign});

  @override
  ConsumerState<UpdateCampaignScreen> createState() => _UpdateCampaignScreenState();
}

class _UpdateCampaignScreenState extends ConsumerState<UpdateCampaignScreen> {
  String? _selectedAgentId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedAgentId = widget.campaign.agentId;
  }

  Future<void> _updateCampaign() async {
    if (_selectedAgentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an agent')),
      );
      return;
    }

    if (_selectedAgentId == widget.campaign.agentId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes to update')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(campaignsApiServiceProvider);
      await service.updateCampaign(
        widget.campaign.id,
        {
          'agentId': _selectedAgentId,
          'agent_id': _selectedAgentId,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaign updated successfully')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final agentsAsync = ref.watch(agentsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Campaign'),
        backgroundColor: AppTheme.surfaceCard,
        foregroundColor: AppTheme.darkGrey,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Campaign Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderGrey),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Campaign',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.mediumGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.campaign.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Current Agent: ${widget.campaign.agentName}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Agent Selection
              const Text(
                'Select New Agent',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkGrey,
                ),
              ),
              const SizedBox(height: 12),

              agentsAsync.when(
                data: (agents) {
                  if (agents.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderGrey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'No agents available',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.mediumGrey,
                        ),
                      ),
                    );
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderGrey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedAgentId,
                        isExpanded: true,
                        hint: const Text('Select an agent'),
                        items: agents.map((agent) {
                          return DropdownMenuItem<String>(
                            value: agent.id,
                            child: Text(
                              agent.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedAgentId = value;
                          });
                        },
                      ),
                    ),
                  );
                },
                loading: () => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderGrey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Loading agents...',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.mediumGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                error: (error, stack) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Error loading agents: $error',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Update Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateCampaign,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.surfaceCard,
                          ),
                        )
                      : const Text(
                          'Update Campaign',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
