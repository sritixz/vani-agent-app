import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vani_app/config/theme.dart';
import 'package:vani_app/data/services/campaigns_api_service.dart';
import 'package:vani_app/presentation/providers/agents_provider.dart';
import 'package:vani_app/presentation/providers/phone_numbers_provider.dart';
import 'package:vani_app/models/campaign_model.dart';

class UpdateCampaignScreen extends ConsumerStatefulWidget {
  final Campaign campaign;

  const UpdateCampaignScreen({super.key, required this.campaign});

  @override
  ConsumerState<UpdateCampaignScreen> createState() => _UpdateCampaignScreenState();
}

class _UpdateCampaignScreenState extends ConsumerState<UpdateCampaignScreen> {
  String? _selectedPrimaryAgentId;
  final Set<String> _selectedAdditionalAgentIds = {};
  String _agentStrategy = 'round_robin';
  String _numberStrategy = 'smart';
  final Set<String> _selectedOutboundNumberIds = {};
  bool _isLoading = false;

  final List<Map<String, String>> _agentStrategies = [
    {'value': 'round_robin', 'label': 'Round robin'},
    {'value': 'sticky_per_contact', 'label': 'Sticky per contact'},
  ];

  final List<Map<String, String>> _numberStrategies = [
    {'value': 'smart', 'label': 'Smart (avoid failed numbers)'},
    {'value': 'round_robin', 'label': 'Round Robin'},
    {'value': 'sequential', 'label': 'Sequential'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedPrimaryAgentId = widget.campaign.agentId;
    _numberStrategy = widget.campaign.numberRotationStrategy.isNotEmpty 
        ? widget.campaign.numberRotationStrategy 
        : 'smart';
  }

  Future<void> _updateCampaign() async {
    if (_selectedPrimaryAgentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a primary voice agent')),
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
          'agentId': _selectedPrimaryAgentId,
          'agent_id': _selectedPrimaryAgentId,
          'additional_agent_ids': _selectedAdditionalAgentIds.toList(),
          'agent_strategy': _agentStrategy,
          'number_rotation_strategy': _numberStrategy,
          'numberRotationStrategy': _numberStrategy,
          'phone_number_ids': _selectedOutboundNumberIds.toList(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Campaign updated successfully'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating campaign: $e'), backgroundColor: AppTheme.errorRed),
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
    final agentsState = ref.watch(agentsProvider);
    final phoneNumbersState = ref.watch(phoneNumbersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Campaign'),
        backgroundColor: AppTheme.surfaceCard,
        foregroundColor: AppTheme.darkGrey,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Campaign Header Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderGrey),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.campaign.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Campaign ID: ${widget.campaign.id}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.mediumGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 1. Select Voice Agent (Primary)
              const Text(
                'Select Voice Agent',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkGrey,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedPrimaryAgentId,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                hint: const Text('Select Voice Agent'),
                items: agentsState.agents.map((ag) {
                  return DropdownMenuItem<String>(
                    value: ag.id,
                    child: Text(
                      ag.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedPrimaryAgentId = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // 2. Agent and Number Rotation Box Container (Website Pixel-Perfect Alignment)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderGrey),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Agent and Number Rotation',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'The primary agent is always first and remains the single-agent fail-safe. Every call stores the actual agent, agent configuration version, and outbound number used.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.mediumGrey,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Additional Agents Picker
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Additional agents · ${_selectedAdditionalAgentIds.length} selected',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      hint: const Text('Select additional agents for rotation'),
                      items: agentsState.agents
                          .where((a) => a.id != _selectedPrimaryAgentId)
                          .map((ag) {
                        final isSelected = _selectedAdditionalAgentIds.contains(ag.id);
                        return DropdownMenuItem<String>(
                          value: ag.id,
                          child: Row(
                            children: [
                              Checkbox(
                                value: isSelected,
                                activeColor: AppTheme.primaryGreen,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedAdditionalAgentIds.add(ag.id);
                                    } else {
                                      _selectedAdditionalAgentIds.remove(ag.id);
                                    }
                                  });
                                },
                              ),
                              Expanded(
                                child: Text(
                                  ag.name,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            if (_selectedAdditionalAgentIds.contains(val)) {
                              _selectedAdditionalAgentIds.remove(val);
                            } else {
                              _selectedAdditionalAgentIds.add(val);
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Agent Strategy & Number Strategy Row
                    Row(
                      children: [
                        // Agent Strategy
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Agent strategy',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.darkGrey,
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _agentStrategy,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                                items: _agentStrategies.map((st) {
                                  return DropdownMenuItem<String>(
                                    value: st['value'],
                                    child: Text(
                                      st['label']!,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _agentStrategy = val;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Number Strategy
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Number strategy',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.darkGrey,
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _numberStrategies.any((s) => s['value'] == _numberStrategy)
                                    ? _numberStrategy
                                    : 'smart',
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                                items: _numberStrategies.map((st) {
                                  return DropdownMenuItem<String>(
                                    value: st['value'],
                                    child: Text(
                                      st['label']!,
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _numberStrategy = val;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Outbound Number Pool Picker
                    const Text(
                      'Outbound number pool',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Outbound numbers · ${_selectedOutboundNumberIds.length} selected',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      hint: const Text('Select outbound phone numbers'),
                      items: phoneNumbersState.phoneNumbers.map((num) {
                        final isSelected = _selectedOutboundNumberIds.contains(num.id);
                        return DropdownMenuItem<String>(
                          value: num.id,
                          child: Row(
                            children: [
                              Checkbox(
                                value: isSelected,
                                activeColor: AppTheme.primaryGreen,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedOutboundNumberIds.add(num.id);
                                    } else {
                                      _selectedOutboundNumberIds.remove(num.id);
                                    }
                                  });
                                },
                              ),
                              Expanded(
                                child: Text(
                                  '${num.phoneNumber} (${num.provider})',
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            if (_selectedOutboundNumberIds.contains(val)) {
                              _selectedOutboundNumberIds.remove(val);
                            } else {
                              _selectedOutboundNumberIds.add(val);
                            }
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons: Cancel & Update Campaign
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.borderGrey),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.darkGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _updateCampaign,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Update Campaign',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
