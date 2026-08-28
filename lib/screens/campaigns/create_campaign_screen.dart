import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:vani_app/config/theme.dart';
import 'package:vani_app/data/services/campaigns_api_service.dart';
import 'package:vani_app/models/campaign_model.dart';
import 'package:vani_app/presentation/providers/agents_provider.dart';

class PreviewRecord {
  final String phone;
  final String formattedPhone;
  final String name;
  final String customInstruction;
  final bool isValid;

  PreviewRecord({
    required this.phone,
    required this.formattedPhone,
    required this.name,
    required this.customInstruction,
    required this.isValid,
  });
}

class CreateCampaignScreen extends ConsumerStatefulWidget {
  final Campaign? campaign; // For editing existing campaign

  const CreateCampaignScreen({super.key, this.campaign});

  @override
  ConsumerState<CreateCampaignScreen> createState() => _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends ConsumerState<CreateCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _agentNameController = TextEditingController();
  final _agentIdController = TextEditingController();
  final _retriesController = TextEditingController(text: '3');
  final _customFirstLineController = TextEditingController();
  final _startDateTimeController = TextEditingController();
  final _endDateTimeController = TextEditingController();
  final _timeZoneController = TextEditingController(text: 'UTC');
  
  DateTime? _startDateTime;
  DateTime? _endDateTime;
  
  PlatformFile? _selectedFile;
  List<PreviewRecord> _previewRecords = [];
  bool _hideInvalidNumbers = false;
  bool _isLoading = false;

  // Tier 1 Switches
  bool _multiNumberRotation = false;
  bool _autoFollowupCall = false;
  bool _sendWhatsappMessage = false;

  // Tier 2 Contact Source Tabs & Campaign Types
  String _selectedContactTab = 'Upload File'; // 'Upload File', 'Google Sheet', 'Contact Stream', 'Contact Lists'
  final _gsheetUrlController = TextEditingController();
  final _contactStreamUrlController = TextEditingController();
  String? _selectedContactListId;

  String _selectedCampaignType = 'standard'; // 'standard', 'quick_qualify'
  String _selectedTimezone = 'Asia/Kolkata';

  final List<String> _timezones = [
    'Asia/Kolkata',
    'UTC',
    'America/New_York',
    'America/Los_Angeles',
    'Europe/London',
    'Asia/Dubai',
    'Singapore',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.campaign != null) {
      _populateFields(widget.campaign!);
    }
  }

  void _populateFields(Campaign campaign) {
    _nameController.text = campaign.name;
    _agentNameController.text = campaign.agentName;
    _agentIdController.text = campaign.agentId;
    _retriesController.text = campaign.retries.toString();
    _customFirstLineController.text = campaign.customFirstLine ?? '';
    
    if (campaign.startDateTime != null) {
      _startDateTime = DateTime.tryParse(campaign.startDateTime!);
      _startDateTimeController.text = _formatDateTimeForDisplay(_startDateTime);
    }
    if (campaign.endDateTime != null) {
      _endDateTime = DateTime.tryParse(campaign.endDateTime!);
      _endDateTimeController.text = _formatDateTimeForDisplay(_endDateTime);
    }
    
    _timeZoneController.text = campaign.timeZone ?? 'UTC';
  }

  String _formatDateTimeForDisplay(DateTime? dateTime) {
    if (dateTime == null) return '';
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _agentNameController.dispose();
    _agentIdController.dispose();
    _retriesController.dispose();
    _customFirstLineController.dispose();
    _startDateTimeController.dispose();
    _endDateTimeController.dispose();
    _timeZoneController.dispose();
    _gsheetUrlController.dispose();
    _contactStreamUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _selectedFile = file;
        });
        await _parseFileRecords(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _previewRecords.clear();
    });
  }

  Future<void> _parseFileRecords(PlatformFile file) async {
    try {
      Uint8List? bytes = file.bytes;
      if (bytes == null && file.path != null && file.path!.isNotEmpty) {
        final f = File(file.path!);
        if (await f.exists()) {
          bytes = await f.readAsBytes();
        }
      }

      if (bytes == null || bytes.isEmpty) return;

      final content = String.fromCharCodes(bytes);
      final lines = content
          .split(RegExp(r'\r?\n'))
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      if (lines.isEmpty) return;

      final headers = lines.first.toLowerCase().split(',').map((h) => h.trim().replaceAll('"', '')).toList();

      int phoneIdx = headers.indexWhere((h) => h.contains('phone') || h.contains('mobile') || h.contains('number'));
      int nameIdx = headers.indexWhere((h) => h.contains('name') || h.contains('contact'));
      int instructionIdx = headers.indexWhere((h) => h.contains('instruction') || h.contains('note') || h.contains('custom'));

      if (phoneIdx == -1) phoneIdx = 0;
      if (nameIdx == -1) nameIdx = 1 < headers.length ? 1 : -1;
      if (instructionIdx == -1) instructionIdx = 2 < headers.length ? 2 : -1;

      final records = <PreviewRecord>[];

      for (int i = 1; i < lines.length; i++) {
        final cols = _splitCsvLine(lines[i]);
        if (cols.isEmpty) continue;

        final rawPhone = phoneIdx < cols.length ? cols[phoneIdx].trim() : '';
        final rawName = nameIdx != -1 && nameIdx < cols.length ? cols[nameIdx].trim() : '';
        final rawInstruction = instructionIdx != -1 && instructionIdx < cols.length ? cols[instructionIdx].trim() : '';

        if (rawPhone.isEmpty && rawName.isEmpty) continue;

        String cleanPhone = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');
        if (!cleanPhone.startsWith('+') && cleanPhone.length == 10) {
          cleanPhone = '+91$cleanPhone';
        } else if (!cleanPhone.startsWith('+') && cleanPhone.length == 12 && cleanPhone.startsWith('91')) {
          cleanPhone = '+$cleanPhone';
        }

        final isValid = cleanPhone.length >= 10 && (cleanPhone.startsWith('+') || RegExp(r'^\d+$').hasMatch(cleanPhone));

        records.add(PreviewRecord(
          phone: rawPhone,
          formattedPhone: cleanPhone.isNotEmpty ? cleanPhone : rawPhone,
          name: rawName,
          customInstruction: rawInstruction,
          isValid: isValid,
        ));
      }

      setState(() {
        _previewRecords = records;
      });
    } catch (_) {}
  }

  List<String> _splitCsvLine(String line) {
    final result = <String>[];
    bool inQuotes = false;
    final sb = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        inQuotes = !inQuotes;
      } else if (c == ',' && !inQuotes) {
        result.add(sb.toString().trim());
        sb.clear();
      } else {
        sb.write(c);
      }
    }
    result.add(sb.toString().trim());
    return result;
  }

  void _showDataPreviewDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final recordsToDisplay = _hideInvalidNumbers
                ? _previewRecords.where((r) => r.isValid).toList()
                : _previewRecords;

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(maxHeight: 550),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.lightGrey,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.poll_outlined, size: 20, color: AppTheme.darkGrey),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Data Preview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkGrey)),
                              Text(
                                'Previewing ${recordsToDisplay.length} records',
                                style: const TextStyle(fontSize: 11, color: AppTheme.mediumGrey),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Checkbox(
                              value: _hideInvalidNumbers,
                              activeColor: AppTheme.primaryGreen,
                              onChanged: (val) {
                                setModalState(() {
                                  _hideInvalidNumbers = val ?? false;
                                });
                                setState(() {
                                  _hideInvalidNumbers = val ?? false;
                                });
                              },
                            ),
                            const Text('Hide Invalid', style: TextStyle(fontSize: 10, color: AppTheme.mediumGrey)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      color: AppTheme.lightGrey,
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: Text('PHONE NUMBER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.mediumGrey))),
                          Expanded(flex: 2, child: Text('NAME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.mediumGrey))),
                          Expanded(flex: 4, child: Text('CUSTOM_INSTRUCTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.mediumGrey))),
                        ],
                      ),
                    ),

                    Expanded(
                      child: recordsToDisplay.isEmpty
                          ? const Center(
                              child: Text('No records to display', style: TextStyle(fontSize: 12, color: AppTheme.mediumGrey)),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: recordsToDisplay.length,
                              separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5),
                              itemBuilder: (context, idx) {
                                final r = recordsToDisplay[idx];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(r.formattedPhone, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.darkGrey)),
                                            if (r.isValid) ...[
                                              const SizedBox(height: 2),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.lightGreen,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text('E.164 CLEANED', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          r.name.isNotEmpty ? r.name : '-',
                                          style: const TextStyle(fontSize: 11, color: AppTheme.darkGrey),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 4,
                                        child: Text(
                                          r.customInstruction.isNotEmpty ? r.customInstruction : '-',
                                          style: const TextStyle(fontSize: 10, color: AppTheme.mediumGrey),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),

                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(Icons.info_outline, size: 12, color: AppTheme.mediumGrey),
                        SizedBox(width: 4),
                        Text('Preview shows cleaned phone numbers in E.164 format.', style: TextStyle(fontSize: 9, color: AppTheme.mediumGrey)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _removeFile();
                          },
                          icon: const Icon(Icons.delete_outline, size: 14, color: AppTheme.errorRed),
                          label: const Text('Remove File', style: TextStyle(fontSize: 11, color: AppTheme.errorRed, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.errorRed),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: const Text('Close Preview', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _selectDateTime(TextEditingController controller, bool isStart) async {
    final currentDateTime = isStart ? _startDateTime : _endDateTime;
    final initialDate = currentDateTime ?? DateTime.now();
    
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (time != null) {
        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        
        setState(() {
          if (isStart) {
            _startDateTime = dateTime;
            _startDateTimeController.text = _formatDateTimeForDisplay(dateTime);
          } else {
            _endDateTime = dateTime;
            _endDateTimeController.text = _formatDateTimeForDisplay(dateTime);
          }
        });
      }
    }
  }

  Future<void> _saveCampaign() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.campaign == null) {
      if (_selectedContactTab == 'Upload File' && _selectedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a contact file')),
        );
        return;
      } else if (_selectedContactTab == 'Google Sheet' && _gsheetUrlController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a Google Sheet URL')),
        );
        return;
      } else if (_selectedContactTab == 'Contact Stream' && _contactStreamUrlController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a Contact Stream Webhook URL')),
        );
        return;
      } else if (_selectedContactTab == 'Contact Lists' && _selectedContactListId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a contact list')),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(campaignsApiServiceProvider);
      final contactSourceMap = {
        'Upload File': 'file',
        'Google Sheet': 'gsheet',
        'Contact Stream': 'stream',
        'Contact Lists': 'list',
      };

      final campaignData = <String, dynamic>{
        'name': _nameController.text,
        'agent_id': _agentIdController.text,
        'agentId': _agentIdController.text,
        'retries': _retriesController.text,
        'contact_source': contactSourceMap[_selectedContactTab] ?? 'file',
        'campaign_type': _selectedCampaignType,
        'auto_followup_enabled': _autoFollowupCall ? 'true' : 'false',
        'whatsapp_automation_enabled': _sendWhatsappMessage ? 'true' : 'false',
        if (_multiNumberRotation) 'number_rotation_strategy': 'round_robin',
      };

      if (_selectedContactTab == 'Google Sheet') {
        campaignData['gsheet_url'] = _gsheetUrlController.text.trim();
        campaignData['gsheet_column_phone'] = 'phone_number';
        campaignData['gsheet_column_name'] = 'contact_name';
        campaignData['gsheet_column_instruction'] = 'notes';
        campaignData['gsheet_sync_interval_minutes'] = '60';
      } else if (_selectedContactTab == 'Contact Stream') {
        campaignData['stream_mode'] = 'realtime';
        campaignData['stream_source_filter'] = _contactStreamUrlController.text.trim().isNotEmpty
            ? _contactStreamUrlController.text.trim()
            : 'all';
        campaignData['stream_lead_status_filter'] = 'all';
      } else if (_selectedContactTab == 'Contact Lists') {
        campaignData['contact_list_id'] = _selectedContactListId;
      }

      if (_customFirstLineController.text.isNotEmpty) {
        campaignData['custom_first_line'] = _customFirstLineController.text;
      }
      if (_startDateTime != null) {
        campaignData['start_date_time'] = _startDateTime!.toIso8601String();
      }
      if (_endDateTime != null) {
        campaignData['end_date_time'] = _endDateTime!.toIso8601String();
      }
      if (_timeZoneController.text.isNotEmpty) {
        campaignData['time_zone'] = _timeZoneController.text;
      }

      if (_selectedFile != null && _selectedContactTab == 'Upload File') {
        Uint8List? fileBytes = _selectedFile!.bytes;
        final filePath = _selectedFile!.path;

        if (fileBytes == null && filePath != null && filePath.isNotEmpty) {
          try {
            final file = File(filePath);
            if (await file.exists()) {
              fileBytes = await file.readAsBytes();
            }
          } catch (_) {}
        }

        final fileName = _selectedFile!.name;
        final extension = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
        MediaType mediaType;
        if (extension == 'xlsx') {
          mediaType = MediaType('application', 'vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        } else if (extension == 'xls') {
          mediaType = MediaType('application', 'vnd.ms-excel');
        } else {
          mediaType = MediaType('text', 'csv');
        }

        if (fileBytes != null && fileBytes.isNotEmpty) {
          campaignData['contact_file'] = MultipartFile.fromBytes(
            fileBytes,
            filename: fileName,
            contentType: mediaType,
          );
        } else if (filePath != null && filePath.isNotEmpty) {
          campaignData['contact_file'] = await MultipartFile.fromFile(
            filePath,
            filename: fileName,
            contentType: mediaType,
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error: Unable to read selected file. Please select the file again.'),
                backgroundColor: AppTheme.errorRed,
              ),
            );
          }
          return;
        }
      }

      if (widget.campaign == null) {
        // Create new campaign
        await service.createCampaign(campaignData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Campaign created successfully')),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        // Update existing campaign
        await service.updateCampaign(widget.campaign!.id, campaignData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Campaign updated successfully')),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final agentsState = ref.watch(agentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.campaign == null ? 'Start a Campaign' : 'Edit Campaign'),
        backgroundColor: AppTheme.surfaceCard,
        foregroundColor: AppTheme.darkGrey,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Campaign Essentials Section Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderGrey),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Campaign Essentials', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.darkGrey)),
                    const SizedBox(height: 12),
                    // Campaign Designation Input
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'CAMPAIGN DESIGNATION *',
                        hintText: 'Enter Campaign Name',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter campaign name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Assigned Voice Expert Dropdown Selector
                    DropdownButtonFormField<String>(
                      value: _agentIdController.text.isNotEmpty ? _agentIdController.text : null,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'ASSIGNED VOICE EXPERT *',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      hint: const Text('Select Voice Expert', style: TextStyle(fontSize: 13)),
                      items: agentsState.agents.map((ag) {
                        return DropdownMenuItem<String>(
                          value: ag.id,
                          child: Text(
                            '${ag.name} (${ag.voice})',
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      }).toList(),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Please select a voice expert';
                        }
                        return null;
                      },
                      onChanged: widget.campaign != null
                          ? null
                          : (val) {
                              if (val != null) {
                                final selected = agentsState.agents.firstWhere((a) => a.id == val);
                                setState(() {
                                  _agentIdController.text = val;
                                  _agentNameController.text = selected.name;
                                });
                              }
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Multi-Number Rotation Switch (Web App Alignment)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.lightGrey,
                  border: Border.all(color: AppTheme.borderGrey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sync_alt, color: AppTheme.mediumGrey, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Multi-Number Rotation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkGrey)),
                          Text('Distribute call load across multiple outbound numbers', style: TextStyle(fontSize: 10, color: AppTheme.mediumGrey)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _multiNumberRotation,
                      activeColor: AppTheme.primaryGreen,
                      onChanged: (val) => setState(() => _multiNumberRotation = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4-Tab Contact Source Selector Card
              if (widget.campaign == null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderGrey),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Contacts Source', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.darkGrey)),
                      const SizedBox(height: 12),

                      // Source Tab Selection Bar
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['Upload File', 'Google Sheet', 'Contact Stream', 'Contact Lists'].map((tab) {
                            final isSelected = tab == _selectedContactTab;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(tab, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppTheme.darkGrey)),
                                selected: isSelected,
                                selectedColor: AppTheme.primaryGreen,
                                backgroundColor: AppTheme.lightGrey,
                                onSelected: (val) {
                                  if (val) setState(() => _selectedContactTab = tab);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tab Content Rendering
                      if (_selectedContactTab == 'Upload File') ...[
                        if (_selectedFile == null)
                          InkWell(
                            onTap: _pickFile,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.lightGrey,
                                border: Border.all(color: AppTheme.borderGrey, style: BorderStyle.solid),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.upload_file, color: AppTheme.primaryGreen, size: 36),
                                  SizedBox(height: 8),
                                  Text(
                                    'Upload Contact Spreadsheet',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkGrey),
                                  ),
                                  SizedBox(height: 2),
                                  Text('Excel (.xlsx, .xls, .csv) files only', style: TextStyle(fontSize: 10, color: AppTheme.mediumGrey)),
                                ],
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.borderGrey),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppTheme.darkGrey, width: 1.5),
                                  ),
                                  child: const Icon(Icons.check, size: 14, color: AppTheme.darkGrey),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Data Loaded Successfully',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkGrey),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_previewRecords.isEmpty ? "1" : _previewRecords.length} records detected',
                                        style: const TextStyle(fontSize: 11, color: AppTheme.mediumGrey),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _showDataPreviewDialog(context),
                                  icon: const Icon(Icons.visibility_outlined, size: 14),
                                  label: const Text('Preview Data', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    elevation: 0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Downloading sample campaign manifest template...'), backgroundColor: AppTheme.primaryGreen),
                            );
                          },
                          icon: const Icon(Icons.download, size: 14, color: AppTheme.primaryGreen),
                          label: const Text('Download campaign manifest template by clicking here', style: TextStyle(fontSize: 11, color: AppTheme.primaryGreen)),
                        ),
                      ] else if (_selectedContactTab == 'Google Sheet') ...[
                        TextFormField(
                          controller: _gsheetUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Google Sheet Spreadsheet URL *',
                            hintText: 'https://docs.google.com/spreadsheets/d/...',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.table_chart, color: AppTheme.primaryGreen),
                          ),
                        ),
                      ] else if (_selectedContactTab == 'Contact Stream') ...[
                        TextFormField(
                          controller: _contactStreamUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Realtime Contact Stream Webhook URL',
                            hintText: 'https://api.vaniagent.com/webhooks/contacts',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.stream, color: Colors.blue),
                          ),
                        ),
                      ] else if (_selectedContactTab == 'Contact Lists') ...[
                        DropdownButtonFormField<String>(
                          value: _selectedContactListId,
                          decoration: const InputDecoration(
                            labelText: 'Select Saved Contact List *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.contacts, color: Colors.purple),
                          ),
                          hint: const Text('Choose list from CRM'),
                          items: const [
                            DropdownMenuItem(value: 'list_1', child: Text('Q3 Real Estate Leads (500 contacts)')),
                            DropdownMenuItem(value: 'list_2', child: Text('Healthcare Followup List (250 contacts)')),
                          ],
                          onChanged: (val) => setState(() => _selectedContactListId = val),
                        ),
                      ],
                    ],
                  ),
                ),
              if (widget.campaign == null) const SizedBox(height: 16),

              // Campaign Type Cards Section (Standard vs Quick Qualify)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderGrey),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Campaign Type', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.darkGrey)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Standard Card
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedCampaignType = 'standard'),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _selectedCampaignType == 'standard' ? AppTheme.lightGreen : AppTheme.lightGrey,
                                border: Border.all(color: _selectedCampaignType == 'standard' ? AppTheme.primaryGreen : AppTheme.borderGrey, width: 1.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.phone_forwarded, size: 16, color: _selectedCampaignType == 'standard' ? AppTheme.primaryGreen : AppTheme.mediumGrey),
                                      const SizedBox(width: 4),
                                      const Text('Standard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkGrey)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const Text('Fixed retries, scheduled start/end times', style: TextStyle(fontSize: 10, color: AppTheme.mediumGrey)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Quick Qualify Card
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedCampaignType = 'quick_qualify'),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _selectedCampaignType == 'quick_qualify' ? Colors.purple.withOpacity(0.1) : AppTheme.lightGrey,
                                border: Border.all(color: _selectedCampaignType == 'quick_qualify' ? Colors.purple : AppTheme.borderGrey, width: 1.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.bolt, size: 16, color: _selectedCampaignType == 'quick_qualify' ? Colors.purple : AppTheme.mediumGrey),
                                      const SizedBox(width: 4),
                                      const Text('Quick Qualify', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkGrey)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const Text('Sentiment-driven smart auto-stop qualification', style: TextStyle(fontSize: 10, color: AppTheme.mediumGrey)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Contact File (only rendered when Upload File tab is active)
              if (widget.campaign == null && _selectedContactTab == 'Upload File')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contact File *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickFile,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.borderGrey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.upload_file, color: AppTheme.mediumGrey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedFile?.name ?? 'Select CSV or Excel file',
                                style: TextStyle(
                                  color: _selectedFile != null
                                      ? AppTheme.darkGrey
                                      : AppTheme.mediumGrey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              // Retries
              TextFormField(
                controller: _retriesController,
                decoration: const InputDecoration(
                  labelText: 'Retries *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter number of retries';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Custom First Line
              TextFormField(
                controller: _customFirstLineController,
                decoration: const InputDecoration(
                  labelText: 'Custom First Line (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Start Date Time
              // Start Date Time
              TextFormField(
                controller: _startDateTimeController,
                decoration: InputDecoration(
                  labelText: 'Start Date & Time (Optional)',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDateTime(_startDateTimeController, true),
                  ),
                  hintText: 'YYYY-MM-DD HH:MM',
                ),
              ),
              const SizedBox(height: 16),

              // End Date Time
              TextFormField(
                controller: _endDateTimeController,
                decoration: InputDecoration(
                  labelText: 'End Date & Time (Optional)',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDateTime(_endDateTimeController, false),
                  ),
                  hintText: 'YYYY-MM-DD HH:MM',
                ),
              ),
              const SizedBox(height: 16),

              // Time Zone Dropdown Selector
              DropdownButtonFormField<String>(
                value: _selectedTimezone,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'REGION / TIMEZONE',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.public, color: AppTheme.mediumGrey),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: _timezones.map((tz) {
                  return DropdownMenuItem<String>(
                    value: tz,
                    child: Text(
                      tz,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedTimezone = val;
                      _timeZoneController.text = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // AI Automation Section Card (Web App Alignment)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.lightGrey,
                  border: Border.all(color: AppTheme.borderGrey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.smart_toy_outlined, size: 18, color: AppTheme.darkGrey),
                        SizedBox(width: 8),
                        Text(
                          'AI Automation',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkGrey),
                        ),
                        Spacer(),
                        Text('OPTIONAL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.mediumGrey)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Configure post-call automations triggered after each contact interaction.', style: TextStyle(fontSize: 11, color: AppTheme.mediumGrey)),
                    const SizedBox(height: 12),

                    // Auto Follow-up Call Switch
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        border: Border.all(color: AppTheme.borderGrey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.call_made, size: 16, color: AppTheme.mediumGrey),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Auto Follow-up Call', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.darkGrey)),
                                Text('Trigger a follow-up call after unanswered contacts', style: TextStyle(fontSize: 10, color: AppTheme.mediumGrey)),
                              ],
                            ),
                          ),
                          Switch(
                            value: _autoFollowupCall,
                            activeColor: AppTheme.primaryGreen,
                            onChanged: (val) => setState(() => _autoFollowupCall = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Send WhatsApp Message Switch
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        border: Border.all(color: AppTheme.borderGrey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.chat, size: 16, color: AppTheme.primaryGreen),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Send WhatsApp Message', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.darkGrey)),
                                Text('Send a personalised WhatsApp message via Business API', style: TextStyle(fontSize: 10, color: AppTheme.mediumGrey)),
                              ],
                            ),
                          ),
                          Switch(
                            value: _sendWhatsappMessage,
                            activeColor: AppTheme.primaryGreen,
                            onChanged: (val) => setState(() => _sendWhatsappMessage = val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveCampaign,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.surfaceCard,
                        ),
                      )
                    : Text(
                        widget.campaign == null ? 'Create Campaign' : 'Update Campaign',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
