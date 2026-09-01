import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vani_app/core/network/api_endpoints.dart';
import 'package:vani_app/core/network/dio_client.dart';
import 'package:vani_app/data/models/calls/call_history_model.dart';
import 'package:vani_app/data/models/calls/call_statistics_model.dart';

class CallsApiService {
  final DioClient _dioClient;

  CallsApiService(this._dioClient);

  Future<CallHistoryResponse> getCallHistory({
    int? page,
    int? limit,
    String? startDate,
    String? endDate,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.callHistory,
      queryParameters: {
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      },
    );
    return CallHistoryResponse.fromJson(response.data);
  }

  Future<CallStatisticsModel> getCallStatistics({
    String? period,
    String? startDate,
    String? endDate,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.callStatistics,
      queryParameters: {
        if (period != null) 'period': period,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      },
    );
    return CallStatisticsModel.fromJson(response.data);
  }

  Future<List<dynamic>> getCallContacts() async {
    final response = await _dioClient.get(ApiEndpoints.callContacts);
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> validateCall(Map<String, dynamic> data) async {
    final response = await _dioClient.post(
      ApiEndpoints.validateCall,
      data: data,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> downloadRecording(String callId, {bool force = false}) async {
    final response = await _dioClient.post(
      ApiEndpoints.downloadRecording(callId),
      queryParameters: {
        if (force) 'force': force,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> regenerateSummary(String callId) async {
    final response = await _dioClient.post(
      ApiEndpoints.regenerateSummary(callId),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> sendCall({
    required String agentId,
    required String phoneNumber,
    String? contactName,
    String? customInstruction,
    int retryCount = 1,
  }) async {
    final response = await _dioClient.post(
      ApiEndpoints.sendCall,
      data: {
        'agent_id': agentId,
        'phone_number': phoneNumber,
        if (contactName != null && contactName.isNotEmpty) 'contact_name': contactName,
        if (customInstruction != null && customInstruction.isNotEmpty)
          'custom_instruction': customInstruction,
        'retry_count': retryCount,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}

// Provider
final callsApiServiceProvider = Provider<CallsApiService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return CallsApiService(dioClient);
});
