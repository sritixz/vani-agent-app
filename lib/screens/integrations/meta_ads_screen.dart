import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vani_app/config/theme.dart';
import 'package:vani_app/presentation/providers/integrations_provider.dart';
import 'package:vani_app/presentation/providers/meta_ads_provider.dart';
import 'package:vani_app/screens/integrations/create_meta_screen.dart';
import 'package:vani_app/utils/number_formatter.dart';

class MetaAdsScreen extends ConsumerStatefulWidget {
  const MetaAdsScreen({super.key});

  @override
  ConsumerState<MetaAdsScreen> createState() => _MetaAdsScreenState();
}

class _MetaAdsScreenState extends ConsumerState<MetaAdsScreen> {
  bool _isCheckingConnection = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkConnectionAndLoadData();
    });
  }

  Future<void> _checkConnectionAndLoadData() async {
    // First check if Meta connection exists
    await ref.read(integrationsProvider.notifier).loadMetaConnections();
    
    final integrationsState = ref.read(integrationsProvider);
    
    if (integrationsState.hasMetaConnection) {
      // Has connection, load account overview and campaigns
      await ref.read(metaAdsProvider.notifier).loadAccountOverview();
    }
    
    // Always show the Meta Ads screen (with connection prompt if no connection)
    setState(() {
      _isCheckingConnection = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final metaAdsState = ref.watch(metaAdsProvider);

    // Show loading while checking connection
    if (_isCheckingConnection) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Loading Meta Ads...',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.mediumGrey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                      color: AppTheme.darkGrey,
                    ),
                    const Text(
                      'Meta Ads',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        ref.read(metaAdsProvider.notifier).loadAccountOverview();
                      },
                      color: AppTheme.mediumGrey,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create and manage Meta ad campaigns that generate phone leads for your AI agents.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.mediumGrey,
                  ),
                ),
                const SizedBox(height: 24),

                // Error Message
                if (metaAdsState.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.errorRed),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.errorRed,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            metaAdsState.error!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.errorRed,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            ref.read(metaAdsProvider.notifier).clearError();
                          },
                          color: AppTheme.errorRed,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Account Overview or Connection Prompt
                if (metaAdsState.accountOverview != null)
                  _buildAccountOverview(metaAdsState.accountOverview!)
                else if (metaAdsState.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  _buildMetaAdsContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaAdsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step 1 - Connect Meta Account
        const Text(
          'Step 1 — Connect Meta Account',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkGrey,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sign in with Facebook to grant secure access. No passwords stored.',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.mediumGrey,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderGrey),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.facebook,
                size: 48,
                color: Color(0xFF1877F2),
              ),
              const SizedBox(height: 16),
              const Text(
                'Connect your Meta account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkGrey,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Securely connect via Facebook Login. We request ads management, leads retrieval, pages, and WhatsApp Business permissions.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.mediumGrey,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to Create Meta Screen for Facebook OAuth
                    _navigateToCreateMeta();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1877F2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.facebook, color: Colors.white),
                  label: const Text(
                    'Continue with Facebook',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.surfaceCard,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You\'ll be redirected to Facebook to approve access. No passwords stored.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.mediumGrey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountOverview(dynamic accountOverview) {
    final account = accountOverview.account;
    final campaigns = accountOverview.campaigns;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Account Info Card
        if (account != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderGrey),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet,
                      color: AppTheme.primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Account Overview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Balance',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.mediumGrey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            NumberFormatter.formatCurrency(
                              account.balance ?? '0',
                              currency: account.currency == 'INR' ? '₹' : (account.currency ?? ''),
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
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
                            'Amount Spent',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.mediumGrey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            NumberFormatter.formatCurrency(
                              account.amountSpent ?? '0',
                              currency: account.currency == 'INR' ? '₹' : (account.currency ?? ''),
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.darkGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Campaigns Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Campaigns',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkGrey,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Navigate to create campaign screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Campaign builder coming soon!'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add, color: AppTheme.surfaceCard, size: 18),
              label: const Text(
                'Create Campaign',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.surfaceCard,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Campaigns List
        if (campaigns.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderGrey),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.campaign_outlined,
                  size: 48,
                  color: AppTheme.mediumGrey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No campaigns yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGrey,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create your first campaign to start generating leads',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.mediumGrey,
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: campaigns.map<Widget>((campaign) {
              return _buildCampaignCard(campaign);
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildCampaignCard(dynamic campaign) {
    final insights = campaign.insights;
    final status = campaign.status?.toString().toUpperCase() ?? 'UNKNOWN';
    final isActive = status == 'ACTIVE';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderGrey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0x1A10B981)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.campaign,
                  color: isActive ? AppTheme.primaryGreen : AppTheme.mediumGrey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign.name ?? 'Unnamed Campaign',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0x1A10B981)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? AppTheme.successGreen
                                  : AppTheme.mediumGrey,
                            ),
                          ),
                        ),
                        if (campaign.objective != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            campaign.objective.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.mediumGrey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppTheme.mediumGrey),
                onSelected: (value) {
                  if (value == 'pause' || value == 'resume') {
                    final newStatus = value == 'pause' ? 'PAUSED' : 'ACTIVE';
                    ref
                        .read(metaAdsProvider.notifier)
                        .updateCampaignStatus(campaign.id, newStatus);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: isActive ? 'pause' : 'resume',
                    child: Row(
                      children: [
                        Icon(
                          isActive ? Icons.pause : Icons.play_arrow,
                          size: 18,
                          color: AppTheme.darkGrey,
                        ),
                        const SizedBox(width: 8),
                        Text(isActive ? 'Pause' : 'Resume'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Always show metrics section (even if null)
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.borderGrey),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricColumn(
                  'Spend',
                  insights?.spend != null 
                      ? NumberFormatter.formatIndian(insights!.spend)
                      : '0',
                ),
              ),
              Expanded(
                child: _buildMetricColumn(
                  'Impressions',
                  insights?.impressions != null
                      ? NumberFormatter.formatIndian(insights!.impressions)
                      : '0',
                ),
              ),
              Expanded(
                child: _buildMetricColumn(
                  'Clicks',
                  insights?.clicks != null
                      ? NumberFormatter.formatIndian(insights!.clicks)
                      : '0',
                ),
              ),
              Expanded(
                child: _buildMetricColumn(
                  'Leads',
                  insights?.leads != null
                      ? NumberFormatter.formatIndian(insights!.leads)
                      : '0',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.mediumGrey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkGrey,
          ),
        ),
      ],
    );
  }

  void _navigateToCreateMeta() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateMetaScreen(),
      ),
    );

    if (result == true) {
      // Reload Meta connections and account overview after setup
      await ref.read(integrationsProvider.notifier).loadMetaConnections();
      await ref.read(metaAdsProvider.notifier).loadAccountOverview();
    }
  }
}
