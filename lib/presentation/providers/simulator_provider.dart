import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vani_app/core/exceptions/app_exception.dart';
import 'package:vani_app/data/services/simulator_api_service.dart';

class SimulatorState {
  final List<dynamic> drafts;
  final List<dynamic> runs;
  final Map<String, dynamic>? currentDraft;
  final Map<String, dynamic>? currentRun;
  final bool isLoading;
  final String? error;

  SimulatorState({
    this.drafts = const [],
    this.runs = const [],
    this.currentDraft,
    this.currentRun,
    this.isLoading = false,
    this.error,
  });

  SimulatorState copyWith({
    List<dynamic>? drafts,
    List<dynamic>? runs,
    Map<String, dynamic>? currentDraft,
    Map<String, dynamic>? currentRun,
    bool? isLoading,
    String? error,
  }) {
    return SimulatorState(
      drafts: drafts ?? this.drafts,
      runs: runs ?? this.runs,
      currentDraft: currentDraft ?? this.currentDraft,
      currentRun: currentRun ?? this.currentRun,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SimulatorNotifier extends StateNotifier<SimulatorState> {
  final SimulatorApiService _apiService;

  SimulatorNotifier(this._apiService) : super(SimulatorState());

  Future<void> loadDraftsAndRuns(String agentId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final drafts = await _apiService.listSimulationDrafts(agentId);
      final runs = await _apiService.listSimulationRuns(agentId);
      
      state = state.copyWith(
        drafts: drafts,
        runs: runs,
        isLoading: false,
        error: null,
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load simulator data');
    }
  }

  Future<void> generateDraft(String agentId, Map<String, dynamic> params) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final draft = await _apiService.generateSimulationDraft(agentId, params);
      final draftsList = [draft, ...state.drafts.where((d) => d['id'] != draft['id'])];
      state = state.copyWith(
        currentDraft: draft,
        drafts: draftsList,
        isLoading: false,
        error: null,
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to generate persona draft');
      rethrow;
    }
  }

  Future<void> loadDraft(String agentId, String draftId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final draft = await _apiService.getSimulationDraft(agentId, draftId);
      state = state.copyWith(
        currentDraft: draft,
        isLoading: false,
        error: null,
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load draft details');
    }
  }

  Future<void> updateDraft(String agentId, String draftId, Map<String, dynamic> updateData) async {
    try {
      final updatedDraft = await _apiService.updateSimulationDraft(agentId, draftId, updateData);
      final updatedDraftsList = state.drafts.map((d) {
        if (d['id'] == draftId) return updatedDraft;
        return d;
      }).toList();
      state = state.copyWith(
        currentDraft: updatedDraft,
        drafts: updatedDraftsList,
      );
    } on AppException catch (e) {
      state = state.copyWith(error: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(error: 'Failed to update draft');
      rethrow;
    }
  }

  Future<void> generateMore(String agentId, String draftId, int count) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedDraft = await _apiService.generateMorePersonas(agentId, draftId, count);
      final updatedDraftsList = state.drafts.map((d) {
        if (d['id'] == draftId) return updatedDraft;
        return d;
      }).toList();
      state = state.copyWith(
        currentDraft: updatedDraft,
        drafts: updatedDraftsList,
        isLoading: false,
        error: null,
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to generate more personas');
      rethrow;
    }
  }

  Future<void> startSimulation(String agentId, String draftId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final run = await _apiService.startSimulationDraft(agentId, draftId);
      final runsList = [run, ...state.runs];
      state = state.copyWith(
        currentRun: run,
        runs: runsList,
        isLoading: false,
        error: null,
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to start simulation');
      rethrow;
    }
  }

  Future<void> loadRun(String agentId, String runId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final run = await _apiService.getSimulationRun(agentId, runId);
      state = state.copyWith(
        currentRun: run,
        isLoading: false,
        error: null,
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load run details');
    }
  }

  Future<void> deleteRun(String agentId, String runId) async {
    try {
      await _apiService.deleteSimulationRun(agentId, runId);
      final updatedRuns = state.runs.where((r) => r['id'] != runId).toList();
      state = state.copyWith(
        runs: updatedRuns,
        currentRun: state.currentRun?['id'] == runId ? null : state.currentRun,
      );
    } on AppException catch (e) {
      state = state.copyWith(error: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete run');
      rethrow;
    }
  }

  void clearCurrentDraft() {
    state = state.copyWith(currentDraft: null);
  }

  void selectDraft(Map<String, dynamic> draft) {
    state = state.copyWith(currentDraft: draft);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final simulatorProvider = StateNotifierProvider<SimulatorNotifier, SimulatorState>((ref) {
  final apiService = ref.watch(simulatorApiServiceProvider);
  return SimulatorNotifier(apiService);
});
