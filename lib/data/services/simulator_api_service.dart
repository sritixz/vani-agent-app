import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:vani_app/core/network/dio_client.dart';

final _logger = Logger();

class SimulatorApiService {
  final DioClient _dioClient;

  SimulatorApiService(this._dioClient);

  Future<List<dynamic>> listSimulationDrafts(String agentId) async {
    _logger.d('Listing simulation drafts for agent $agentId...');
    final response = await _dioClient.get('/api/agents/$agentId/simulation-drafts');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> generateSimulationDraft(String agentId, Map<String, dynamic> draftParams) async {
    _logger.d('Generating simulation draft for agent $agentId with params: $draftParams');
    final response = await _dioClient.post(
      '/api/agents/$agentId/simulation-drafts/generate',
      data: draftParams,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> generateMorePersonas(String agentId, String draftId, int count) async {
    _logger.d('Generating $count more personas for draft $draftId...');
    final response = await _dioClient.post(
      '/api/agents/$agentId/simulation-drafts/$draftId/generate-more-personas',
      data: {'count': count},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSimulationDraft(String agentId, String draftId) async {
    _logger.d('Getting simulation draft $draftId...');
    final response = await _dioClient.get('/api/agents/$agentId/simulation-drafts/$draftId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateSimulationDraft(String agentId, String draftId, Map<String, dynamic> updateData) async {
    _logger.d('Updating simulation draft $draftId with data: $updateData');
    final response = await _dioClient.patch(
      '/api/agents/$agentId/simulation-drafts/$draftId',
      data: updateData,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> startSimulationDraft(String agentId, String draftId) async {
    _logger.d('Starting simulation draft $draftId...');
    final response = await _dioClient.post('/api/agents/$agentId/simulation-drafts/$draftId/start');
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> listSimulationRuns(String agentId) async {
    _logger.d('Listing simulation runs for agent $agentId...');
    final response = await _dioClient.get('/api/agents/$agentId/simulation-runs');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getSimulationRun(String agentId, String runId) async {
    _logger.d('Getting simulation run $runId details...');
    final response = await _dioClient.get('/api/agents/$agentId/simulation-runs/$runId');
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteSimulationRun(String agentId, String runId) async {
    _logger.d('Deleting simulation run $runId...');
    await _dioClient.delete('/api/agents/$agentId/simulation-runs/$runId');
  }

  Future<Map<String, dynamic>> getSimulationDetails(String agentId, String runId, String simulationId) async {
    _logger.d('Getting simulation details for simulation $simulationId...');
    final response = await _dioClient.get('/api/agents/$agentId/simulation-runs/$runId/simulations/$simulationId');
    return response.data as Map<String, dynamic>;
  }
}

// Provider
final simulatorApiServiceProvider = Provider<SimulatorApiService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return SimulatorApiService(dioClient);
});
