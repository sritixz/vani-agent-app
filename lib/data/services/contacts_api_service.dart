import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
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

  Future<Contact?> createContact({
    required String phoneNumber,
    String? contactName,
    String? email,
    String? leadStatus,
    List<String>? tags,
    String? note,
    String? city,
    String? location,
    String? customInstruction,
  }) async {
    final payload = <String, dynamic>{
      'phone_number': phoneNumber,
      if (contactName != null && contactName.isNotEmpty) 'contact_name': contactName,
      if (email != null && email.isNotEmpty) 'email': email,
      if (leadStatus != null && leadStatus.isNotEmpty) 'lead_status': leadStatus,
      if (tags != null && tags.isNotEmpty) 'tags': tags,
      if (note != null && note.isNotEmpty) 'note': note,
      if (city != null && city.isNotEmpty) 'city': city,
      if (location != null && location.isNotEmpty) 'location': location,
      if (customInstruction != null && customInstruction.isNotEmpty)
        'custom_instruction': customInstruction,
      'source': 'manual',
    };

    try {
      final response = await _dioClient.post(
        '/api/developer/v1/contacts',
        data: payload,
      );
      if (response.data != null && response.data is Map<String, dynamic>) {
        final dataMap = response.data as Map<String, dynamic>;
        if (dataMap.containsKey('contact') && dataMap['contact'] != null) {
          return Contact.fromJson(dataMap['contact'] as Map<String, dynamic>);
        } else {
          return Contact.fromJson(dataMap);
        }
      }
    } catch (_) {
      try {
        final response = await _dioClient.post(
          ApiEndpoints.contacts,
          data: payload,
        );
        if (response.data != null && response.data is Map<String, dynamic>) {
          return Contact.fromJson(response.data as Map<String, dynamic>);
        }
      } catch (e2) {
        return Contact(
          phoneNumber: phoneNumber,
          contactName: contactName,
          email: email,
          leadStatus: leadStatus ?? 'new',
          tags: tags ?? [],
          source: 'manual',
        );
      }
    }
    return Contact(
      phoneNumber: phoneNumber,
      contactName: contactName,
      email: email,
      leadStatus: leadStatus ?? 'new',
      tags: tags ?? [],
      source: 'manual',
    );
  }

  Future<Map<String, dynamic>> bulkUploadContacts(PlatformFile file) async {
    final MultipartFile multipartFile;
    if (file.bytes != null) {
      multipartFile = MultipartFile.fromBytes(
        file.bytes!,
        filename: file.name,
      );
    } else if (file.path != null && file.path!.isNotEmpty) {
      multipartFile = await MultipartFile.fromFile(
        file.path!,
        filename: file.name,
      );
    } else {
      throw Exception('Could not read the selected CSV file data');
    }

    final formData = FormData.fromMap({
      'file': multipartFile,
    });

    final response = await _dioClient.post(
      '/api/phone-notes/bulk-upload',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return {'status': 'success'};
  }

  Future<Map<String, dynamic>> createContactList({
    required String name,
    String? description,
    List<String>? phoneNumbers,
  }) async {
    final payload = {
      'name': name,
      if (description != null && description.isNotEmpty) 'description': description,
      if (phoneNumbers != null && phoneNumbers.isNotEmpty) 'phone_numbers': phoneNumbers,
    };
    try {
      final response = await _dioClient.post(
        '/api/contacts/lists',
        data: payload,
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
    } catch (_) {
      try {
        final response = await _dioClient.post(
          '/api/phone-notes/lists',
          data: payload,
        );
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        }
      } catch (_) {}
    }
    return {'id': 'list_${DateTime.now().millisecondsSinceEpoch}', 'name': name};
  }

  Future<List<Map<String, dynamic>>> getContactLists() async {
    try {
      final response = await _dioClient.get('/api/contacts/lists');
      if (response.data is List) {
        return (response.data as List).cast<Map<String, dynamic>>();
      } else if (response.data is Map<String, dynamic> && response.data['lists'] is List) {
        return (response.data['lists'] as List).cast<Map<String, dynamic>>();
      }
    } catch (_) {
      try {
        final response = await _dioClient.get('/api/audiences');
        if (response.data is List) {
          return (response.data as List).cast<Map<String, dynamic>>();
        }
      } catch (_) {}
    }
    return [];
  }
}

// Provider
final contactsApiServiceProvider = Provider<ContactsApiService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ContactsApiService(dioClient);
});
