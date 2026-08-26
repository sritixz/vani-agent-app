import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vani_app/core/network/api_endpoints.dart';
import 'package:vani_app/core/network/dio_client.dart';
import 'package:vani_app/models/campaign_model.dart';
import 'package:vani_app/models/campaign_number_model.dart';

class CampaignsApiService {
  final DioClient _dioClient;

  CampaignsApiService(this._dioClient);

  Future<List<Campaign>> getCampaigns({
    String? search,
    String? status,
    String? createdFrom,
    String? createdTill,
  }) async {
    final queryParameters = <String, dynamic>{};
    
    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }
    if (createdFrom != null && createdFrom.isNotEmpty) {
      queryParameters['createdFrom'] = createdFrom;
    }
    if (createdTill != null && createdTill.isNotEmpty) {
      queryParameters['createdTill'] = createdTill;
    }

    final response = await _dioClient.get(
      ApiEndpoints.campaigns,
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
    );
    
    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((json) => Campaign.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Campaign> getCampaign(String campaignId) async {
    final response = await _dioClient.get(ApiEndpoints.campaign(campaignId));
    return Campaign.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Campaign> createCampaign(Map<String, dynamic> campaignData) async {
    // Convert to FormData for multipart/form-data
    final formData = FormData.fromMap(campaignData);
    
    final response = await _dioClient.post(
      ApiEndpoints.campaigns,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );
    return Campaign.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Campaign> updateCampaign(String campaignId, Map<String, dynamic> campaignData) async {
    final response = await _dioClient.patch(
      ApiEndpoints.campaign(campaignId),
      data: campaignData,
    );
    return Campaign.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteCampaign(String campaignId) async {
    await _dioClient.delete(ApiEndpoints.campaign(campaignId));
  }

  Future<Campaign> pauseCampaign(String campaignId) async {
    final response = await _dioClient.post(ApiEndpoints.campaignPause(campaignId));
    return Campaign.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Campaign> resumeCampaign(String campaignId) async {
    final response = await _dioClient.post(ApiEndpoints.campaignResume(campaignId));
    return Campaign.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> syncCampaign(String campaignId) async {
    await _dioClient.post(ApiEndpoints.campaignSync(campaignId));
  }

  Future<List<String>> getGsheetHeaders(String campaignId) async {
    final response = await _dioClient.get(ApiEndpoints.campaignGsheetHeaders(campaignId));
    // API returns {"header_name": {}, ...} — keys are the column header names
    final Map<String, dynamic> data = response.data as Map<String, dynamic>;
    return data.keys.toList();
  }

  Future<List<CampaignNumber>> getCampaignNumbers(
    String campaignId, {
    String? filter,
    String? sentiment,
  }) async {
    final queryParameters = <String, dynamic>{};
    
    if (filter != null && filter.isNotEmpty) {
      queryParameters['filter'] = filter;
    }
    if (sentiment != null && sentiment.isNotEmpty) {
      queryParameters['sentiment'] = sentiment;
    }

    final response = await _dioClient.get(
      ApiEndpoints.campaignNumbers(campaignId),
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
    );
    
    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((json) => CampaignNumber.fromJson(json as Map<String, dynamic>)).toList();
  }
}

// Provider
final campaignsApiServiceProvider = Provider<CampaignsApiService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return CampaignsApiService(dioClient);
});
