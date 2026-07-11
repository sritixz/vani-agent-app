import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vani_app/core/exceptions/app_exception.dart';
import 'package:vani_app/data/models/credits/credits_model.dart';
import 'package:vani_app/domain/repositories/credits_repository.dart';

// Credits State
class CreditsState {
  final CreditBalanceModel? balance;
  final List<CreditTransactionModel> transactions;
  final bool isLoadingBalance;
  final bool isLoadingTransactions;
  final bool isPurchasing;
  final String? error;

  CreditsState({
    this.balance,
    this.transactions = const [],
    this.isLoadingBalance = false,
    this.isLoadingTransactions = false,
    this.isPurchasing = false,
    this.error,
  });

  CreditsState copyWith({
    CreditBalanceModel? balance,
    List<CreditTransactionModel>? transactions,
    bool? isLoadingBalance,
    bool? isLoadingTransactions,
    bool? isPurchasing,
    String? error,
  }) {
    return CreditsState(
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
      isLoadingBalance: isLoadingBalance ?? this.isLoadingBalance,
      isLoadingTransactions: isLoadingTransactions ?? this.isLoadingTransactions,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      error: error,
    );
  }
}

// Credits Notifier
class CreditsNotifier extends StateNotifier<CreditsState> {
  final CreditsRepository _repository;

  CreditsNotifier(this._repository) : super(CreditsState());

  Future<void> loadCreditBalance() async {
    state = state.copyWith(isLoadingBalance: true, error: null);
    try {
      final balance = await _repository.getCreditBalance();
      state = state.copyWith(
        balance: balance,
        isLoadingBalance: false,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        isLoadingBalance: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingBalance: false,
        error: 'Failed to load credit balance',
      );
    }
  }

  Future<void> loadCreditTransactions({int limit = 10, int offset = 0}) async {
    state = state.copyWith(isLoadingTransactions: true, error: null);
    try {
      final transactions = await _repository.getCreditTransactions(
        limit: limit,
        offset: offset,
      );
      state = state.copyWith(
        transactions: transactions,
        isLoadingTransactions: false,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        isLoadingTransactions: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingTransactions: false,
        error: 'Failed to load credit transactions',
      );
    }
  }

  Future<Map<String, dynamic>> initiateCreditPurchase({
    required String amount,
  }) async {
    state = state.copyWith(isPurchasing: true, error: null);
    try {
      final orderData = await _repository.initiateCreditPurchase(amount: amount);
      state = state.copyWith(isPurchasing: false);
      return orderData;
    } on AppException catch (e) {
      state = state.copyWith(
        isPurchasing: false,
        error: e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isPurchasing: false,
        error: 'Failed to initiate credit purchase',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyRazorpayPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    state = state.copyWith(isPurchasing: true, error: null);
    try {
      final verificationResult = await _repository.verifyRazorpayPayment(
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
        razorpaySignature: razorpaySignature,
      );
      // Reload balance after successful payment
      await loadCreditBalance();
      state = state.copyWith(isPurchasing: false);
      return verificationResult;
    } on AppException catch (e) {
      state = state.copyWith(
        isPurchasing: false,
        error: e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isPurchasing: false,
        error: 'Failed to verify payment',
      );
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final creditsProvider =
    StateNotifierProvider<CreditsNotifier, CreditsState>((ref) {
  final repository = ref.watch(creditsRepositoryProvider);
  return CreditsNotifier(repository);
});
