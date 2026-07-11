import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vani_app/core/network/api_endpoints.dart';
import 'package:vani_app/core/network/dio_client.dart';
import 'package:vani_app/data/models/subscriptions/subscription_model.dart';

class SubscriptionsApiService {
  final DioClient _dioClient;

  SubscriptionsApiService(this._dioClient);

  Future<List<SubscriptionTierModel>> getSubscriptionTiers() async {
    final response = await _dioClient.get(ApiEndpoints.subscriptionTiers);
    return (response.data as List)
        .map((json) => SubscriptionTierModel.fromJson(json))
        .toList();
  }

  Future<CurrentSubscriptionModel> getCurrentSubscription() async {
    final response = await _dioClient.get(ApiEndpoints.currentSubscription);
    return CurrentSubscriptionModel.fromJson(response.data);
  }

  Future<CurrentSubscriptionModel> changeTier({
    required String tierId,
  }) async {
    final response = await _dioClient.post(
      ApiEndpoints.changeTier,
      data: {'tierId': tierId},
    );
    return CurrentSubscriptionModel.fromJson(response.data);
  }

  Future<Map<String, dynamic>> upgradeTier({
    required String tierName,
  }) async {
    final response = await _dioClient.post(
      ApiEndpoints.upgradeTier,
      data: {'tier_name': tierName},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyTierUpgrade({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final response = await _dioClient.post(
      ApiEndpoints.verifyTierUpgrade,
      data: {
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}

// Provider
final subscriptionsApiServiceProvider = Provider<SubscriptionsApiService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return SubscriptionsApiService(dioClient);
});
