import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:vani_app/core/exceptions/app_exception.dart';
import 'package:vani_app/data/services/knowledge_api_service.dart';
import 'package:vani_app/models/knowledge_base_model.dart';

final _logger = Logger();

class KnowledgeState {
  final List<KnowledgeBase> knowledgeBases;
  final bool isLoading;
  final String? error;

  KnowledgeState({
    this.knowledgeBases = const [],
    this.isLoading = false,
    this.error,
  });

  KnowledgeState copyWith({
    List<KnowledgeBase>? knowledgeBases,
    bool? isLoading,
    String? error,
  }) {
    return KnowledgeState(
      knowledgeBases: knowledgeBases ?? this.knowledgeBases,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class KnowledgeNotifier extends StateNotifier<KnowledgeState> {
  final KnowledgeApiService _apiService;

  KnowledgeNotifier(this._apiService) : super(KnowledgeState());

  Future<void> loadKnowledgeBases() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      _logger.d('Loading knowledge bases in provider...');
      final knowledgeBases = await _apiService.getKnowledgeBases();
      state = state.copyWith(
        knowledgeBases: knowledgeBases,
        isLoading: false,
        error: null,
      );
    } on AppException catch (e) {
      _logger.e('AppException loading knowledge bases: ${e.message}');
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      _logger.e('Error loading knowledge bases: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load knowledge bases',
      );
    }
  }

  Future<KnowledgeBase> createKnowledgeBase(String name, String text) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      _logger.d('Creating knowledge base in provider...');
      final newKb = await _apiService.createKnowledgeBase({
        'name': name,
        'text': text,
      });
      final updatedList = [...state.knowledgeBases, newKb];
      state = state.copyWith(
        knowledgeBases: updatedList,
        isLoading: false,
        error: null,
      );
      return newKb;
    } on AppException catch (e) {
      _logger.e('AppException creating knowledge base: ${e.message}');
      state = state.copyWith(isLoading: false, error: e.message);
      rethrow;
    } catch (e) {
      _logger.e('Error creating knowledge base: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create knowledge base',
      );
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final knowledgeProvider = StateNotifierProvider<KnowledgeNotifier, KnowledgeState>((ref) {
  final apiService = ref.watch(knowledgeApiServiceProvider);
  return KnowledgeNotifier(apiService);
});
