import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vani_app/core/network/api_endpoints.dart';
import 'package:vani_app/core/network/dio_client.dart';
import 'package:vani_app/data/models/credits/credits_model.dart';

class CreditsApiService {
  final DioClient _dioClient;

  CreditsApiService(this._dioClient);

  Future<CreditBalanceModel> getCreditBalance() async {
    final response = await _dioClient.get(ApiEndpoints.creditBalance);
    return CreditBalanceModel.fromJson(response.data);
  }

  Future<List<CreditTransactionModel>> getCreditTransactions({
    int limit = 10,
    int offset = 0,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.creditTransactions,
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );
    return (response.data as List)
        .map((json) => CreditTransactionModel.fromJson(json))
        .toList();
  }

  Future<Map<String, dynamic>> initiateCreditPurchase({
    required String amount,
  }) async {
    final response = await _dioClient.post(
      ApiEndpoints.purchaseCredits,
      data: {
        'amount': amount,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> verifyRazorpayPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final response = await _dioClient.post(
      ApiEndpoints.verifyPayment,
      data: {
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
      },
    );
    return response.data;
  }
}

// Provider
final creditsApiServiceProvider = Provider<CreditsApiService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return CreditsApiService(dioClient);
});
