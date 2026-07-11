import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vani_app/config/theme.dart';
import 'package:vani_app/data/services/campaigns_api_service.dart';
import 'package:vani_app/models/campaign_model.dart';
import 'package:vani_app/models/campaign_number_model.dart';
import 'package:vani_app/utils/date_time_utils.dart';

final campaignDetailsProvider = FutureProvider.autoDispose.family<Campaign, String>(
  (ref, campaignId) async {
    final service = ref.watch(campaignsApiServiceProvider);
    return service.getCampaign(campaignId);
  },
);

final campaignNumbersProvider = FutureProvider.autoDispose.family<List<CampaignNumber>, CampaignNumbersParams>(
  (ref, params) async {
    final service = ref.watch(campaignsApiServiceProvider);
    return service.getCampaignNumbers(
      params.campaignId,
      filter: params.filter,
      sentiment: params.sentiment,
    );
  },
);

final gsheetHeadersProvider = FutureProvider.autoDispose.family<List<String>, String>(
  (ref, campaignId) async {
    final service = ref.watch(campaignsApiServiceProvider);
    return service.getGsheetHeaders(campaignId);
  },
);

class CampaignNumbersParams {
  final String campaignId;
  final String? filter;
  final String? sentiment;

  const CampaignNumbersParams({
    required this.campaignId,
    this.filter,
    this.sentiment,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CampaignNumbersParams &&
          runtimeType == other.runtimeType &&
          campaignId == other.campaignId &&
          filter == other.filter &&
          sentiment == other.sentiment;

  @override
  int get hashCode => campaignId.hashCode ^ filter.hashCode ^ sentiment.hashCode;
}

class CampaignDetailsScreen extends ConsumerStatefulWidget {
  final String campaignId;

  const CampaignDetailsScreen({super.key, required this.campaignId});

  @override
  ConsumerState<CampaignDetailsScreen> createState() => _CampaignDetailsScreenState();
}

class _CampaignDetailsScreenState extends ConsumerState<CampaignDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedFilter;
  String? _selectedSentiment;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Color _getSentimentColor(String? sentiment) {
    if (sentiment == null) return AppTheme.mediumGrey;
    switch (sentiment.toLowerCase()) {
      case 'positive':
        return Colors.green;
      case 'negative':
        return Colors.red;
      case 'neutral':
        return Colors.orange;
      default:
        return AppTheme.mediumGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final campaignAsync = ref.watch(campaignDetailsProvider(widget.campaignId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campaign Details'),
        backgroundColor: AppTheme.surfaceCard,
        foregroundColor: AppTheme.darkGrey,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.mediumGrey,
          indicatorColor: AppTheme.primaryGreen,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Numbers'),
            Tab(text: 'Sheet Headers'),
          ],
        ),
      ),
      body: campaignAsync.when(
        data: (campaign) => TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(campaign),
            _buildNumbersTab(campaign),
            _buildGsheetHeadersTab(campaign),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryGreen,
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Error loading campaign details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.darkGrey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.mediumGrey,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(campaignDetailsProvider);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(Campaign campaign) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Campaign Name and Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  campaign.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkGrey,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusBackgroundColor(campaign.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  campaign.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _getStatusColor(campaign.status),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'ID: ${campaign.id}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppTheme.mediumGrey,
            ),
          ),
          const SizedBox(height: 24),

          // Basic Information
          _SectionCard(
            title: 'BASIC INFORMATION',
            children: [
              _DetailRow(label: 'Agent Name', value: campaign.agentName),
              _DetailRow(label: 'Agent ID', value: campaign.agentId),
              _DetailRow(label: 'Retries', value: campaign.retries.toString()),
              _DetailRow(label: 'Max Concurrent Calls', value: campaign.maxConcurrentCalls.toString()),
              if (campaign.customFirstLine != null)
                _DetailRow(label: 'Custom First Line', value: campaign.customFirstLine!),
            ],
          ),
          const SizedBox(height: 16),

          // Schedule Information
          _SectionCard(
            title: 'SCHEDULE',
            children: [
              _DetailRow(label: 'Start Date & Time', value: _formatDateTime(campaign.startDateTime)),
              _DetailRow(label: 'End Date & Time', value: _formatDateTime(campaign.endDateTime)),
              _DetailRow(label: 'Time Zone', value: campaign.timeZone ?? 'N/A'),
              if (campaign.activatedAt != null)
                _DetailRow(label: 'Activated At', value: _formatDateTime(campaign.activatedAt)),
            ],
          ),
          const SizedBox(height: 16),

          // Contact Information
          _SectionCard(
            title: 'CONTACT INFORMATION',
            children: [
              _DetailRow(label: 'Contact Source', value: campaign.contactSource),
              if (campaign.contactFileName != null)
                _DetailRow(label: 'Contact File', value: campaign.contactFileName!),
              if (campaign.gsheetUrl != null)
                _DetailRow(label: 'Google Sheet URL', value: campaign.gsheetUrl!),
            ],
          ),
          const SizedBox(height: 16),

          // Campaign Settings
          _SectionCard(
            title: 'CAMPAIGN SETTINGS',
            children: [
              _DetailRow(label: 'Campaign Type', value: campaign.campaignType),
              _DetailRow(label: 'Number Rotation Strategy', value: campaign.numberRotationStrategy),
              _DetailRow(label: 'Call Window Start', value: campaign.callWindowStart.toString()),
              _DetailRow(label: 'Call Window End', value: campaign.callWindowEnd.toString()),
              _DetailRow(label: 'No Answer Cooldown (min)', value: campaign.noAnswerCooldownMinutes.toString()),
              _DetailRow(label: 'Max Attempts Per Day', value: campaign.maxAttemptsPerDay.toString()),
              _DetailRow(label: 'Max Campaign Days', value: campaign.maxCampaignDays.toString()),
              _DetailRow(label: 'Max Qualification Rounds', value: campaign.maxQualificationRounds.toString()),
            ],
          ),
          const SizedBox(height: 16),

          // Automation Settings
          _SectionCard(
            title: 'AUTOMATION',
            children: [
              _DetailRow(label: 'Auto Followup', value: campaign.autoFollowupEnabled ? 'Enabled' : 'Disabled'),
              if (campaign.autoFollowupEnabled && campaign.autoFollowupTriggerType != null)
                _DetailRow(label: 'Followup Trigger', value: campaign.autoFollowupTriggerType!),
              _DetailRow(label: 'SMS Automation', value: campaign.smsAutomationEnabled ? 'Enabled' : 'Disabled'),
              _DetailRow(label: 'WhatsApp Automation', value: campaign.whatsappAutomationEnabled ? 'Enabled' : 'Disabled'),
            ],
          ),
          const SizedBox(height: 16),

          // Timestamps
          _SectionCard(
            title: 'TIMESTAMPS',
            children: [
              _DetailRow(label: 'Created At', value: _formatDateTime(campaign.createdAt)),
              _DetailRow(label: 'Updated At', value: _formatDateTime(campaign.updatedAt)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumbersTab(Campaign campaign) {
    return Column(
      children: [
        // Filters
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            border: Border(
              bottom: BorderSide(color: AppTheme.borderGrey),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkGrey,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderGrey),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedFilter,
                          isExpanded: true,
                          hint: const Text('Status Filter'),
                          dropdownColor: Colors.white,
                          items: const [
                            DropdownMenuItem(value: null, child: Text('All')),
                            DropdownMenuItem(value: 'eligible', child: Text('Eligible')),
                            DropdownMenuItem(value: 'blocked', child: Text('Blocked')),
                            DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                            DropdownMenuItem(value: 'unresolved', child: Text('Unresolved')),
                            DropdownMenuItem(value: 'whatsapp_pending', child: Text('WhatsApp Pending')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedFilter = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderGrey),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSentiment,
                          isExpanded: true,
                          hint: const Text('Sentiment'),
                          dropdownColor: Colors.white,
                          items: const [
                            DropdownMenuItem(value: null, child: Text('All')),
                            DropdownMenuItem(value: 'positive', child: Text('Positive')),
                            DropdownMenuItem(value: 'negative', child: Text('Negative')),
                            DropdownMenuItem(value: 'neutral', child: Text('Neutral')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedSentiment = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Numbers List
        Expanded(
          child: _buildNumbersList(),
        ),
      ],
    );
  }

  Widget _buildNumbersList() {
    final params = CampaignNumbersParams(
      campaignId: widget.campaignId,
      filter: _selectedFilter,
      sentiment: _selectedSentiment,
    );
    final numbersAsync = ref.watch(campaignNumbersProvider(params));

    return numbersAsync.when(
      data: (numbers) {
        if (numbers.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.phone_disabled,
                  size: 64,
                  color: AppTheme.mediumGrey,
                ),
                SizedBox(height: 16),
                Text(
                  'No numbers found',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.mediumGrey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: numbers.length,
          itemBuilder: (context, index) {
            final number = numbers[index];
            return _NumberCard(
              number: number,
              formatDateTime: _formatDateTime,
              getSentimentColor: _getSentimentColor,
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryGreen,
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error loading numbers',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.darkGrey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.mediumGrey,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(campaignNumbersProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGsheetHeadersTab(Campaign campaign) {
    // Check if campaign uses Google Sheets
    if (campaign.contactSource != 'gsheet' && campaign.gsheetUrl == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_chart_outlined,
              size: 64,
              color: AppTheme.mediumGrey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Google Sheet Connected',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.mediumGrey,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'This campaign is not using Google Sheets as a contact source',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.mediumGrey,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final headersAsync = ref.watch(gsheetHeadersProvider(widget.campaignId));

    return headersAsync.when(
      data: (headers) {
        if (headers.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.table_chart_outlined,
                  size: 64,
                  color: AppTheme.mediumGrey,
                ),
                SizedBox(height: 16),
                Text(
                  'No headers found',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.mediumGrey,
                  ),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'The Google Sheet may be empty or not properly configured',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.mediumGrey,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                  const Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: AppTheme.primaryGreen),
                      SizedBox(width: 8),
                      Text(
                        'Google Sheet Headers',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'These are the column headers from your Google Sheet that can be used for column remapping.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${headers.length} column${headers.length != 1 ? 's' : ''} found',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.mediumGrey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...headers.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final headerName = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderGrey),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '$index',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        headerName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.darkGrey,
                        ),
                      ),
                    ),
                    const Icon(Icons.drag_handle, size: 18, color: AppTheme.mediumGrey),
                  ],
                ),
              );
            }),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryGreen,
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Error loading sheet headers',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.darkGrey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.mediumGrey,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(gsheetHeadersProvider);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.mediumGrey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.darkGrey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppTheme.darkGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberCard extends StatelessWidget {
  final CampaignNumber number;
  final String Function(String?) formatDateTime;
  final Color Function(String?) getSentimentColor;

  const _NumberCard({
    required this.number,
    required this.formatDateTime,
    required this.getSentimentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      number.contactName ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkGrey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      number.phoneNumber,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.mediumGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (number.sentiment != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: getSentimentColor(number.sentiment).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    number.sentiment!.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: getSentimentColor(number.sentiment),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(label: 'Status', value: number.status),
              _InfoChip(label: 'Attempts', value: number.attempts.toString()),
              _InfoChip(label: 'Resolved', value: number.resolved ? 'Yes' : 'No'),
              if (number.whatsappSent)
                const _InfoChip(label: 'WhatsApp', value: 'Sent'),
              _InfoChip(label: 'Daily Calls', value: number.dailyCallCount.toString()),
              _InfoChip(label: 'Rounds', value: number.qualificationRounds.toString()),
            ],
          ),
          if (number.blocker != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.block, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Blocker: ${number.blocker}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (number.lastCallAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Last Call: ${formatDateTime(number.lastCallAt)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.mediumGrey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.borderGrey,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppTheme.darkGrey,
        ),
      ),
    );
  }
}
