import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:vani_app/core/exceptions/app_exception.dart';
import 'package:vani_app/data/models/calls/call_statistics_model.dart';
import 'package:vani_app/data/models/credits/credits_model.dart';
import 'package:vani_app/data/models/subscriptions/subscription_model.dart';
import 'package:vani_app/data/services/calls_api_service.dart';
import 'package:vani_app/data/services/user_api_service.dart';
import 'package:vani_app/data/services/credits_api_service.dart';
import 'package:vani_app/data/services/subscriptions_api_service.dart';

final _logger = Logger();

// Dashboard State
class DashboardState {
  final CreditBalanceModel? creditBalance;
  final CurrentSubscriptionModel? currentSubscription;
  final CallStatisticsModel? callStatistics;
  final Map<String, dynamic>? userStatusMap;
  final String selectedPeriod; // 'all', 'today', '7d', '30d'
  final bool isLoading;
  final bool isStatsLoading;
  final String? error;

  DashboardState({
    this.creditBalance,
    this.currentSubscription,
    this.callStatistics,
    this.userStatusMap,
    this.selectedPeriod = 'all',
    this.isLoading = false,
    this.isStatsLoading = false,
    this.error,
  });

  DashboardState copyWith({
    CreditBalanceModel? creditBalance,
    CurrentSubscriptionModel? currentSubscription,
    CallStatisticsModel? callStatistics,
    Map<String, dynamic>? userStatusMap,
    String? selectedPeriod,
    bool? isLoading,
    bool? isStatsLoading,
    String? error,
  }) {
    return DashboardState(
      creditBalance: creditBalance ?? this.creditBalance,
      currentSubscription: currentSubscription ?? this.currentSubscription,
      callStatistics: callStatistics ?? this.callStatistics,
      userStatusMap: userStatusMap ?? this.userStatusMap,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      isLoading: isLoading ?? this.isLoading,
      isStatsLoading: isStatsLoading ?? this.isStatsLoading,
      error: error,
    );
  }
}

// Dashboard Notifier
class DashboardNotifier extends StateNotifier<DashboardState> {
  final UserApiService _userApiService;
  final CreditsApiService _creditsApiService;
  final SubscriptionsApiService _subscriptionsApiService;
  final CallsApiService _callsApiService;

  DashboardNotifier(
    this._userApiService,
    this._creditsApiService,
    this._subscriptionsApiService,
    this._callsApiService,
  ) : super(DashboardState());

  Future<void> changePeriod(String period) async {
    if (state.selectedPeriod == period && state.callStatistics != null) return;
    state = state.copyWith(selectedPeriod: period, isStatsLoading: true);
    try {
      final periodParam = period == 'all' ? null : period;
      final stats = await _callsApiService.getCallStatistics(period: periodParam);
      state = state.copyWith(callStatistics: stats, isStatsLoading: false);
    } catch (e) {
      _logger.e('Error changing period statistics: $e');
      state = state.copyWith(isStatsLoading: false);
    }
  }

  Future<void> loadDashboardData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      CreditBalanceModel? creditBalance;
      CurrentSubscriptionModel? currentSubscription;
      CallStatisticsModel? callStatistics;
      Map<String, dynamic>? userStatusMap;
      String? error;

      // Try to fetch from user status endpoint first
      try {
        userStatusMap = await _userApiService.getUserStatus();
        _logger.d('User Status Response: $userStatusMap');

        // Parse credit balance - handle both object and simple number formats
        dynamic creditData = userStatusMap['credit_balance'] ?? 
                            userStatusMap['creditBalance'] ?? 
                            userStatusMap['credits'];
        
        if (creditData != null) {
          try {
            if (creditData is Map<String, dynamic>) {
              // If it's an object, parse it directly
              creditBalance = CreditBalanceModel.fromJson(creditData);
              _logger.d('Parsed credit balance from user status (object): $creditBalance');
            } else if (creditData is num) {
              // If it's a simple number, create a CreditBalanceModel with it
              creditBalance = CreditBalanceModel(
                balance: creditData.toDouble(),
                currency: 'USD',
                lastUpdated: DateTime.now(),
              );
              _logger.d('Parsed credit balance from user status (number): $creditBalance');
            } else if (creditData is String) {
              // If it's a string, try to parse it as a number
              try {
                final balanceValue = double.parse(creditData);
                creditBalance = CreditBalanceModel(
                  balance: balanceValue,
                  currency: 'USD',
                  lastUpdated: DateTime.now(),
                );
                _logger.d('Parsed credit balance from user status (string): $creditBalance');
              } catch (e) {
                _logger.w('Failed to parse credit balance string: $creditData');
              }
            } else {
              _logger.w('Credit data is unexpected type: ${creditData.runtimeType}');
            }
          } catch (e) {
            _logger.w('Error parsing credit balance from user status: $e');
          }
        }

        // Parse subscription plan - check multiple possible field names
        dynamic subscriptionData = userStatusMap['subscription_plan'] ?? 
                                  userStatusMap['subscriptionPlan'] ?? 
                                  userStatusMap['subscription'] ??
                                  userStatusMap['subscription_tier'] ??
                                  userStatusMap['current_subscription'];
        
        if (subscriptionData != null) {
          try {
            if (subscriptionData is Map<String, dynamic>) {
              currentSubscription = CurrentSubscriptionModel.fromJson(subscriptionData);
              _logger.d('Parsed subscription from user status (object): $currentSubscription');
            } else if (subscriptionData is String) {
              // If it's a simple string (tier name), create a subscription model
              currentSubscription = CurrentSubscriptionModel(
                id: 'unknown',
                tierId: 'unknown',
                status: 'active',
                tierName: subscriptionData,
              );
              _logger.d('Parsed subscription from user status (string): $currentSubscription');
            } else {
              _logger.w('Subscription data is unexpected type: ${subscriptionData.runtimeType}');
            }
          } catch (e) {
            _logger.w('Error parsing subscription from user status: $e');
          }
        }
      } catch (e) {
        _logger.w('Failed to fetch from user status endpoint: $e');
      }

      // Fallback: If data not found in user status, fetch from dedicated endpoints
      if (creditBalance == null) {
        try {
          _logger.d('Fetching credit balance from dedicated endpoint');
          creditBalance = await _creditsApiService.getCreditBalance();
          _logger.d('Fetched credit balance: $creditBalance');
        } catch (e) {
          _logger.e('Error fetching credit balance: $e');
          error = error ?? 'Failed to fetch credit balance';
        }
      }

      if (currentSubscription == null) {
        try {
          _logger.d('Fetching subscription from dedicated endpoint');
          currentSubscription = await _subscriptionsApiService.getCurrentSubscription();
          _logger.d('Fetched subscription: $currentSubscription');
        } catch (e) {
          _logger.e('Error fetching subscription: $e');
          error = error ?? 'Failed to fetch subscription';
        }
      }

      // Fetch call statistics
      try {
        _logger.d('Fetching call statistics');
        final periodParam = state.selectedPeriod == 'all' ? null : state.selectedPeriod;
        callStatistics = await _callsApiService.getCallStatistics(period: periodParam);
        _logger.d('Fetched call statistics: $callStatistics');
      } catch (e) {
        _logger.e('Error fetching call statistics: $e');
        // Don't set error for statistics, just log it
      }

      state = state.copyWith(
        creditBalance: creditBalance,
        currentSubscription: currentSubscription,
        callStatistics: callStatistics,
        userStatusMap: userStatusMap,
        isLoading: false,
        error: error,
      );
    } on AppException catch (e) {
      _logger.e('AppException: ${e.message}');
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      _logger.e('Error loading dashboard data: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load dashboard data: ${e.toString()}',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final userApiService = ref.watch(userApiServiceProvider);
  final creditsApiService = ref.watch(creditsApiServiceProvider);
  final subscriptionsApiService = ref.watch(subscriptionsApiServiceProvider);
  final callsApiService = ref.watch(callsApiServiceProvider);
  return DashboardNotifier(
    userApiService,
    creditsApiService,
    subscriptionsApiService,
    callsApiService,
  );
});
