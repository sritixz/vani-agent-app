enum ContactStatus {
  newLead,
  attempting,
  connected,
  doNotCall,
}

class Contact {
  final String phoneNumber;
  final String? contactName;
  final String? email;
  final String? city;
  final String? location;
  final String? source;
  final String? leadStatus;
  final String? customInstruction;
  final List<String> tags;
  final int notesCount;
  final int totalCalls;
  final int completedCalls;
  final int failedCalls;
  final String? lastCallAt;

  Contact({
    required this.phoneNumber,
    this.contactName,
    this.email,
    this.city,
    this.location,
    this.source,
    this.leadStatus,
    this.customInstruction,
    this.tags = const [],
    this.notesCount = 0,
    this.totalCalls = 0,
    this.completedCalls = 0,
    this.failedCalls = 0,
    this.lastCallAt,
  });

  Contact copyWith({
    String? phoneNumber,
    String? contactName,
    String? email,
    String? city,
    String? location,
    String? source,
    String? leadStatus,
    String? customInstruction,
    List<String>? tags,
    int? notesCount,
    int? totalCalls,
    int? completedCalls,
    int? failedCalls,
    String? lastCallAt,
  }) {
    return Contact(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      contactName: contactName ?? this.contactName,
      email: email ?? this.email,
      city: city ?? this.city,
      location: location ?? this.location,
      source: source ?? this.source,
      leadStatus: leadStatus ?? this.leadStatus,
      customInstruction: customInstruction ?? this.customInstruction,
      tags: tags ?? this.tags,
      notesCount: notesCount ?? this.notesCount,
      totalCalls: totalCalls ?? this.totalCalls,
      completedCalls: completedCalls ?? this.completedCalls,
      failedCalls: failedCalls ?? this.failedCalls,
      lastCallAt: lastCallAt ?? this.lastCallAt,
    );
  }

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      phoneNumber: json['phone_number'] as String,
      contactName: json['contact_name'] as String?,
      email: json['email'] as String?,
      city: json['city'] as String?,
      location: json['location'] as String?,
      source: json['source'] as String?,
      leadStatus: json['lead_status'] as String?,
      customInstruction: json['custom_instruction'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      notesCount: json['notes_count'] as int? ?? 0,
      totalCalls: json['total_calls'] as int? ?? 0,
      completedCalls: json['completed_calls'] as int? ?? 0,
      failedCalls: json['failed_calls'] as int? ?? 0,
      lastCallAt: json['last_call_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone_number': phoneNumber,
      'contact_name': contactName,
      'email': email,
      'city': city,
      'location': location,
      'source': source,
      'lead_status': leadStatus,
      'custom_instruction': customInstruction,
      'tags': tags,
      'notes_count': notesCount,
      'total_calls': totalCalls,
      'completed_calls': completedCalls,
      'failed_calls': failedCalls,
      'last_call_at': lastCallAt,
    };
  }

  String get displayName => contactName ?? phoneNumber;

  String get initials {
    if (contactName != null && contactName!.isNotEmpty) {
      final parts = contactName!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return contactName!.substring(0, 1).toUpperCase();
    }
    return phoneNumber.substring(0, 2);
  }

  ContactStatus get status {
    if (leadStatus == null) return ContactStatus.newLead;
    
    switch (leadStatus!.toLowerCase()) {
      case 'new':
      case 'new_lead':
      case 'new lead':
        return ContactStatus.newLead;
      case 'attempting':
        return ContactStatus.attempting;
      case 'connected':
        return ContactStatus.connected;
      case 'do_not_call':
      case 'do not call':
      case 'junk_dnc':
      case 'junk/dnc':
      case 'not_interested':
        return ContactStatus.doNotCall;
      default:
        return ContactStatus.newLead;
    }
  }
}

class ContactsResponse {
  final List<Contact> contacts;
  final int total;
  final int page;
  final int pages;

  ContactsResponse({
    required this.contacts,
    required this.total,
    required this.page,
    required this.pages,
  });

  factory ContactsResponse.fromJson(Map<String, dynamic> json) {
    return ContactsResponse(
      contacts: (json['contacts'] as List<dynamic>)
          .map((e) => Contact.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      pages: json['pages'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contacts': contacts.map((e) => e.toJson()).toList(),
      'total': total,
      'page': page,
      'pages': pages,
    };
  }
}
