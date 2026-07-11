import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:vani_app/core/network/api_endpoints.dart';
import 'package:vani_app/core/network/dio_client.dart';
import 'package:vani_app/models/knowledge_base_model.dart';

final _logger = Logger();

class KnowledgeApiService {
  final DioClient _dioClient;

  KnowledgeApiService(this._dioClient);

  Future<List<KnowledgeBase>> getKnowledgeBases() async {
    _logger.d('Fetching knowledge bases...');
    final response = await _dioClient.get(ApiEndpoints.knowledge);
    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((json) => KnowledgeBase.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<KnowledgeBase> createKnowledgeBase(Map<String, dynamic> kbData) async {
    _logger.d('Creating knowledge base with data: $kbData');
    final response = await _dioClient.post(
      ApiEndpoints.knowledge,
      data: kbData,
    );
    _logger.d('Create knowledge base response: ${response.data}');
    return KnowledgeBase.fromJson(response.data as Map<String, dynamic>);
  }
}

// Provider
final knowledgeApiServiceProvider = Provider<KnowledgeApiService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return KnowledgeApiService(dioClient);
});
