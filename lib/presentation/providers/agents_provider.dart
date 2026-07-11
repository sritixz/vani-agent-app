import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:vani_app/core/exceptions/app_exception.dart';
import 'package:vani_app/data/services/agents_api_service.dart';
import 'package:vani_app/data/services/phone_numbers_api_service.dart';
import 'package:vani_app/models/agent_model.dart';

final _logger = Logger();

// Agents State
class AgentsState {
  final List<Agent> agents;
  final Map<String, String>
  phoneNumbersMap; // phoneNumberId -> actual phone number
  final bool isLoading;
  final String? error;

  AgentsState({
    this.agents = const [],
    this.phoneNumbersMap = const {},
    this.isLoading = false,
    this.error,
  });

  AgentsState copyWith({
    List<Agent>? agents,
    Map<String, String>? phoneNumbersMap,
    bool? isLoading,
    String? error,
  }) {
    return AgentsState(
      agents: agents ?? this.agents,
      phoneNumbersMap: phoneNumbersMap ?? this.phoneNumbersMap,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  // Helper method to get phone number for an agent
  String getPhoneNumber(Agent agent) {
    if (agent.phoneNumberId == null) return 'Unassigned';
    return phoneNumbersMap[agent.phoneNumberId] ?? agent.phoneNumberId!;
  }
}

// Agents Notifier
class AgentsNotifier extends StateNotifier<AgentsState> {
  final AgentsApiService _agentsApiService;
  final PhoneNumbersApiService _phoneNumbersApiService;

  AgentsNotifier(this._agentsApiService, this._phoneNumbersApiService)
    : super(AgentsState());

  Future<void> loadAgents() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      _logger.d('Fetching agents...');
      final agents = await _agentsApiService.getAgents();
      _logger.d('Fetched ${agents.length} agents');

      // Fetch phone numbers to create a mapping
      Map<String, String> phoneNumbersMap = {};
      try {
        _logger.d('Fetching phone numbers for mapping...');
        final phoneNumbers = await _phoneNumbersApiService.getPhoneNumbers();
        phoneNumbersMap = {
          for (var phone in phoneNumbers)
            phone.id: phone.phoneNumber ?? phone.id,
        };
        _logger.d(
          'Created phone numbers map with ${phoneNumbersMap.length} entries',
        );
      } catch (e) {
        _logger.w('Failed to fetch phone numbers for mapping: $e');
        // Continue without phone number mapping
      }

      state = state.copyWith(
        agents: agents,
        phoneNumbersMap: phoneNumbersMap,
        isLoading: false,
        error: null,
      );
    } on AppException catch (e) {
      _logger.e('AppException: ${e.message}');
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      _logger.e('Error loading agents: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load agents: ${e.toString()}',
      );
    }
  }

  Future<void> toggleAgentStatus(String agentId, bool isActive) async {
    try {
      _logger.d('Toggling agent $agentId status to $isActive');

      // Optimistically update the UI
      final updatedAgents = state.agents.map((agent) {
        if (agent.id == agentId) {
          return agent.copyWith(isActive: isActive);
        }
        return agent;
      }).toList();

      state = state.copyWith(agents: updatedAgents);

      // Make API call
      await _agentsApiService.updateAgent(agentId, {'is_active': isActive});
      _logger.d('Agent status updated successfully');
    } on AppException catch (e) {
      _logger.e('AppException: ${e.message}');
      // Revert the optimistic update
      await loadAgents();
      state = state.copyWith(error: e.message);
    } catch (e) {
      _logger.e('Error toggling agent status: $e');
      // Revert the optimistic update
      await loadAgents();
      state = state.copyWith(error: 'Failed to update agent status');
    }
  }

  Future<void> createAgent(Map<String, dynamic> agentData) async {
    try {
      _logger.d('Creating new agent...');
      final newAgent = await _agentsApiService.createAgent(agentData);
      _logger.d('Agent created successfully: ${newAgent.id}');

      // Add to state
      final updatedAgents = [...state.agents, newAgent];
      state = state.copyWith(agents: updatedAgents);
    } on AppException catch (e) {
      _logger.e('AppException: ${e.message}');
      state = state.copyWith(error: e.message);
      rethrow;
    } catch (e) {
      _logger.e('Error creating agent: $e');
      state = state.copyWith(error: 'Failed to create agent');
      rethrow;
    }
  }

  Future<void> updateAgent(
    String agentId,
    Map<String, dynamic> agentData,
  ) async {
    try {
      _logger.d('=== AGENTS PROVIDER UPDATE ===');
      _logger.d('Agent ID: $agentId');
      _logger.d('Update data: $agentData');

      final updatedAgent = await _agentsApiService.updateAgent(
        agentId,
        agentData,
      );

      _logger.d('Agent updated successfully from API');
      _logger.d('Updated agent data: ${updatedAgent.toJson()}');

      // Update in state
      final updatedAgents = state.agents.map((agent) {
        if (agent.id == agentId) {
          _logger.d('Found agent in state, replacing with updated version');
          return updatedAgent;
        }
        return agent;
      }).toList();

      _logger.d('Updating state with ${updatedAgents.length} agents');
      state = state.copyWith(agents: updatedAgents);
      _logger.d('State updated successfully');
      _logger.d('==============================');
    } on AppException catch (e) {
      _logger.e('=== AGENTS PROVIDER UPDATE ERROR (AppException) ===');
      _logger.e('AppException: ${e.message}');
      _logger.e('===================================================');
      state = state.copyWith(error: e.message);
      rethrow;
    } catch (e, stackTrace) {
      _logger.e('=== AGENTS PROVIDER UPDATE ERROR ===');
      _logger.e('Error updating agent: $e');
      _logger.e('Stack trace: $stackTrace');
      _logger.e('====================================');
      state = state.copyWith(error: 'Failed to update agent');
      rethrow;
    }
  }

  Future<void> deleteAgent(String agentId) async {
    try {
      _logger.d('Deleting agent $agentId');
      await _agentsApiService.deleteAgent(agentId);
      _logger.d('Agent deleted successfully');

      // Remove from state
      final updatedAgents = state.agents
          .where((agent) => agent.id != agentId)
          .toList();
      state = state.copyWith(agents: updatedAgents);
    } on AppException catch (e) {
      _logger.e('AppException: ${e.message}');
      state = state.copyWith(error: e.message);
    } catch (e) {
      _logger.e('Error deleting agent: $e');
      state = state.copyWith(error: 'Failed to delete agent');
    }
  }

  Future<String> generateAnalysisPrompt(String agentPrompt) async {
    try {
      _logger.d('Generating analysis prompt...');
      final analysisPrompt = await _agentsApiService.generateAnalysisPrompt(
        agentPrompt,
      );
      _logger.d('Analysis prompt generated successfully');
      return analysisPrompt;
    } on AppException catch (e) {
      _logger.e('AppException: ${e.message}');
      state = state.copyWith(error: e.message);
      rethrow;
    } catch (e) {
      _logger.e('Error generating analysis prompt: $e');
      state = state.copyWith(error: 'Failed to generate analysis prompt');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> generateAnalysisConfig(
    String agentPrompt,
  ) async {
    try {
      _logger.d('Generating analysis config...');
      final analysisConfig = await _agentsApiService.generateAnalysisConfig(
        agentPrompt,
      );
      _logger.d('Analysis config generated successfully');
      return analysisConfig;
    } on AppException catch (e) {
      _logger.e('AppException: ${e.message}');
      state = state.copyWith(error: e.message);
      rethrow;
    } catch (e) {
      _logger.e('Error generating analysis config: $e');
      state = state.copyWith(error: 'Failed to generate analysis config');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> generateS2sSystemPrompt({
    required String provider,
    required String agentPrompt,
    String? greetingLine,
    required String greetingType,
    required String language,
    required List<String> knowledgeBaseIds,
  }) async {
    try {
      _logger.d('Generating S2S system prompt...');
      final promptData = await _agentsApiService.generateS2sSystemPrompt(
        provider: provider,
        agentPrompt: agentPrompt,
        greetingLine: greetingLine,
        greetingType: greetingType,
        language: language,
        knowledgeBaseIds: knowledgeBaseIds,
      );
      _logger.d('S2S system prompt generated successfully');
      return promptData;
    } on AppException catch (e) {
      _logger.e('AppException: ${e.message}');
      state = state.copyWith(error: e.message);
      rethrow;
    } catch (e) {
      _logger.e('Error generating S2S system prompt: $e');
      state = state.copyWith(error: 'Failed to generate realtime prompt');
      rethrow;
    }
  }

  Future<String> updatePromptGeneratorSystemPrompt(String systemPrompt) async {
    try {
      _logger.d('Updating prompt generator system prompt...');
      final updatedPrompt = await _agentsApiService
          .updatePromptGeneratorSystemPrompt(systemPrompt);
      _logger.d('Prompt generator system prompt updated successfully');
      return updatedPrompt;
    } on AppException catch (e) {
      _logger.e('AppException: ${e.message}');
      state = state.copyWith(error: e.message);
      rethrow;
    } catch (e) {
      _logger.e('Error updating prompt generator system prompt: $e');
      state = state.copyWith(error: 'Failed to update realtime system prompt');
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final agentsProvider = StateNotifierProvider<AgentsNotifier, AgentsState>((
  ref,
) {
  final agentsApiService = ref.watch(agentsApiServiceProvider);
  final phoneNumbersApiService = ref.watch(phoneNumbersApiServiceProvider);
  return AgentsNotifier(agentsApiService, phoneNumbersApiService);
});
