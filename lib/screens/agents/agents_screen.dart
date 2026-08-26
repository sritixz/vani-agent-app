import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vani_app/config/theme.dart';
import 'package:vani_app/models/agent_model.dart';
import 'package:vani_app/presentation/providers/agents_provider.dart';
import 'package:vani_app/screens/agents/agent_details_screen.dart';
import 'package:vani_app/screens/agents/create_edit_agent_screen.dart';
import 'package:vani_app/screens/agents/agent_simulator_screen.dart';
import 'package:vani_app/screens/agents/browse_templates_screen.dart';
import 'package:vani_app/screens/agents/agent_flow_screen.dart';
import 'package:vani_app/data/services/calls_api_service.dart';

class AgentsScreen extends ConsumerStatefulWidget {
  const AgentsScreen({super.key});

  @override
  ConsumerState<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends ConsumerState<AgentsScreen> {
  @override
  void initState() {
    super.initState();
    // Load agents when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(agentsProvider.notifier).loadAgents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final agentsState = ref.watch(agentsProvider);

    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Agents',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.darkGrey,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Manage active voice agents',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.mediumGrey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BrowseTemplatesScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.borderGrey),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.grid_view_rounded, size: 13, color: AppTheme.darkGrey),
                          label: const Text(
                            'Browse Templates',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.darkGrey),
                          ),
                        ),
                        if (!agentsState.isLoading && agentsState.agents.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.lightGreen,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                            ),
                            child: Text(
                              '${agentsState.agents.length} total',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Loading State
                if (agentsState.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                // Error State
                else if (agentsState.error != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderGrey),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Error: ${agentsState.error}',
                          style: const TextStyle(color: AppTheme.errorRed),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            ref.read(agentsProvider.notifier).loadAgents();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                // Empty State
                else if (agentsState.agents.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderGrey),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.smart_toy_outlined,
                            size: 48,
                            color: AppTheme.mediumGrey,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No agents yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.darkGrey,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Create your first voice agent to get started',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.mediumGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                // Agents List
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: agentsState.agents.length,
                    itemBuilder: (context, index) {
                      final agent = agentsState.agents[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildAgentCard(agent),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateEditAgentScreen(),
            ),
          ).then((_) {
            // Reload agents after returning from create screen
            ref.read(agentsProvider.notifier).loadAgents();
          });
        },
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showDeleteConfirmation(Agent agent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Agent'),
        content: Text(
          'Are you sure you want to delete "${agent.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(agentsProvider.notifier).deleteAgent(agent.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentCard(Agent agent) {
    final agentsState = ref.watch(agentsProvider);
    final phoneNumber = agentsState.getPhoneNumber(agent);

    String getEngineType(Agent agent) => agent.engineType;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row with Name, ID and Status Toggle
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agent.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkGrey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${agent.id}',
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppTheme.mediumGrey,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status switch & text Row
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 0.75,
                    child: Switch(
                      value: agent.isActive,
                      onChanged: (value) {
                        ref
                            .read(agentsProvider.notifier)
                            .toggleAgentStatus(agent.id, value);
                      },
                      activeTrackColor: AppTheme.primaryGreen,
                      activeColor: Colors.white,
                    ),
                  ),
                  Text(
                    agent.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: agent.isActive
                          ? AppTheme.primaryGreen
                          : AppTheme.mediumGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),

          Container(
            height: 1,
            color: AppTheme.borderGrey,
            margin: const EdgeInsets.symmetric(vertical: 12),
          ),

          // Details Grid: Phone, Voice, Type
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PHONE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.mediumGrey,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      phoneNumber,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.darkGrey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'VOICE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.mediumGrey,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      agent.voice,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.darkGrey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TYPE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.mediumGrey,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      getEngineType(agent),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.darkGrey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action Buttons Row: Test, Simulate, Flow, Edit, Delete
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Test Action Button
                InkWell(
                  onTap: () => _showQuickTestCallDialog(agent),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.phone_in_talk, size: 13, color: AppTheme.primaryGreen),
                        SizedBox(width: 4),
                        Text('Test', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Simulate Button (Vani Ultra / Ultra Realtime)
                if (getEngineType(agent) == 'Vani Ultra' || getEngineType(agent) == 'Ultra Realtime') ...[
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AgentSimulatorScreen(agent: agent),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        border: Border.all(color: Colors.purple.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.bolt_outlined, size: 13, color: Colors.purple),
                          SizedBox(width: 4),
                          Text('Simulate', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],

                // Flow Action Button
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AgentFlowScreen(agent: agent),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade800.withOpacity(0.1),
                      border: Border.all(color: Colors.amber.shade800.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.account_tree_outlined, size: 13, color: Colors.amber.shade800),
                        const SizedBox(width: 4),
                        Text('Flow', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade800)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Edit Button
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateEditAgentScreen(agent: agent),
                      ),
                    ).then((_) {
                      ref.read(agentsProvider.notifier).loadAgents();
                    });
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 13, color: Colors.blue),
                        SizedBox(width: 4),
                        Text('Edit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Delete Button
                InkWell(
                  onTap: () => _showDeleteConfirmation(agent),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withOpacity(0.1),
                      border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.delete_outline, size: 13, color: AppTheme.errorRed),
                        SizedBox(width: 4),
                        Text('Delete', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.errorRed)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickTestCallDialog(Agent agent) {
    final phoneController = TextEditingController();
    bool isTesting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppTheme.borderGrey),
              ),
              title: Row(
                children: [
                  const Icon(Icons.phone_in_talk, color: AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Test Agent: ${agent.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Launch an instant test call session to evaluate agent greeting, prompt responses, and voice quality.',
                    style: TextStyle(fontSize: 12, color: AppTheme.mediumGrey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Test Phone Number',
                      hintText: '+919876543210',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  if (isTesting) ...[
                    const SizedBox(height: 16),
                    const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: AppTheme.primaryGreen),
                          SizedBox(height: 8),
                          Text('Initiating test call...', style: TextStyle(fontSize: 12, color: AppTheme.mediumGrey)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isTesting ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.mediumGrey)),
                ),
                ElevatedButton(
                  onPressed: isTesting
                      ? null
                      : () async {
                          final phone = phoneController.text.trim();
                          if (phone.isEmpty) return;
                          setDialogState(() => isTesting = true);
                          try {
                            await ref.read(callsApiServiceProvider).validateCall({
                              'phone_number': phone,
                              'agent_id': agent.id,
                              'call_type': 'outbound',
                              'test_mode': true,
                            });
                            if (context.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Test call for ${agent.name} initiated successfully!'),
                                  backgroundColor: AppTheme.primaryGreen,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isTesting = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to trigger test call: $e'),
                                  backgroundColor: AppTheme.errorRed,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Text('Start Test Call', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
