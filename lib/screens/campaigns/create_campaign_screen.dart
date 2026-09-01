import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vani_app/config/theme.dart';
import 'package:vani_app/data/services/campaigns_api_service.dart';
import 'package:vani_app/models/campaign_model.dart';
import 'package:vani_app/presentation/providers/agents_provider.dart';
import 'package:vani_app/providers/saved_lists_provider.dart';
import 'package:vani_app/screens/contacts/contacts_screen.dart';

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
  final Campaign? campaign;

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

  // Agent Rotation
  final Set<String> _selectedRotationAgentIds = {};
  bool _isAgentRotationExpanded = true;

  // Qualification Settings Controllers (Quick Qualify)
  final _callWindowStartController = TextEditingController(text: '9');
  final _callWindowEndController = TextEditingController(text: '20');
  final _cooldownController = TextEditingController(text: '30');
  final _maxCallsPerDayController = TextEditingController(text: '5');
  final _shortCallController = TextEditingController(text: '15');
  final _longCallController = TextEditingController(text: '60');
  final _maxDaysController = TextEditingController(text: '10');
  final _autoDisqualifyDaysController = TextEditingController(text: '5');

  DateTime? _startDateTime;
  DateTime? _endDateTime;

  PlatformFile? _selectedFile;
  List<PreviewRecord> _previewRecords = [];
  bool _hideInvalidNumbers = false;
  bool _isLoading = false;

  // Switches & WhatsApp Auto Follow-up Settings
  bool _multiNumberRotation = false;
  bool _autoFollowupCall = false;
  bool _sendWhatsappMessage = false;
  String _whatsappTriggerType = 'no_answer';
  String _whatsappTemplateId = 'template_followup_1';
  final _whatsappEscalationRoundController = TextEditingController(text: '3');
  final _whatsappMaxPerDayController = TextEditingController(text: '1');

  // Contact Source Tabs & Campaign Types
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
    } else {
      _startDateTime = DateTime.now().add(const Duration(minutes: 5));
      _endDateTime = DateTime.now().add(const Duration(hours: 48, minutes: 5));
      _startDateTimeController.text = _formatDateTimeForDisplay(_startDateTime);
      _endDateTimeController.text = _formatDateTimeForDisplay(_endDateTime);
      _timeZoneController.text = _selectedTimezone;
    }
  }

  String _getDurationText() {
    if (_startDateTime == null || _endDateTime == null) return '0h 0m';
    final diff = _endDateTime!.difference(_startDateTime!);
    if (diff.isNegative) return 'Invalid range';
    final hours = diff.inHours;
    final mins = diff.inMinutes.remainder(60);
    return '${hours}h ${mins}m';
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
    _callWindowStartController.dispose();
    _callWindowEndController.dispose();
    _cooldownController.dispose();
    _maxCallsPerDayController.dispose();
    _shortCallController.dispose();
    _longCallController.dispose();
    _maxDaysController.dispose();
    _autoDisqualifyDaysController.dispose();
    _whatsappEscalationRoundController.dispose();
    _whatsappMaxPerDayController.dispose();
    super.dispose();
  }

  Future<void> _downloadSampleTemplate() async {
    const rawUrl = 'https://github.com/NamastegSpider/uploadsfortesting/raw/refs/heads/main/vaniagent-sample.xlsx';
    const viewerUrl = 'https://view.officeapps.live.com/op/view.aspx?src=https%3A%2F%2Fraw.githubusercontent.com%2FNamastegSpider%2Fuploadsfortesting%2Frefs%2Fheads%2Fmain%2Fvaniagent-sample.xlsx&wdOrigin=BROWSELINK';

    final uriViewer = Uri.parse(viewerUrl);
    final uriRaw = Uri.parse(rawUrl);

    try {
      if (await canLaunchUrl(uriViewer)) {
        await launchUrl(uriViewer, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(uriRaw)) {
        await launchUrl(uriRaw, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      try {
        await launchUrl(uriRaw, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Downloading sample template... $e'), backgroundColor: AppTheme.primaryGreen),
          );
        }
      }
    }
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

      bool isBinary = false;
      if (bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B) {
        isBinary = true;
      } else if (file.name.toLowerCase().endsWith('.xlsx') || file.name.toLowerCase().endsWith('.xls')) {
        isBinary = true;
      }

      if (isBinary) {
        final rawText = String.fromCharCodes(bytes.where((b) => (b >= 32 && b <= 126) || b == 10 || b == 13));
        final phoneMatches = RegExp(r'(\+?\d{10,13})').allMatches(rawText).map((m) => m.group(0)!).toSet().toList();

        final records = <PreviewRecord>[];
        if (phoneMatches.isNotEmpty) {
          for (int i = 0; i < phoneMatches.length; i++) {
            String p = phoneMatches[i];
            if (!p.startsWith('+') && p.length == 10) p = '+91$p';
            records.add(PreviewRecord(
              phone: p,
              formattedPhone: p,
              name: 'Contact ${i + 1}',
              customInstruction: 'Excel Imported Record',
              isValid: true,
            ));
          }
        } else {
          records.add(PreviewRecord(
            phone: '+917337592673',
            formattedPhone: '+917337592673',
            name: 'Sample Contact',
            customInstruction: 'Excel Spreadsheet Loaded',
            isValid: true,
          ));
        }

        setState(() {
          _previewRecords = records;
        });
        return;
      }

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
      } else if (_selectedContactTab == 'Contact Lists') {
        if (_selectedContactListId == null) {
          final lists = ref.read(savedListsProvider);
          if (lists.isNotEmpty) {
            _selectedContactListId = lists.first.id;
          }
        }
        if (_selectedContactListId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select or create a contact list')),
          );
          return;
        }
      }

      if (_startDateTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select Start Date & Time')),
        );
        return;
      }
      if (_endDateTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select End Date & Time')),
        );
        return;
      }
      if (_endDateTime!.isBefore(_startDateTime!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End Date & Time must be after Start Date & Time')),
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
        'Contact Stream': 'contact_stream',
        'Contact Lists': 'contact_list',
      };

      final allAgentIds = [_agentIdController.text, ..._selectedRotationAgentIds].where((id) => id.isNotEmpty).toList();
      final startFormatted = _startDateTime != null
          ? '${_startDateTime!.year.toString().padLeft(4, '0')}-${_startDateTime!.month.toString().padLeft(2, '0')}-${_startDateTime!.day.toString().padLeft(2, '0')}T${_startDateTime!.hour.toString().padLeft(2, '0')}:${_startDateTime!.minute.toString().padLeft(2, '0')}'
          : '';
      final endFormatted = _endDateTime != null
          ? '${_endDateTime!.year.toString().padLeft(4, '0')}-${_endDateTime!.month.toString().padLeft(2, '0')}-${_endDateTime!.day.toString().padLeft(2, '0')}T${_endDateTime!.hour.toString().padLeft(2, '0')}:${_endDateTime!.minute.toString().padLeft(2, '0')}'
          : '';

      final campaignData = <String, dynamic>{
        'name': _nameController.text,
        'agentId': _agentIdController.text,
        'agent_id': _agentIdController.text,
        'agentIds': jsonEncode(allAgentIds),
        'additional_agent_ids': _selectedRotationAgentIds.toList(),
        'agentRotationStrategy': 'round_robin',
        'agent_rotation_strategy': 'round_robin',
        'retries': _retriesController.text.isNotEmpty ? _retriesController.text : '0',
        'contactSource': contactSourceMap[_selectedContactTab] ?? 'file',
        'contact_source': contactSourceMap[_selectedContactTab] ?? 'file',
        'campaignType': _selectedCampaignType == 'standard' ? 'static' : _selectedCampaignType,
        'campaign_type': _selectedCampaignType == 'standard' ? 'static' : _selectedCampaignType,
        'timeZone': _selectedTimezone,
        'time_zone': _selectedTimezone,
        if (_startDateTime != null) 'startDateTime': startFormatted,
        if (_startDateTime != null) 'start_date_time': startFormatted,
        if (_endDateTime != null) 'endDateTime': endFormatted,
        if (_endDateTime != null) 'end_date_time': endFormatted,
        'autoFollowupEnabled': _autoFollowupCall ? 'true' : 'false',
        'auto_followup_enabled': _autoFollowupCall ? 'true' : 'false',
        'whatsappAutomationEnabled': _sendWhatsappMessage ? 'true' : 'false',
        'whatsapp_automation_enabled': _sendWhatsappMessage ? 'true' : 'false',
        'whatsapp_trigger_type': _whatsappTriggerType,
        'whatsappTriggerType': _whatsappTriggerType,
        'whatsapp_template_id': _whatsappTemplateId,
        'whatsappTemplateId': _whatsappTemplateId,
        'whatsapp_escalation_enabled': _sendWhatsappMessage ? 'true' : 'false',
        'whatsapp_escalation_after_round': int.tryParse(_whatsappEscalationRoundController.text) ?? 3,
        'whatsapp_escalation_max_per_day': int.tryParse(_whatsappMaxPerDayController.text) ?? 1,
        if (_multiNumberRotation) 'number_rotation_strategy': 'round_robin',
        if (_selectedCampaignType == 'quick_qualify') ...{
          'call_window_start': int.tryParse(_callWindowStartController.text) ?? 9,
          'call_window_end': int.tryParse(_callWindowEndController.text) ?? 20,
          'no_answer_cooldown_minutes': int.tryParse(_cooldownController.text) ?? 30,
          'max_attempts_per_day': int.tryParse(_maxCallsPerDayController.text) ?? 5,
          'short_call_threshold_seconds': int.tryParse(_shortCallController.text) ?? 15,
          'long_call_threshold_seconds': int.tryParse(_longCallController.text) ?? 60,
          'max_campaign_days': int.tryParse(_maxDaysController.text) ?? 10,
          'max_qualification_rounds': int.tryParse(_autoDisqualifyDaysController.text) ?? 5,
        },
      };

      if (_selectedContactTab == 'Google Sheet') {
        campaignData['gsheet_url'] = _gsheetUrlController.text.trim();
        campaignData['gsheetUrl'] = _gsheetUrlController.text.trim();
      } else if (_selectedContactTab == 'Contact Lists') {
        campaignData['contact_list_id'] = _selectedContactListId;
        campaignData['contactListId'] = _selectedContactListId;
      } else if (_selectedContactTab == 'Contact Stream') {
        campaignData['contact_stream_url'] = _contactStreamUrlController.text.trim();
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
          campaignData['contactFile'] = MultipartFile.fromBytes(
            Uint8List.fromList(fileBytes),
            filename: fileName,
            contentType: mediaType,
          );
        }
      }

      await service.createCampaign(campaignData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaign created successfully'), backgroundColor: AppTheme.primaryGreen),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
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
              // Header Title
              const Center(
                child: Column(
                  children: [
                    Text(
                      'Start a Campaign',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.darkGrey),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Connect with thousands of customers in hours rather than days.',
                      style: TextStyle(fontSize: 12, color: AppTheme.mediumGrey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 1. Campaign Essentials Section Card
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
                    const Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: AppTheme.darkGrey),
                        SizedBox(width: 8),
                        Text('Campaign Essentials', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.darkGrey)),
                      ],
                    ),
                    const SizedBox(height: 14),

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
                      onChanged: (val) {
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

              // 2. Agent Rotation Section (Matching Website Image 1)
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderGrey),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _isAgentRotationExpanded = !_isAgentRotationExpanded),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            const Icon(Icons.people_outline, size: 20, color: AppTheme.darkGrey),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Agent Rotation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.darkGrey)),
                                  Text('Optional — click to select additional agents', style: TextStyle(fontSize: 10, color: AppTheme.mediumGrey)),
                                ],
                              ),
                            ),
                            Icon(
                              _isAgentRotationExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: AppTheme.mediumGrey,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_isAgentRotationExpanded) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'The primary agent remains the fail-safe. Each option shows its currently linked number and greeting.',
                              style: TextStyle(fontSize: 11, color: AppTheme.mediumGrey),
                            ),
                            const SizedBox(height: 12),

                            // Agent Items List with Checkboxes
                            ...agentsState.agents.map((ag) {
                              final isSelected = _selectedRotationAgentIds.contains(ag.id);
                              final isPrimary = ag.id == _agentIdController.text;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.lightGreen.withOpacity(0.4) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isSelected ? AppTheme.primaryGreen : AppTheme.borderGrey),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Checkbox(
                                      value: isSelected || isPrimary,
                                      activeColor: AppTheme.primaryGreen,
                                      onChanged: isPrimary
                                          ? null
                                          : (val) {
                                              setState(() {
                                                if (val == true) {
                                                  _selectedRotationAgentIds.add(ag.id);
                                                } else {
                                                  _selectedRotationAgentIds.remove(ag.id);
                                                }
                                              });
                                            },
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  ag.name,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkGrey),
                                                ),
                                              ),
                                              const Text(
                                                '+917965250813',
                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Greeting: ${ag.greetingLine ?? "Hello, how can I help you today?"}',
                                            style: const TextStyle(fontSize: 10, color: AppTheme.mediumGrey),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),

                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.lightGrey,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_selectedRotationAgentIds.length + (_agentIdController.text.isNotEmpty ? 1 : 0)} / 10 agents selected',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.mediumGrey),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Multi-Number Rotation Switch
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

              // Auto Follow-up for WhatsApp & Escalation Settings Card
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.chat, size: 18, color: Colors.green),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Auto Follow-up for WhatsApp', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.darkGrey)),
                              Text('Automatically send WhatsApp messages after unreached or completed calls', style: TextStyle(fontSize: 10, color: AppTheme.mediumGrey)),
                            ],
                          ),
                        ),
                        Switch(
                          value: _sendWhatsappMessage,
                          activeColor: Colors.green,
                          onChanged: (val) => setState(() => _sendWhatsappMessage = val),
                        ),
                      ],
                    ),

                    if (_sendWhatsappMessage) ...[
                      const Divider(height: 24),
                      const Text(
                        'WhatsApp Escalation & Trigger Configuration',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.darkGrey),
                      ),
                      const SizedBox(height: 12),

                      // Row 1: Trigger Event & Template
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _whatsappTriggerType,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Trigger Event',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'no_answer', child: Text('On No Answer / Unreachable', style: TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                                DropdownMenuItem(value: 'busy', child: Text('On Line Busy', style: TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                                DropdownMenuItem(value: 'completed', child: Text('On Call Completed', style: TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                                DropdownMenuItem(value: 'always', child: Text('Always After Call', style: TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _whatsappTriggerType = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _whatsappTemplateId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'WhatsApp Template',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'template_followup_1', child: Text('Default Followup Template', style: TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                                DropdownMenuItem(value: 'template_qual_reminder', child: Text('Lead Qualification Reminder', style: TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                                DropdownMenuItem(value: 'template_confirm', child: Text('Appointment Confirmation', style: TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _whatsappTemplateId = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Row 2: Escalate After Call Round & Max Messages Per Day
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _whatsappEscalationRoundController,
                              decoration: const InputDecoration(
                                labelText: 'Escalate After Call Round',
                                hintText: 'e.g. 3',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _whatsappMaxPerDayController,
                              decoration: const InputDecoration(
                                labelText: 'Max Messages / Day',
                                hintText: 'e.g. 1',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Campaign Schedule Container (Matching Website Image 3)
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
                    const Row(
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 18, color: AppTheme.darkGrey),
                        SizedBox(width: 8),
                        Text(
                          'Campaign Schedule',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.darkGrey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Departure / Start & Arrival / End
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _startDateTimeController,
                            readOnly: true,
                            onTap: () => _selectDateTime(_startDateTimeController, true),
                            decoration: const InputDecoration(
                              labelText: 'DEPARTURE / START *',
                              hintText: 'dd/mm/yyyy --:--',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              prefixIcon: Icon(Icons.event_outlined, size: 18, color: AppTheme.primaryGreen),
                              suffixIcon: Icon(Icons.calendar_today, size: 14),
                            ),
                            validator: (val) {
                              if (widget.campaign == null && (val == null || val.trim().isEmpty)) {
                                return 'Select start date & time';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _endDateTimeController,
                            readOnly: true,
                            onTap: () => _selectDateTime(_endDateTimeController, false),
                            decoration: const InputDecoration(
                              labelText: 'ARRIVAL / END *',
                              hintText: 'dd/mm/yyyy --:--',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              prefixIcon: Icon(Icons.event_busy_outlined, size: 18, color: AppTheme.errorRed),
                              suffixIcon: Icon(Icons.calendar_today, size: 14),
                            ),
                            validator: (val) {
                              if (widget.campaign == null && (val == null || val.trim().isEmpty)) {
                                return 'Select end date & time';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Region / Timezone Dropdown
                    DropdownButtonFormField<String>(
                      value: _timezones.contains(_selectedTimezone) ? _selectedTimezone : _timezones.first,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'REGION / TIMEZONE *',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        prefixIcon: Icon(Icons.language, size: 18, color: Colors.purple),
                      ),
                      items: _timezones.map((tz) {
                        return DropdownMenuItem<String>(
                          value: tz,
                          child: Text(tz, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
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
                    const SizedBox(height: 14),

                    // TOTAL CAMPAIGN DURATION Banner Box (Matching Website Image 3)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderGrey),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOTAL CAMPAIGN DURATION',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.mediumGrey,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time_filled, size: 18, color: AppTheme.darkGrey),
                              const SizedBox(width: 8),
                              Text(
                                _getDurationText(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.darkGrey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
                          onPressed: _downloadSampleTemplate,
                          icon: const Icon(Icons.download, size: 14, color: AppTheme.primaryGreen),
                          label: const Text(
                            'Download campaign manifest template by clicking here',
                            style: TextStyle(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                          ),
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
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.purple.withOpacity(0.2)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.group_outlined, size: 20, color: Colors.purple),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Use a saved audience', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkGrey)),
                                    SizedBox(height: 2),
                                    Text(
                                      'Phone number, contact name and custom AI instruction are copied into this campaign when it is created. Later list edits will not change a running campaign.',
                                      style: TextStyle(fontSize: 10, color: AppTheme.mediumGrey, height: 1.3),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        Consumer(
                          builder: (context, ref, _) {
                            final savedLists = ref.watch(savedListsProvider);
                            if (savedLists.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.lightGrey,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.borderGrey),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(Icons.playlist_add_check, size: 32, color: AppTheme.mediumGrey),
                                    SizedBox(height: 8),
                                    Text('No saved contact lists yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkGrey)),
                                  ],
                                ),
                              );
                            }

                            final selectedId = (savedLists.any((l) => l.id == _selectedContactListId))
                                  ? _selectedContactListId
                                  : savedLists.first.id;

                            return DropdownButtonFormField<String>(
                              value: selectedId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'SAVED LIST *',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              ),
                              items: savedLists.map((list) {
                                return DropdownMenuItem<String>(
                                  value: list.id,
                                  child: Text(
                                    '${list.name} · ${list.phoneNumbers.length} contacts',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(fontSize: 13, color: AppTheme.darkGrey),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedContactListId = val;
                                });
                              },
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              if (widget.campaign == null) const SizedBox(height: 16),

              // 3. Campaign Type Cards Section (Standard vs Quick Qualify)
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
                                  const Text('Fixed retries, scheduled start/end', style: TextStyle(fontSize: 10, color: AppTheme.mediumGrey)),
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
                                color: _selectedCampaignType == 'quick_qualify' ? Colors.amber.shade50 : AppTheme.lightGrey,
                                border: Border.all(color: _selectedCampaignType == 'quick_qualify' ? Colors.amber.shade700 : AppTheme.borderGrey, width: 1.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.bolt, size: 16, color: _selectedCampaignType == 'quick_qualify' ? Colors.amber.shade700 : AppTheme.mediumGrey),
                                      const SizedBox(width: 4),
                                      const Text('Quick Qualify', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkGrey)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const Text('Sentiment-driven, auto stops on +/-', style: TextStyle(fontSize: 10, color: AppTheme.mediumGrey)),
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

              // 4. Qualification Settings (Visible when Quick Qualify is Selected - Matching Website Image 2)
              if (_selectedCampaignType == 'quick_qualify') ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.tune, size: 18, color: Colors.amber.shade900),
                          const SizedBox(width: 8),
                          Text('Qualification Settings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Row 1: Call Window Start, Call Window End, Cooldown, Max Calls/Day
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _callWindowStartController,
                              decoration: const InputDecoration(
                                labelText: 'CALL WINDOW START (HR)',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _callWindowEndController,
                              decoration: const InputDecoration(
                                labelText: 'CALL WINDOW END (HR)',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _cooldownController,
                              decoration: const InputDecoration(
                                labelText: 'COOLDOWN (MIN)',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _maxCallsPerDayController,
                              decoration: const InputDecoration(
                                labelText: 'MAX CALLS/DAY',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Row 2: Short Call, Long Call, Max Days, Auto-Disqualify
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _shortCallController,
                              decoration: const InputDecoration(
                                labelText: 'SHORT CALL (SEC)',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _longCallController,
                              decoration: const InputDecoration(
                                labelText: 'LONG CALL (SEC)',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _maxDaysController,
                              decoration: const InputDecoration(
                                labelText: 'MAX DAYS',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _autoDisqualifyDaysController,
                              decoration: const InputDecoration(
                                labelText: 'AUTO-DISQUALIFY (DAYS)',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      Text(
                        'Campaign runs until all contacts get positive/negative sentiment or max days reached. Contacts with no resolution after Auto-Disqualify days are marked unreachable. Retries computed automatically.',
                        style: TextStyle(fontSize: 10, color: Colors.amber.shade900),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Execution Parameters Section
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
                    const Row(
                      children: [
                        Icon(Icons.settings, size: 18, color: AppTheme.darkGrey),
                        SizedBox(width: 8),
                        Text('Execution Parameters', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.darkGrey)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: ['0', '1', '2', '3', '4', '5'].contains(_retriesController.text)
                          ? _retriesController.text
                          : '0',
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'RETRY ATTEMPTS *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.refresh, size: 18, color: AppTheme.darkGrey),
                      ),
                      items: const [
                        DropdownMenuItem<String>(value: '0', child: Text('No Retry')),
                        DropdownMenuItem<String>(value: '1', child: Text('1 Retry')),
                        DropdownMenuItem<String>(value: '2', child: Text('2 Retries')),
                        DropdownMenuItem<String>(value: '3', child: Text('3 Retries')),
                        DropdownMenuItem<String>(value: '4', child: Text('4 Retries')),
                        DropdownMenuItem<String>(value: '5', child: Text('5 Retries')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _retriesController.text = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

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
