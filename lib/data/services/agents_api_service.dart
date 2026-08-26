import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:vani_app/core/network/api_endpoints.dart';
import 'package:vani_app/core/network/dio_client.dart';
import 'package:vani_app/models/agent_model.dart';

final _logger = Logger();

class AgentsApiService {
  final DioClient _dioClient;

  AgentsApiService(this._dioClient);

  Future<List<Agent>> getAgents() async {
    final response = await _dioClient.get(ApiEndpoints.agents);
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((json) => Agent.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<dynamic>> getOmnivoiceProfiles() async {
    try {
      final response = await _dioClient.get('/api/omnivoice/profiles');
      if (response.data is List) {
        return response.data as List<dynamic>;
      }
      return [];
    } catch (e) {
      _logger.e('Failed to fetch omnivoice profiles from API: $e');
      return [];
    }
  }

  Future<Agent> getAgent(String agentId) async {
    final response = await _dioClient.get(ApiEndpoints.agent(agentId));
    return Agent.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Agent> createAgent(Map<String, dynamic> agentData) async {
    _logger.d('Creating agent with data: $agentData');
    final response = await _dioClient.post(
      ApiEndpoints.agents,
      data: agentData,
      options: Options(
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 120),
      ),
    );
    _logger.d('Create response: ${response.data}');
    return Agent.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Agent> updateAgent(
    String agentId,
    Map<String, dynamic> agentData,
  ) async {
    _logger.d('=== AGENTS API SERVICE UPDATE ===');
    _logger.d('Agent ID: $agentId');
    _logger.d('Endpoint: ${ApiEndpoints.agent(agentId)}');
    _logger.d('Request Data: $agentData');
    _logger.d('Request Data Keys: ${agentData.keys.toList()}');
    _logger.d('Request Data Values: ${agentData.values.toList()}');

    try {
      final response = await _dioClient.patch(
        ApiEndpoints.agent(agentId),
        data: agentData,
        options: Options(
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 120),
        ),
      );

      _logger.d('Response Status Code: ${response.statusCode}');
      _logger.d('Response Headers: ${response.headers}');
      _logger.d('Response Data: ${response.data}');
      _logger.d('Response Data Type: ${response.data.runtimeType}');
      _logger.d('=== UPDATE SUCCESSFUL ===');

      return Agent.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      _logger.e('=== UPDATE FAILED ===');
      _logger.e('Error: $e');
      _logger.e('Stack Trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> deleteAgent(String agentId) async {
    await _dioClient.delete(ApiEndpoints.agent(agentId));
  }

  Future<Map<String, dynamic>> generateAnalysisConfig(
    String agentPrompt,
  ) async {
    final response = await _dioClient.post(
      ApiEndpoints.generateAnalysisConfig,
      data: {'agent_prompt': agentPrompt},
      options: Options(
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 120),
      ),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<String> generateAnalysisPrompt(String agentPrompt) async {
    final response = await _dioClient.post(
      ApiEndpoints.generateAnalysisPrompt,
      data: {'agent_prompt': agentPrompt},
      options: Options(
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 120),
      ),
    );
    return response.data['analysis_prompt'] as String;
  }

  Future<Map<String, dynamic>> generateS2sSystemPrompt({
    required String provider,
    required String agentPrompt,
    String? greetingLine,
    required String greetingType,
    required String language,
    required List<String> knowledgeBaseIds,
  }) async {
    final response = await _dioClient.post(
      ApiEndpoints.generateS2sSystemPrompt,
      data: {
        'provider': provider,
        'agent_prompt': agentPrompt,
        'greeting_line': greetingLine,
        'greeting_type': greetingType,
        'language': language,
        'knowledge_base_ids': knowledgeBaseIds,
      },
      options: Options(
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 120),
      ),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<String> getPromptGeneratorSystemPrompt() async {
    final response = await _dioClient.get(ApiEndpoints.promptGeneratorSettings);
    return response.data['system_prompt'] as String? ?? '';
  }

  Future<String> updatePromptGeneratorSystemPrompt(String systemPrompt) async {
    final response = await _dioClient.put(
      ApiEndpoints.promptGeneratorSettings,
      data: {'system_prompt': systemPrompt},
      options: Options(
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 120),
      ),
    );
    return response.data['system_prompt'] as String? ?? '';
  }
}

// Provider
final agentsApiServiceProvider = Provider<AgentsApiService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AgentsApiService(dioClient);
});
