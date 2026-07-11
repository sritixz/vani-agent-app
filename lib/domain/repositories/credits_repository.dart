import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vani_app/core/exceptions/app_exception.dart';
import 'package:vani_app/data/models/credits/credits_model.dart';
import 'package:vani_app/data/services/credits_api_service.dart';

class CreditsRepository {
  final CreditsApiService _apiService;

  CreditsRepository(this._apiService);

  Future<CreditBalanceModel> getCreditBalance() async {
    try {
      return await _apiService.getCreditBalance();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Failed to fetch credit balance: ${e.toString()}');
    }
  }

  Future<List<CreditTransactionModel>> getCreditTransactions({
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      return await _apiService.getCreditTransactions(
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Failed to fetch credit transactions: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> initiateCreditPurchase({
    required String amount,
  }) async {
    try {
      return await _apiService.initiateCreditPurchase(amount: amount);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Failed to initiate credit purchase: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> verifyRazorpayPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      return await _apiService.verifyRazorpayPayment(
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
        razorpaySignature: razorpaySignature,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Failed to verify Razorpay payment: ${e.toString()}');
    }
  }
}

// Provider
final creditsRepositoryProvider = Provider<CreditsRepository>((ref) {
  final apiService = ref.watch(creditsApiServiceProvider);
  return CreditsRepository(apiService);
});
