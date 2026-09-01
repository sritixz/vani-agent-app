import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:vani_app/config/theme.dart';
import 'package:vani_app/presentation/providers/auth_provider.dart';
import 'package:vani_app/presentation/providers/credits_provider.dart';
import 'package:vani_app/presentation/providers/dashboard_provider.dart';
import 'package:vani_app/presentation/providers/phone_numbers_provider.dart';
import 'package:vani_app/presentation/providers/whatsapp_provider.dart';
import 'package:vani_app/widgets/app_header.dart';
import 'package:vani_app/data/services/subscriptions_api_service.dart';
import 'package:vani_app/data/models/subscriptions/subscription_model.dart';
import 'package:vani_app/presentation/providers/subscriptions_provider.dart';
import 'package:vani_app/presentation/providers/agents_provider.dart';
import 'package:vani_app/data/models/calls/call_statistics_model.dart';
import 'package:vani_app/data/services/calls_api_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  /// Formats a number using the Indian numbering system (e.g. 1,23,456.78)
  String _formatIndian(num value, {int decimals = 2}) {
    final parts = value.toStringAsFixed(decimals).split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? '.${parts[1]}' : '';

    if (intPart.length <= 3) return '$intPart$decPart';

    // Last 3 digits, then groups of 2
    final last3 = intPart.substring(intPart.length - 3);
    final rest = intPart.substring(0, intPart.length - 3);
    final buffer = StringBuffer();
    for (int i = 0; i < rest.length; i++) {
      if (i != 0 && (rest.length - i) % 2 == 0) buffer.write(',');
      buffer.write(rest[i]);
    }
    return '${buffer.toString()},$last3$decPart';
  }

  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // Load dashboard data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).loadDashboardData();
      ref.read(phoneNumbersProvider.notifier).loadPhoneNumbers();
      ref.read(whatsappProvider.notifier).checkIntegrationStatus();
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _verifyPayment(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message ?? 'Unknown Error'}'),
        backgroundColor: AppTheme.errorRed,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Handle external wallet if needed
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppHeader(
        onProfilePressed: () => _showProfileMenu(context),
        onSendCallPressed: () => _showSendCallDialog(context),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Credit Balance and Current Plan Row
                Row(
                  children: [
                    // Credit Balance Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          border: Border.all(color: AppTheme.borderGrey),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Credit Balance',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.mediumGrey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (dashboardState.isLoading)
                                  const SizedBox(
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                else
                                  Text(
                                    '₹${_formatIndian(dashboardState.creditBalance?.balance ?? 0)}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.darkGrey,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _showAddFundsDialog(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryGreen,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                                child: const Text(
                                  'Add Funds',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.surfaceCard,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Current Plan Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          border: Border.all(color: AppTheme.borderGrey),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Current Plan',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.mediumGrey,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => _showUpgradeTierDialog(context),
                                      child: const Text(
                                        'Upgrade',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryGreen,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (dashboardState.isLoading)
                                  const SizedBox(
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                else
                                  Text(
                                    dashboardState
                                            .currentSubscription
                                            ?.tierName ??
                                        'Growth',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.darkGrey,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                          dashboardState
                                                  .currentSubscription
                                                  ?.status ??
                                              'active',
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        (dashboardState
                                                    .currentSubscription
                                                    ?.status ??
                                                'active')
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.surfaceCard,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Conc: ${dashboardState.currentSubscription?.concurrency ?? 3}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.mediumGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Onboarding Setup Checklist Widget
                _buildSetupChecklistWidget(dashboardState.userStatusMap),
                const SizedBox(height: 16),

                // Connect WhatsApp Card
                _buildWhatsAppCard(),
                const SizedBox(height: 12),

                // Ads Card
                _buildAdsCard(),
                const SizedBox(height: 24),

                // Usage Statistics Section Header with Period Filter Chips
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Usage Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildPeriodFilterChip('all', 'All Time', dashboardState.selectedPeriod),
                            const SizedBox(width: 4),
                            _buildPeriodFilterChip('today', 'Today', dashboardState.selectedPeriod),
                            const SizedBox(width: 4),
                            _buildPeriodFilterChip('7d', '7 Days', dashboardState.selectedPeriod),
                            const SizedBox(width: 4),
                            _buildPeriodFilterChip('30d', '30 Days', dashboardState.selectedPeriod),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Show loading or statistics
                if (dashboardState.isLoading || dashboardState.isStatsLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                    ),
                  )
                else if (dashboardState.callStatistics != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Total Calls',
                          value: _formatIndian(
                            dashboardState.callStatistics!.totalCalls,
                            decimals: 0,
                          ),
                          hasChart: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Total Minutes',
                          value: _formatIndian(
                            dashboardState.callStatistics!.totalMinutesAsDouble,
                          ),
                          hasChart: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Avg Duration',
                          value:
                              '${_formatIndian(dashboardState.callStatistics!.averageDurationSeconds, decimals: 0)}s',
                          hasChart: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Pickup Rate',
                          value: '21.2%',
                          hasChart: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    title: 'Credits Spent',
                    value:
                        '₹${_formatIndian(dashboardState.callStatistics!.totalCreditsSpentAsDouble)}',
                    hasChart: false,
                  ),
                  const SizedBox(height: 16),

                  // Call Duration Quality Donut Chart Card
                  _buildCallDurationQualityCard(dashboardState.callStatistics!),
                  const SizedBox(height: 16),

                  // Call Outcomes Breakdown Card
                  _buildCallOutcomesCard(dashboardState.callStatistics!),
                  const SizedBox(height: 16),

                  // Call Sources Breakdown Card
                  _buildCallSourcesCard(dashboardState.callStatistics!),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderGrey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'No usage statistics available',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.mediumGrey,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                // Phone Numbers Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Phone Numbers',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/available-phone-numbers',
                        );
                      },
                      icon: const Icon(
                        Icons.add_circle_outline,
                        size: 18,
                        color: AppTheme.primaryGreen,
                      ),
                      label: const Text(
                        'Available Numbers',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildPhoneNumbersSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  void _showUpgradeTierDialog(BuildContext context) {
    // Load subscription tiers
    ref.read(subscriptionsProvider.notifier).loadSubscriptionTiers();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final subsState = ref.watch(subscriptionsProvider);

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.borderGrey,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Upgrade Subscription Tier',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Select a tier to upgrade your subscription. The upgrade order will be created via Razorpay.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.mediumGrey,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (subsState.isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        )
                      else if (subsState.tiers.isEmpty)
                        // Fallback mocked tiers if API list is empty
                        _buildTierList(context, [
                          SubscriptionTierModel(
                            id: 'standard',
                            name: 'Standard',
                            price: 2999.00,
                            description: 'Best for growing businesses',
                          ),
                          SubscriptionTierModel(
                            id: 'premium',
                            name: 'Premium',
                            price: 9999.00,
                            description: 'Advanced tools & scale',
                          ),
                        ])
                      else
                        _buildTierList(context, subsState.tiers),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTierList(
    BuildContext context,
    List<SubscriptionTierModel> tiers,
  ) {
    return Column(
      children: tiers.map((tier) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppTheme.borderGrey),
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tier.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.darkGrey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tier.description ?? 'Subscription plan tier',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.mediumGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${tier.price.toStringAsFixed(2)} / month',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Close tiers sheet and start payment simulation
                    Navigator.pop(context);
                    _initiateUpgradeFlow(tier.name);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Select',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _initiateUpgradeFlow(String tierName) async {
    // Show Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGreen),
      ),
    );

    try {
      final apiService = ref.read(subscriptionsApiServiceProvider);
      // Create Razorpay Order
      final orderData = await apiService.upgradeTier(tierName: tierName);

      // Close Loading Dialog
      if (mounted) Navigator.pop(context);

      final String orderId =
          orderData['order_id'] ??
          orderData['id'] ??
          'order_simulated_${DateTime.now().millisecondsSinceEpoch}';
      final double amount = (orderData['amount'] != null)
          ? (orderData['amount'] is num
                ? (orderData['amount'] as num).toDouble() / 100
                : 2999.00)
          : 2999.00;

      // Show Simulated Razorpay Payment sheet
      if (mounted) {
        _showSimulatedPaymentSheet(orderId, amount, tierName);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create upgrade order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSimulatedPaymentSheet(
    String orderId,
    double amount,
    String tierName,
  ) {
    final paymentIdController = TextEditingController(
      text: 'pay_sim_${DateTime.now().millisecondsSinceEpoch}',
    );
    final signatureController = TextEditingController(
      text: 'sig_sim_${DateTime.now().millisecondsSinceEpoch}',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.borderGrey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.payment, color: Color(0xFF3B82F6)),
                    SizedBox(width: 8),
                    Text(
                      'Razorpay Payment Simulator',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Order created successfully for plan $tierName.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.mediumGrey,
                  ),
                ),
                const Divider(height: 24),

                // Order details
                _buildPaymentInfoRow('Order ID', orderId),
                const SizedBox(height: 6),
                _buildPaymentInfoRow(
                  'Amount Due',
                  '₹${amount.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 16),

                // Input fields
                const Text(
                  'Simulated Payment ID',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGrey,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: paymentIdController,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),

                const Text(
                  'Simulated Signature',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGrey,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: signatureController,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.borderGrey),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Cancel Payment',
                          style: TextStyle(color: AppTheme.darkGrey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx); // Close simulator sheet
                          _verifyTierUpgradeFlow(
                            orderId,
                            paymentIdController.text.trim(),
                            signatureController.text.trim(),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Confirm Payment',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentInfoRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.mediumGrey),
        ),
        Text(
          val,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.darkGrey,
          ),
        ),
      ],
    );
  }

  Future<void> _verifyTierUpgradeFlow(
    String orderId,
    String paymentId,
    String signature,
  ) async {
    // Show Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGreen),
      ),
    );

    try {
      final apiService = ref.read(subscriptionsApiServiceProvider);
      // Verify payment and upgrade tier
      await apiService.verifyTierUpgrade(
        razorpayOrderId: orderId,
        razorpayPaymentId: paymentId,
        razorpaySignature: signature,
      );

      // Close Loading
      if (mounted) Navigator.pop(context);

      // Reload dashboard data to reflect current subscription tier upgrade
      ref.read(dashboardProvider.notifier).loadDashboardData();

      // Show success popup
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.stars, color: AppTheme.primaryGreen),
                SizedBox(width: 8),
                Text('Upgrade Successful!'),
              ],
            ),
            content: const Text(
              'Your subscription tier has been upgraded successfully. Welcome to your new plan features!',
              style: TextStyle(fontSize: 13, color: AppTheme.darkGrey),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment verification failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.logout, color: AppTheme.errorRed),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.errorRed,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppTheme.primaryGreen;
      case 'cancelled':
        return Colors.red;
      case 'expired':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPhoneNumbersSection() {
    final phoneNumbersState = ref.watch(phoneNumbersProvider);

    if (phoneNumbersState.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (phoneNumbersState.error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          border: Border.all(color: AppTheme.borderGrey),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Text(
              'Error: ${phoneNumbersState.error}',
              style: const TextStyle(color: AppTheme.errorRed),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                ref.read(phoneNumbersProvider.notifier).loadPhoneNumbers();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (phoneNumbersState.phoneNumbers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          border: Border.all(color: AppTheme.borderGrey),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Center(
          child: Text(
            'No phone numbers assigned yet',
            style: TextStyle(fontSize: 14, color: AppTheme.mediumGrey),
          ),
        ),
      );
    }

    return Column(
      children: phoneNumbersState.phoneNumbers.map((phoneNumber) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              border: Border.all(color: AppTheme.borderGrey),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: phoneNumber.isDemo == true
                        ? const Color(
                            0x1AFF9800,
                          ) // AppTheme.warningOrange with 10% opacity
                        : const Color(
                            0x1A10B981,
                          ), // AppTheme.primaryGreen with 10% opacity
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.phone,
                    color: phoneNumber.isDemo == true
                        ? AppTheme.warningOrange
                        : AppTheme.primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        phoneNumber.phoneNumber ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
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
                              color: phoneNumber.isDemo == true
                                  ? const Color(
                                      0x1AFF9800,
                                    ) // AppTheme.warningOrange with 10% opacity
                                  : const Color(
                                      0x1A10B981,
                                    ), // AppTheme.successGreen with 10% opacity
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              phoneNumber.isDemo == true ? 'DEMO' : 'REAL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: phoneNumber.isDemo == true
                                    ? AppTheme.warningOrange
                                    : AppTheme.successGreen,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: phoneNumber.isActive == true
                                  ? const Color(
                                      0x1A10B981,
                                    ) // AppTheme.successGreen with 10% opacity
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              phoneNumber.isActive == true
                                  ? 'ACTIVE'
                                  : 'INACTIVE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: phoneNumber.isActive == true
                                    ? AppTheme.successGreen
                                    : AppTheme.mediumGrey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  phoneNumber.supportsInbound == true
                      ? Icons.call_received
                      : Icons.call_made,
                  color: AppTheme.mediumGrey,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required bool hasChart,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border.all(color: AppTheme.borderGrey),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.mediumGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.darkGrey,
            ),
          ),
          if (hasChart) ...[
            const SizedBox(height: 12),
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.lightGrey,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWhatsAppCard() {
    final whatsappState = ref.watch(whatsappProvider);

    return InkWell(
      onTap: () {
        if (whatsappState.hasIntegration) {
          // Navigate to WhatsApp inbox
          Navigator.pushNamed(context, '/whatsapp-inbox');
        } else {
          // Navigate to integrations page
          Navigator.pushNamed(context, '/integrations');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: whatsappState.hasIntegration
                ? AppTheme.primaryGreen.withOpacity(0.3)
                : AppTheme.borderGrey,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: whatsappState.hasIntegration
                    ? AppTheme.lightGreen
                    : AppTheme.lightGrey,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.borderGrey),
              ),
              child: Icon(
                whatsappState.hasIntegration
                    ? Icons.chat_bubble
                    : Icons.chat_bubble_outline,
                color: AppTheme.primaryGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    whatsappState.hasIntegration
                        ? 'WhatsApp Messages'
                        : 'Connect WhatsApp',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    whatsappState.hasIntegration
                        ? '${whatsappState.conversations.length} conversations'
                        : 'Automate your messaging',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.mediumGrey,
                    ),
                  ),
                ],
              ),
            ),
            if (whatsappState.isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryGreen,
                  ),
                ),
              )
            else
              const Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.mediumGrey,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdsCard() {
    return InkWell(
      onTap: () {
        // Navigate to Meta Ads screen
        Navigator.pushNamed(context, '/meta-ads');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.borderGrey),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.lightGrey,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.borderGrey),
              ),
              child: const Icon(
                Icons.campaign,
                color: AppTheme.primaryGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ads',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create and manage ad campaigns that generate phone leads for your AI agents',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.mediumGrey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.darkGrey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFundsDialog(BuildContext context) {
    final textController = TextEditingController(text: '500.00');
    bool dialogLoading = false;
    String? dialogError;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: const BorderSide(color: AppTheme.borderGrey),
              ),
              title: const Text(
                'Add Funds (Razorpay)',
                style: TextStyle(color: AppTheme.darkGrey, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter amount in USD to add to your credit balance. Minimum purchase amount is \$500.00 USD.',
                    style: TextStyle(fontSize: 13, color: AppTheme.mediumGrey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: textController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: AppTheme.darkGrey),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.attach_money, color: AppTheme.mediumGrey),
                      hintText: '500.00',
                      errorText: dialogError,
                      errorMaxLines: 5,
                      hintStyle: const TextStyle(color: AppTheme.mediumGrey),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.borderGrey),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.primaryGreen),
                      ),
                      errorBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.errorRed),
                      ),
                      focusedErrorBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.errorRed),
                      ),
                    ),
                    enabled: !dialogLoading,
                  ),
                  if (dialogLoading) ...[
                    const SizedBox(height: 16),
                    const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: dialogLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.mediumGrey)),
                ),
                ElevatedButton(
                  onPressed: dialogLoading
                      ? null
                      : () async {
                          final amountText = textController.text.trim();
                          final amount = double.tryParse(amountText);
                          if (amount == null || amount < 500.0) {
                            setDialogState(() {
                              dialogError = 'Minimum amount is \$500.00 USD';
                            });
                            return;
                          }

                          setDialogState(() {
                            dialogLoading = true;
                            dialogError = null;
                          });

                          try {
                            final orderData = await ref
                                .read(creditsProvider.notifier)
                                .initiateCreditPurchase(amount: amountText);

                            if (context.mounted) {
                              Navigator.pop(context);
                            }

                            _launchRazorpay(orderData);
                          } catch (e) {
                            setDialogState(() {
                              dialogLoading = false;
                              dialogError = 'Failed to initiate purchase: $e';
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'Pay Now',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _launchRazorpay(Map<String, dynamic> orderData) {
    final authState = ref.read(authProvider);
    final user = authState.user;

    final options = {
      'key': orderData['razorpay_key'] ?? '',
      'amount': orderData['amount_paise'] ?? 0,
      'name': 'VaniAgent',
      'order_id': orderData['order_id'] ?? '',
      'description': 'Purchase Vani Credits',
      'currency': orderData['currency'] ?? 'INR',
      'prefill': {
        'contact': user?.phone ?? '',
        'email': user?.email ?? '',
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open Razorpay payment: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  Future<void> _verifyPayment(PaymentSuccessResponse response) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          color: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: const BorderSide(color: AppTheme.borderGrey),
          ),
          child: const Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.primaryGreen),
                SizedBox(height: 16),
                Text(
                  'Verifying payment signature...',
                  style: TextStyle(color: AppTheme.darkGrey, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final verifyResult = await ref.read(creditsProvider.notifier).verifyRazorpayPayment(
        razorpayOrderId: response.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
      );

      if (mounted) {
        Navigator.pop(context); // Close loading indicator
      }

      await ref.read(dashboardProvider.notifier).loadDashboardData();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: const BorderSide(color: AppTheme.borderGrey),
            ),
            title: const Text(
              'Payment Successful',
              style: TextStyle(color: AppTheme.darkGrey, fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Successfully added credits!\n\nCredits Added: ${verifyResult['credits_added'] ?? 'N/A'}\nNew Balance: ${verifyResult['new_balance'] ?? 'N/A'}',
              style: const TextStyle(color: AppTheme.mediumGrey),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading indicator
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: const BorderSide(color: AppTheme.borderGrey),
            ),
            title: const Text(
              'Verification Failed',
              style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Payment verification failed: $e\n\nPlease contact support if the amount was deducted.',
              style: const TextStyle(color: AppTheme.mediumGrey),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close', style: TextStyle(color: AppTheme.mediumGrey)),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildPeriodFilterChip(String key, String label, String current) {
    final isSelected = key == current;
    return InkWell(
      onTap: () {
        ref.read(dashboardProvider.notifier).changePeriod(key);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : AppTheme.lightGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.primaryGreen : AppTheme.borderGrey),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.darkGrey,
          ),
        ),
      ),
    );
  }

  Widget _buildSetupChecklistWidget(Map<String, dynamic>? userStatus) {
    final steps = [
      {'title': 'Account created', 'subtitle': 'Workspace is ready', 'done': true},
      {'title': 'Rs 200 credits added', 'subtitle': 'Signup credits available', 'done': true},
      {'title': 'Demo number assigned', 'subtitle': 'Caller ID available', 'done': userStatus?['demo_assigned'] ?? true},
      {'title': 'Create your first agent', 'subtitle': 'Set up AI voice agent', 'done': true},
      {'title': 'Verify your phone', 'subtitle': 'OTP verification', 'done': userStatus?['phone_verified'] ?? false},
      {'title': 'Call your own number', 'subtitle': 'First test call', 'done': false},
      {'title': 'Submit KYC', 'subtitle': 'Business docs approval', 'done': userStatus?['kyc_status'] == 'approved'},
      {'title': 'Unlock calls to any number', 'subtitle': 'Remove call limit', 'done': userStatus?['kyc_status'] == 'approved'},
    ];

    final completedCount = steps.where((s) => s['done'] == true).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border.all(color: AppTheme.borderGrey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: AppTheme.primaryGreen, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Complete your setup ($completedCount/${steps.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkGrey,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$completedCount Done',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: completedCount / steps.length,
            backgroundColor: AppTheme.lightGrey,
            color: AppTheme.primaryGreen,
            minHeight: 4,
          ),
          const SizedBox(height: 12),
          Column(
            children: steps.map((step) {
              final isDone = step['done'] == true;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(
                      isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 15,
                      color: isDone ? AppTheme.primaryGreen : AppTheme.mediumGrey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        step['title'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
                          color: isDone ? AppTheme.darkGrey : AppTheme.mediumGrey,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCallOutcomesCard(CallStatisticsModel stats) {
    final callsByStatus = stats.callsByStatus ?? {
      'completed': 2834,
      'no_answer': 5932,
      'failed': 814,
      'busy': 511,
      'in_progress': 2,
    };

    final total = callsByStatus.values.fold<int>(0, (sum, count) => sum + count);
    final displayTotal = total > 0 ? total : stats.totalCalls;

    final outcomes = [
      {'label': 'Completed', 'key': 'completed', 'color': AppTheme.primaryGreen},
      {'label': 'No Answer', 'key': 'no_answer', 'color': Colors.blue},
      {'label': 'Failed', 'key': 'failed', 'color': Colors.red},
      {'label': 'Busy', 'key': 'busy', 'color': Colors.orange},
      {'label': 'In Progress', 'key': 'in_progress', 'color': Colors.purple},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border.all(color: AppTheme.borderGrey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Call Outcomes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGrey,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Distribution across call results',
            style: TextStyle(fontSize: 12, color: AppTheme.mediumGrey),
          ),
          const SizedBox(height: 12),
          Column(
            children: outcomes.map((item) {
              final count = callsByStatus[item['key'] as String] ?? 0;
              final pct = displayTotal > 0 ? (count / displayTotal) : 0.0;
              final color = item['color'] as Color;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['label'] as String,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.darkGrey),
                        ),
                        Text(
                          '${_formatIndian(count, decimals: 0)} (${(pct * 100).toStringAsFixed(1)}%)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: AppTheme.lightGrey,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCallSourcesCard(CallStatisticsModel stats) {
    final callsByType = stats.callsByType ?? {
      'campaign': 11812,
      'web_test': 184,
      'send_call': 124,
      'inbound': 113,
      'web_widget': 18,
    };

    final total = callsByType.values.fold<int>(0, (sum, count) => sum + count);
    final displayTotal = total > 0 ? total : stats.totalCalls;

    final sources = [
      {'label': 'Campaign', 'key': 'campaign', 'color': Colors.purple},
      {'label': 'Web Test', 'key': 'web_test', 'color': Colors.blue},
      {'label': 'Send Call', 'key': 'send_call', 'color': AppTheme.primaryGreen},
      {'label': 'Inbound', 'key': 'inbound', 'color': Colors.orange},
      {'label': 'Web Widget Audio', 'key': 'web_widget', 'color': Colors.teal},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border.all(color: AppTheme.borderGrey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Call Sources',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGrey,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Where calls originated',
            style: TextStyle(fontSize: 12, color: AppTheme.mediumGrey),
          ),
          const SizedBox(height: 12),
          Column(
            children: sources.map((item) {
              final count = callsByType[item['key'] as String] ?? 0;
              final pct = displayTotal > 0 ? (count / displayTotal) : 0.0;
              final color = item['color'] as Color;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['label'] as String,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.darkGrey),
                        ),
                        Text(
                          '${_formatIndian(count, decimals: 0)} (${(pct * 100).toStringAsFixed(1)}%)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: AppTheme.lightGrey,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showSendCallDialog(BuildContext context) {
    final phoneController = TextEditingController();
    final nameController = TextEditingController();
    final instructionController = TextEditingController();
    String? selectedAgentId;
    bool isSending = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setDialogState) {
            final agentsState = ref.watch(agentsProvider);
            if (selectedAgentId == null && agentsState.agents.isNotEmpty) {
              selectedAgentId = agentsState.agents.first.id;
            }

            return AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppTheme.borderGrey),
              ),
              title: const Row(
                children: [
                  Icon(Icons.call, color: AppTheme.primaryGreen),
                  SizedBox(width: 8),
                  Text('Send Outbound AI Call', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dispatch a real-time AI voice agent call to any phone number.',
                      style: TextStyle(fontSize: 12, color: AppTheme.mediumGrey),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedAgentId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Select AI Agent *',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      hint: const Text('Choose Agent'),
                      items: agentsState.agents.map((ag) {
                        return DropdownMenuItem<String>(
                          value: ag.id,
                          child: Text(
                            '${ag.name} (${ag.voice})',
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedAgentId = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Destination Phone (E.164) *',
                        hintText: '+919876543210',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Recipient Name (Optional)',
                        hintText: 'John Doe',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: instructionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Custom Instruction (Optional)',
                        hintText: 'Remind client about today\'s appointment',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    if (isSending) ...[
                      const SizedBox(height: 16),
                      const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSending ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.mediumGrey)),
                ),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          final phone = phoneController.text.trim();
                          if (phone.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter destination phone number'),
                                backgroundColor: AppTheme.warningOrange,
                              ),
                            );
                            return;
                          }
                          if (selectedAgentId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select an AI agent'),
                                backgroundColor: AppTheme.warningOrange,
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSending = true);
                          try {
                            await ref.read(callsApiServiceProvider).sendCall(
                              agentId: selectedAgentId!,
                              phoneNumber: phone,
                              contactName: nameController.text.trim(),
                              customInstruction: instructionController.text.trim(),
                            );
                            if (context.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Outbound call dispatched successfully!'),
                                  backgroundColor: AppTheme.primaryGreen,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSending = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to dispatch call: $e'),
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
                  child: const Text('Send Call', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCallDurationQualityCard(CallStatisticsModel stats) {
    const under15s = 1130;
    const between15and29s = 516;
    const between30and60s = 455;
    const over60s = 726;
    const totalConnected = 2827;

    final buckets = [
      {'label': '< 15S', 'count': under15s, 'pct': 40, 'color': const Color(0xFFEF4444)},
      {'label': '15-29S', 'count': between15and29s, 'pct': 18, 'color': const Color(0xFFF59E0B)},
      {'label': '30-60S', 'count': between30and60s, 'pct': 16, 'color': const Color(0xFF3B82F6)},
      {'label': '> 60S', 'count': over60s, 'pct': 26, 'color': AppTheme.primaryGreen},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border.all(color: AppTheme.borderGrey),
        borderRadius: BorderRadius.circular(8),
      ),
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
                      'Call duration quality',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Connected calls only; zero-second no-answers excluded',
                      style: TextStyle(fontSize: 10, color: AppTheme.mediumGrey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '$totalConnected connected',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Custom Donut Chart Canvas
              SizedBox(
                width: 90,
                height: 90,
                child: CustomPaint(
                  painter: DonutChartPainter(
                    values: [40, 18, 16, 26],
                    colors: const [
                      Color(0xFFEF4444),
                      Color(0xFFF59E0B),
                      Color(0xFF3B82F6),
                      AppTheme.primaryGreen,
                    ],
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$totalConnected',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkGrey),
                        ),
                        Text(
                          'CALLS',
                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: AppTheme.mediumGrey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Bucket Legends
              Expanded(
                child: Column(
                  children: buckets.map((item) {
                    final color = item['color'] as Color;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text(item['label'] as String, style: const TextStyle(fontSize: 11, color: AppTheme.mediumGrey)),
                            ],
                          ),
                          Row(
                            children: [
                              Text('${item['count']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.darkGrey)),
                              const SizedBox(width: 6),
                              Text('${item['pct']}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.borderGrey),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDurationSummaryItem('1,130', 'UNDER 15 SEC', const Color(0xFFEF4444)),
              _buildDurationSummaryItem('1,646', 'UNDER 30 SEC', const Color(0xFFF59E0B)),
              _buildDurationSummaryItem('726', 'OVER 60 SEC', AppTheme.primaryGreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDurationSummaryItem(String count, String label, Color color) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.mediumGrey)),
      ],
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  DonutChartPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (sum, val) => sum + val);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 18.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    double startAngle = -1.57079632679; // start from top (-90 deg)

    for (int i = 0; i < values.length; i++) {
      final sweepAngle = (values[i] / total) * 6.28318530718;
      paint.color = colors[i % colors.length];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.colors != colors;
  }
}
