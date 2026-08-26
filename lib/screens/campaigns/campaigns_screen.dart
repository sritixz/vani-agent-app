import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vani_app/config/theme.dart';
import 'package:vani_app/data/services/campaigns_api_service.dart';
import 'package:vani_app/models/campaign_model.dart';
import 'package:vani_app/screens/campaigns/campaign_details_screen.dart';
import 'package:vani_app/screens/campaigns/create_campaign_screen.dart';
import 'package:vani_app/screens/campaigns/update_campaign_screen.dart';
import 'package:vani_app/utils/date_time_utils.dart';

// State provider for campaigns
final campaignsProvider = FutureProvider.autoDispose.family<List<Campaign>, CampaignFilters>(
  (ref, filters) async {
    final service = ref.watch(campaignsApiServiceProvider);
    return service.getCampaigns(
      search: filters.search,
      status: filters.status,
      createdFrom: filters.createdFrom,
      createdTill: filters.createdTill,
    );
  },
);

class CampaignFilters {
  final String? search;
  final String? status;
  final String? createdFrom;
  final String? createdTill;

  const CampaignFilters({
    this.search,
    this.status,
    this.createdFrom,
    this.createdTill,
  });

  CampaignFilters copyWith({
    String? search,
    String? status,
    String? createdFrom,
    String? createdTill,
  }) {
    return CampaignFilters(
      search: search ?? this.search,
      status: status ?? this.status,
      createdFrom: createdFrom ?? this.createdFrom,
      createdTill: createdTill ?? this.createdTill,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CampaignFilters &&
          runtimeType == other.runtimeType &&
          search == other.search &&
          status == other.status &&
          createdFrom == other.createdFrom &&
          createdTill == other.createdTill;

  @override
  int get hashCode =>
      search.hashCode ^
      status.hashCode ^
      createdFrom.hashCode ^
      createdTill.hashCode;
}

class CampaignsScreen extends ConsumerStatefulWidget {
  const CampaignsScreen({super.key});

  @override
  ConsumerState<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends ConsumerState<CampaignsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final campaignsAsync = ref.watch(campaignsProvider(const CampaignFilters()));

    return Scaffold(
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Campaigns',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.darkGrey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Manage your outbound voice campaigns',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.mediumGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreateCampaignScreen(),
                          ),
                        ).then((_) {
                          ref.invalidate(campaignsProvider);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(
                        'Start Campaign',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Campaign List
                campaignsAsync.when(
                  data: (campaigns) {
                    if (campaigns.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.borderGrey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.campaign_outlined,
                                size: 48,
                                color: AppTheme.mediumGrey,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No campaigns created yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.darkGrey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Create and launch your first AI call campaign',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.mediumGrey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const CreateCampaignScreen(),
                                    ),
                                  ).then((_) {
                                    ref.invalidate(campaignsProvider);
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text(
                                  'Create Campaign',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: campaigns.length,
                      itemBuilder: (context, index) {
                        final campaign = campaigns[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CampaignCard(
                            campaign: campaign,
                            onRefresh: () {
                              ref.invalidate(campaignsProvider);
                            },
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                  error: (error, stack) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderGrey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Error: ${error.toString()}',
                          style: const TextStyle(color: AppTheme.errorRed),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            ref.invalidate(campaignsProvider);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateCampaignScreen(),
            ),
          ).then((_) {
            ref.invalidate(campaignsProvider);
          });
        },
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Start Campaign',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _CampaignCard extends ConsumerWidget {
  final Campaign campaign;
  final VoidCallback onRefresh;

  const _CampaignCard({
    required this.campaign,
    required this.onRefresh,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppTheme.primaryGreen;
      case 'completed':
        return Colors.blue;
      case 'paused':
        return Colors.orange;
      case 'draft':
        return AppTheme.mediumGrey;
      default:
        return AppTheme.mediumGrey;
    }
  }

  Color _getStatusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppTheme.lightGreen;
      case 'completed':
        return Colors.blue.withOpacity(0.1);
      case 'paused':
        return Colors.orange.withOpacity(0.1);
      case 'draft':
        return AppTheme.borderGrey;
      default:
        return AppTheme.borderGrey;
    }
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final date = DateTime.parse(dateTime);
      // Convert UTC to IST (GMT+5:30)
      final istDate = DateTimeUtils.toIST(date);
      return DateFormat('dd/MM/yyyy, HH:mm:ss').format(istDate);
    } catch (e) {
      return dateTime;
    }
  }

  Future<void> _deleteCampaign(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Campaign'),
        content: Text('Are you sure you want to delete "${campaign.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final service = ref.read(campaignsApiServiceProvider);
        await service.deleteCampaign(campaign.id);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Campaign deleted successfully')),
          );
          onRefresh();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting campaign: $e')),
          );
        }
      }
    }
  }

  Future<void> _editCampaign(BuildContext context) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UpdateCampaignScreen(campaign: campaign),
      ),
    );
    if (result == true) {
      onRefresh();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderGrey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Campaign Name, Integration Badges, and Status Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Monospace ID Hash Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.lightGrey,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.borderGrey),
                ),
                child: Text(
                  campaign.id.length > 12 ? campaign.id.substring(0, 12) : campaign.id,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.mediumGrey,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            campaign.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkGrey,
                            ),
                          ),
                        ),
                        // One-Click Resume / Pause Quick Action Button
                        if (campaign.status.toLowerCase() == 'paused')
                          ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                await ref.read(campaignsApiServiceProvider).resumeCampaign(campaign.id);
                                onRefresh();
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error resuming campaign: $e')),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.lightGreen,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.play_arrow, size: 14, color: AppTheme.primaryGreen),
                            label: const Text('Resume', style: TextStyle(color: AppTheme.primaryGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                          )
                        else if (campaign.status.toLowerCase() == 'active')
                          ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                await ref.read(campaignsApiServiceProvider).pauseCampaign(campaign.id);
                                onRefresh();
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error pausing campaign: $e')),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.withOpacity(0.1),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.pause, size: 14, color: Colors.orange),
                            label: const Text('Pause', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusBackgroundColor(campaign.status),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '● ${campaign.status.toUpperCase()}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(campaign.status),
                            ),
                          ),
                        ),
                        // Integration Source Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.lightGreen,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.table_chart, size: 10, color: AppTheme.primaryGreen),
                              SizedBox(width: 2),
                              Text('GSheet', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                            ],
                          ),
                        ),
                        // Category Pill Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Quick Qualification', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.purple)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Schedule Section
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'START DATE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.mediumGrey,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(campaign.startDateTime),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'END DATE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.mediumGrey,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(campaign.endDateTime),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Agent Name Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AGENT NAME',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.mediumGrey,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.headset_mic,
                    size: 14,
                    color: AppTheme.mediumGrey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      campaign.agentName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.darkGrey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Created Date
          Text(
            'Created: ${_formatDateTime(campaign.createdAt)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppTheme.mediumGrey,
            ),
          ),
          const SizedBox(height: 16),

          // 7-Icon Quick Actions Bar (Web App Alignment)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Sync Icon
                IconButton(
                  tooltip: 'Sync Contacts',
                  onPressed: () async {
                    try {
                      await ref.read(campaignsApiServiceProvider).syncCampaign(campaign.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Contact sync triggered successfully!'), backgroundColor: AppTheme.primaryGreen),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sync failed: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.sync, size: 18, color: AppTheme.primaryGreen),
                ),
                // Report / Analytics Icon
                IconButton(
                  tooltip: 'Analytics Report',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CampaignDetailsScreen(campaignId: campaign.id),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bar_chart, size: 18, color: Colors.blue),
                ),
                // Config Icon
                IconButton(
                  tooltip: 'Execution Parameters',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Retries: ${campaign.retries} · Timezone: ${campaign.timeZone ?? "UTC"}')),
                    );
                  },
                  icon: const Icon(Icons.tune, size: 18, color: AppTheme.darkGrey),
                ),
                // Robot Bot Config Icon
                IconButton(
                  tooltip: 'Robot Automation Config',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Row(
                          children: [
                            Icon(Icons.smart_toy, color: AppTheme.primaryGreen),
                            SizedBox(width: 8),
                            Text('Robot Config', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        content: const Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Automated AI bot is active for this campaign.', style: TextStyle(fontSize: 12)),
                            SizedBox(height: 8),
                            Text('• Sentiment auto-stop: Active\n• Auto Follow-up: Enabled\n• WhatsApp outreach: Active', style: TextStyle(fontSize: 11, color: AppTheme.mediumGrey)),
                          ],
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.smart_toy_outlined, size: 18, color: Colors.purple),
                ),
                // Edit Icon
                IconButton(
                  tooltip: 'Edit Campaign',
                  onPressed: () => _editCampaign(context),
                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.darkGrey),
                ),
                // View Icon
                IconButton(
                  tooltip: 'View Details',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CampaignDetailsScreen(campaignId: campaign.id),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 18, color: AppTheme.darkGrey),
                ),
                // Delete Icon
                IconButton(
                  tooltip: 'Delete Campaign',
                  onPressed: () => _deleteCampaign(context, ref),
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
