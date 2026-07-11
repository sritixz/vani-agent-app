import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vani_app/config/theme.dart';
import 'package:vani_app/data/models/phone_numbers/phone_number_model.dart';
import 'package:vani_app/presentation/providers/phone_numbers_provider.dart';

class AvailablePhoneNumbersScreen extends ConsumerStatefulWidget {
  const AvailablePhoneNumbersScreen({super.key});

  @override
  ConsumerState<AvailablePhoneNumbersScreen> createState() =>
      _AvailablePhoneNumbersScreenState();
}

class _AvailablePhoneNumbersScreenState
    extends ConsumerState<AvailablePhoneNumbersScreen> {
  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  // Filtering
  String? _selectedRegion;
  List<String> _availableRegions = [];

  @override
  void initState() {
    super.initState();
    // Load available numbers when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(phoneNumbersProvider.notifier).loadAvailableNumbers();
    });
  }

  void _updateAvailableRegions(List<AvailablePhoneNumberModel> numbers) {
    final regions = numbers
        .where((number) => number.region != null)
        .map((number) => number.region!)
        .toSet()
        .toList();
    regions.sort();
    
    if (_availableRegions.length != regions.length ||
        !_availableRegions.every((region) => regions.contains(region))) {
      setState(() {
        _availableRegions = regions;
      });
    }
  }

  List<AvailablePhoneNumberModel> _getFilteredNumbers(
      List<AvailablePhoneNumberModel> numbers) {
    if (_selectedRegion == null) {
      return numbers;
    }
    return numbers
        .where((number) => number.region == _selectedRegion)
        .toList();
  }

  List<AvailablePhoneNumberModel> _getPaginatedNumbers(
      List<AvailablePhoneNumberModel> numbers) {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    
    if (startIndex >= numbers.length) {
      return [];
    }
    
    return numbers.sublist(
      startIndex,
      endIndex > numbers.length ? numbers.length : endIndex,
    );
  }

  int _getTotalPages(int totalItems) {
    return (totalItems / _itemsPerPage).ceil();
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _filterByRegion(String? region) {
    setState(() {
      _selectedRegion = region;
      _currentPage = 1; // Reset to first page when filtering
    });
  }

  @override
  Widget build(BuildContext context) {
    final phoneNumbersState = ref.watch(phoneNumbersProvider);
    
    // Update available regions when data changes
    if (phoneNumbersState.availableNumbers.isNotEmpty) {
      _updateAvailableRegions(phoneNumbersState.availableNumbers);
    }

    final filteredNumbers = _getFilteredNumbers(phoneNumbersState.availableNumbers);
    final paginatedNumbers = _getPaginatedNumbers(filteredNumbers);
    final totalPages = _getTotalPages(filteredNumbers.length);

    return Scaffold(
      body: SafeArea(
        child: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderGrey),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available Phone Numbers',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.darkGrey,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Select a phone number to purchase',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.mediumGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Filter Section - More Compact
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGrey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.borderGrey),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.filter_list,
                            size: 16,
                            color: AppTheme.mediumGrey,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Filter by Region',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.darkGrey,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 16),
                            onPressed: () {
                              ref
                                  .read(phoneNumbersProvider.notifier)
                                  .loadAvailableNumbers();
                            },
                            tooltip: 'Refresh',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          border: Border.all(color: AppTheme.borderGrey),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _selectedRegion,
                            isExpanded: true,
                            hint: const Text(
                              'All Regions',
                              style: TextStyle(fontSize: 12),
                            ),
                            icon: const Icon(Icons.arrow_drop_down, size: 20),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.darkGrey,
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('All Regions'),
                              ),
                              ..._availableRegions.map((region) {
                                return DropdownMenuItem<String?>(
                                  value: region,
                                  child: Text(region),
                                );
                              }),
                            ],
                            onChanged: _filterByRegion,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Showing ${paginatedNumbers.length} of ${filteredNumbers.length} numbers',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.mediumGrey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content Section
          Expanded(
            child: _buildContent(
              phoneNumbersState,
              paginatedNumbers,
              filteredNumbers.length,
              totalPages,
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildContent(
    PhoneNumbersState state,
    List<AvailablePhoneNumberModel> paginatedNumbers,
    int totalFilteredItems,
    int totalPages,
  ) {
    if (state.isLoadingAvailable) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.errorRed,
              ),
              const SizedBox(height: 16),
              Text(
                'Error: ${state.error}',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.errorRed,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(phoneNumbersProvider.notifier).loadAvailableNumbers();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.availableNumbers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.phone_disabled,
                size: 64,
                color: AppTheme.mediumGrey,
              ),
              const SizedBox(height: 16),
              const Text(
                'No available numbers found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkGrey,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please try again later or contact support',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.mediumGrey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (paginatedNumbers.isEmpty && _selectedRegion != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.filter_list_off,
                size: 64,
                color: AppTheme.mediumGrey,
              ),
              const SizedBox(height: 16),
              Text(
                'No numbers found for region: $_selectedRegion',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.darkGrey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _filterByRegion(null),
                child: const Text('Clear Filter'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Phone Numbers List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: paginatedNumbers.length,
            itemBuilder: (context, index) {
              final number = paginatedNumbers[index];
              return _buildPhoneNumberCard(number);
            },
          ),
        ),
        // Pagination Controls
        if (totalPages > 1) _buildPaginationControls(totalPages),
      ],
    );
  }

  Widget _buildPhoneNumberCard(AvailablePhoneNumberModel number) {
    // Parse and format rental price to 2 decimal places
    String formattedPrice = '0.00';
    if (number.rentalPrice != null) {
      try {
        final price = double.parse(number.rentalPrice!);
        formattedPrice = price.toStringAsFixed(2);
      } catch (e) {
        formattedPrice = number.rentalPrice!;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          border: Border.all(color: AppTheme.borderGrey),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Phone Icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.lightGreen,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.phone,
                    color: AppTheme.primaryGreen,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                // Phone Number
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        number.phoneNumber ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkGrey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (number.friendlyName != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          number.friendlyName!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.mediumGrey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Tags and Price Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tags
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 3,
                    children: [
                      if (number.region != null)
                        _buildTag(
                          label: number.region!,
                          backgroundColor: AppTheme.lightGrey,
                          textColor: AppTheme.mediumGrey,
                        ),
                      if (number.numberType != null)
                        _buildTag(
                          label: number.numberType!.toUpperCase(),
                          backgroundColor: AppTheme.lightGreen,
                          textColor: AppTheme.primaryGreen,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Price
                Row(
                  children: [
                    const Icon(
                      Icons.currency_rupee,
                      size: 11,
                      color: AppTheme.darkGrey,
                    ),
                    Text(
                      formattedPrice,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Purchase Button
            SizedBox(
              width: double.infinity,
              height: 32,
              child: ElevatedButton(
                onPressed: () => _purchaseNumber(number),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'Purchase',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag({
    required String label,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border(
          top: BorderSide(color: AppTheme.borderGrey),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous Button
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: _currentPage > 1
                ? () => _goToPage(_currentPage - 1)
                : null,
            color: AppTheme.primaryGreen,
            disabledColor: AppTheme.mediumGrey,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
          const SizedBox(width: 8),
          // Page Numbers - Wrapped in Expanded to prevent overflow
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _buildPageNumbers(totalPages),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Next Button
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: _currentPage < totalPages
                ? () => _goToPage(_currentPage + 1)
                : null,
            color: AppTheme.primaryGreen,
            disabledColor: AppTheme.mediumGrey,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers(int totalPages) {
    List<Widget> pageButtons = [];
    
    // Show max 5 page buttons for small screens
    int startPage = _currentPage - 2;
    int endPage = _currentPage + 2;
    
    if (startPage < 1) {
      startPage = 1;
      endPage = totalPages < 5 ? totalPages : 5;
    }
    
    if (endPage > totalPages) {
      endPage = totalPages;
      startPage = totalPages - 4 > 0 ? totalPages - 4 : 1;
    }
    
    // First page button
    if (startPage > 1) {
      pageButtons.add(_buildPageButton(1));
      if (startPage > 2) {
        pageButtons.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: Text('...', style: TextStyle(color: AppTheme.mediumGrey, fontSize: 12)),
        ));
      }
    }
    
    // Page number buttons
    for (int i = startPage; i <= endPage; i++) {
      pageButtons.add(_buildPageButton(i));
    }
    
    // Last page button
    if (endPage < totalPages) {
      if (endPage < totalPages - 1) {
        pageButtons.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: Text('...', style: TextStyle(color: AppTheme.mediumGrey, fontSize: 12)),
        ));
      }
      pageButtons.add(_buildPageButton(totalPages));
    }
    
    return pageButtons;
  }

  Widget _buildPageButton(int pageNumber) {
    final isCurrentPage = pageNumber == _currentPage;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: () => _goToPage(pageNumber),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCurrentPage ? AppTheme.primaryGreen : Colors.transparent,
            border: Border.all(
              color: isCurrentPage ? AppTheme.primaryGreen : AppTheme.borderGrey,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              pageNumber.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isCurrentPage ? Colors.white : AppTheme.darkGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _purchaseNumber(AvailablePhoneNumberModel number) async {
    // Parse and format rental price to 2 decimal places
    String formattedPrice = '0.00';
    if (number.rentalPrice != null) {
      try {
        final price = double.parse(number.rentalPrice!);
        formattedPrice = price.toStringAsFixed(2);
      } catch (e) {
        formattedPrice = number.rentalPrice!;
      }
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Purchase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to purchase this number?'),
            const SizedBox(height: 16),
            Text(
              number.phoneNumber ?? 'Unknown',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
            ),
            if (number.rentalPrice != null) ...[
              const SizedBox(height: 8),
              Text(
                'Rental: ₹$formattedPrice',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.mediumGrey,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Purchase'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading indicator
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await ref.read(phoneNumbersProvider.notifier).createPhoneNumber(
            phoneNumber: number.phoneNumber!,
            friendlyName: number.friendlyName,
          );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      Navigator.pop(context); // Go back to dashboard

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number purchased successfully'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to purchase: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }
}
