import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:vani_app/config/theme.dart';
import 'package:vani_app/data/services/campaigns_api_service.dart';
import 'package:vani_app/models/campaign_model.dart';

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
  bool _isLoading = false;

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
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
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

    if (widget.campaign == null && _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a contact file')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(campaignsApiServiceProvider);
      final campaignData = <String, dynamic>{
        'name': _nameController.text,
        'agent_id': _agentIdController.text,
        'retries': _retriesController.text,
      };

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

      if (_selectedFile != null) {
        campaignData['contact_file'] = await MultipartFile.fromFile(
          _selectedFile!.path!,
          filename: _selectedFile!.name,
        );
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.campaign == null ? 'Create Campaign' : 'Edit Campaign'),
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
              // Campaign Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Campaign Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter campaign name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Agent Name (Read-only for edit mode)
              TextFormField(
                controller: _agentNameController,
                decoration: const InputDecoration(
                  labelText: 'Agent Name *',
                  border: OutlineInputBorder(),
                ),
                readOnly: widget.campaign != null,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter agent name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Agent ID (Hidden field, only used for API)
              TextFormField(
                controller: _agentIdController,
                decoration: const InputDecoration(
                  labelText: 'Agent ID *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter agent ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Contact File
              if (widget.campaign == null)
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
              GestureDetector(
                onTap: () => _selectDateTime(_startDateTimeController, true),
                child: TextFormField(
                  controller: _startDateTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Start Date & Time (Optional)',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                    hintText: 'YYYY-MM-DD HH:MM',
                  ),
                  readOnly: true,
                ),
              ),
              const SizedBox(height: 16),

              // End Date Time
              GestureDetector(
                onTap: () => _selectDateTime(_endDateTimeController, false),
                child: TextFormField(
                  controller: _endDateTimeController,
                  decoration: const InputDecoration(
                    labelText: 'End Date & Time (Optional)',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                    hintText: 'YYYY-MM-DD HH:MM',
                  ),
                  readOnly: true,
                ),
              ),
              const SizedBox(height: 16),

              // Time Zone
              TextFormField(
                controller: _timeZoneController,
                decoration: const InputDecoration(
                  labelText: 'Time Zone (Optional)',
                  border: OutlineInputBorder(),
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
