import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vani_app/core/network/api_endpoints.dart';
import 'package:vani_app/core/network/dio_client.dart';
import 'package:vani_app/models/contact_model.dart';

class ContactsApiService {
  final DioClient _dioClient;

  ContactsApiService(this._dioClient);

  Future<ContactsResponse> getContacts({
    int page = 1,
    int limit = 20,
    String? search,
    String? leadStatus,
    String? source,
    bool? hasCalls,
    bool? hasNotes,
    String? tags,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.contacts,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (leadStatus != null && leadStatus.isNotEmpty) 'lead_status': leadStatus,
        if (source != null && source.isNotEmpty) 'source': source,
        if (hasCalls != null) 'has_calls': hasCalls,
        if (hasNotes != null) 'has_notes': hasNotes,
        if (tags != null && tags.isNotEmpty) 'tags': tags,
      },
    );
    return ContactsResponse.fromJson(response.data);
  }

  Future<Contact?> updateContactStatus({
    required String phoneNumber,
    required String leadStatus,
  }) async {
    final payload = {
      'lead_status': leadStatus,
      'leadStatus': leadStatus,
      'phone_number': phoneNumber,
      'phoneNumber': phoneNumber,
    };

    try {
      final response = await _dioClient.patch(
        ApiEndpoints.updateContactStatus(phoneNumber),
        data: payload,
      );
      if (response.data != null && response.data is Map<String, dynamic>) {
        return Contact.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      // Fallback 1: Try PATCH /api/calls/contacts/status with body payload
      try {
        final response = await _dioClient.patch(
          '/api/calls/contacts/status',
          data: payload,
        );
        if (response.data != null && response.data is Map<String, dynamic>) {
          return Contact.fromJson(response.data as Map<String, dynamic>);
        }
        return null;
      } catch (e2) {
        // Fallback 2: Try POST /api/calls/contacts/status
        try {
          final response = await _dioClient.post(
            '/api/calls/contacts/status',
            data: payload,
          );
          if (response.data != null && response.data is Map<String, dynamic>) {
            return Contact.fromJson(response.data as Map<String, dynamic>);
          }
          return null;
        } catch (_) {
          return null;
        }
      }
    }
  }
}

// Provider
final contactsApiServiceProvider = Provider<ContactsApiService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ContactsApiService(dioClient);
});
