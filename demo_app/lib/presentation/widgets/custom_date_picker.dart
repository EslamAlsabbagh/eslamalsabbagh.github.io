import 'package:hrms_demo/core/extensions/context_extensions.dart';
import 'package:hrms_demo/data/models/disabled_date_info.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/widgets/safe_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Future<DateTime?> showCustomDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  List<DisabledDateInfo>? disabledDates,
}) async {
  return await showDialog<DateTime>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return Dialog(
        child: Container(
          width: context.screenWidth > 450 ? 400 : context.screenWidth * 0.9,
          padding: const EdgeInsets.all(16),
          child: CustomCalendarWidget(
            initialDate: initialDate,
            firstDate: firstDate,
            lastDate: lastDate,
            disabledDates: disabledDates,
            onDateSelected: (DateTime selectedDate) {
              Navigator.of(context).pop(selectedDate);
            },
          ),
        ),
      );
    },
  );
}

class CustomCalendarWidget extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final List<DisabledDateInfo>? disabledDates;
  final Function(DateTime) onDateSelected;

  const CustomCalendarWidget({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.disabledDates,
    required this.onDateSelected,
  });

  @override
  State<CustomCalendarWidget> createState() => _CustomCalendarWidgetState();
}

class _CustomCalendarWidgetState extends State<CustomCalendarWidget> with SingleTickerProviderStateMixin {
  late DateTime _currentMonth;
  DateTime? _selectedDate;
  bool _showYearPicker = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  bool _slideFromRight = true;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
    _selectedDate = widget.initialDate;

    _animationController = AnimationController(duration: const Duration(milliseconds: 150), vsync: this);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _previousMonth() {
    _isAnimating = true;
    _slideFromRight = false; // Slide from left for previous month
    _updateSlideAnimation();
    _animateToMonth(DateTime(_currentMonth.year, _currentMonth.month - 1));
  }

  void _nextMonth() {
    _isAnimating = true;
    _slideFromRight = true; // Slide from right for next month
    _updateSlideAnimation();
    _animateToMonth(DateTime(_currentMonth.year, _currentMonth.month + 1));
  }

  void _updateSlideAnimation() {
    _slideAnimation = Tween<Offset>(
      begin: _slideFromRight ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
  }

  void _animateToMonth(DateTime newMonth) {
    _animationController.reset();
    setState(() {
      _currentMonth = newMonth;
    });
    _animationController.forward().then((_) {
      setState(() {
        _isAnimating = false;
      });
    });
  }

  void _toggleYearPicker() {
    _isAnimating = true;
    _slideFromRight = true; // Year picker slides from right
    _updateSlideAnimation();
    _animationController.reset();
    setState(() {
      _showYearPicker = true;
    });
    _animationController.forward().then((_) {
      setState(() {
        _isAnimating = false;
      });
    });
  }

  void _hideYearPicker() {
    _isAnimating = true;
    _slideFromRight = false; // Back to calendar slides from left
    _updateSlideAnimation();
    _animationController.reset();
    setState(() {
      _showYearPicker = false;
    });
    _animationController.forward().then((_) {
      setState(() {
        _isAnimating = false;
      });
    });
  }

  void _selectYear(int year) {
    setState(() {
      _currentMonth = DateTime(year, _currentMonth.month);
    });
    _hideYearPicker();
  }

  void _selectDate(DateTime date) {
    if (_isDateSelectable(date)) {
      setState(() {
        _selectedDate = date;
      });
      widget.onDateSelected(date);
    }
  }

  bool _isDateSelectable(DateTime date) {
    // Compare only the date part, ignoring time
    final dateOnly = DateTime(date.year, date.month, date.day);
    final firstDateOnly = DateTime(widget.firstDate.year, widget.firstDate.month, widget.firstDate.day);
    final lastDateOnly = DateTime(widget.lastDate.year, widget.lastDate.month, widget.lastDate.day);

    // Check if date is within the allowed range
    final isInRange = !dateOnly.isBefore(firstDateOnly) && !dateOnly.isAfter(lastDateOnly);

    // Check if date is not in the disabled dates list
    final isNotDisabled =
        widget.disabledDates == null ||
        !widget.disabledDates!.any((disabledDateInfo) => _isSameDay(dateOnly, disabledDateInfo.date));

    return isInRange && isNotDisabled;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  bool _isToday(DateTime date) {
    return _isSameDay(date, DateTime.now());
  }

  // Get all disabled date infos for a specific date
  List<DisabledDateInfo> _getDisabledDateInfos(DateTime date) {
    if (widget.disabledDates == null) return [];
    return widget.disabledDates!.where((info) => _isSameDay(date, info.date)).toList();
  }

  // Build tooltip message for disabled dates
  String _buildTooltipMessage(BuildContext context, DisabledDateInfo info) {
    final localizations = AppLocalizations.of(context)!;

    if (info.type == 'leave') {
      String leaveTypeLabel = '';
      switch (info.leaveType) {
        case 'Annual':
          leaveTypeLabel = localizations.leaveTypeAnnual;
          break;
        case 'Emergency':
          leaveTypeLabel = localizations.leaveTypeEmergency;
          break;
        case 'Sick':
          leaveTypeLabel = localizations.leaveTypeSick;
          break;
        case 'Compensation':
          leaveTypeLabel = localizations.leaveTypeCompensation;
          break;
        case 'Unpaid':
          leaveTypeLabel = localizations.leaveTypeUnpaid;
          break;
        default:
          leaveTypeLabel = info.leaveType ?? '';
      }
      return '${localizations.unavailableLeaveRequest} ($leaveTypeLabel)';
    } else if (info.type == 'business_trip') {
      return localizations.unavailableBusinessTrip;
    } else if (info.type == 'missing_punch') {
      // Display missing punch type (In/Out) in tooltip
      String punchTypeLabel = '';
      switch (info.missingPunchType) {
        case 'In':
          punchTypeLabel = localizations.inType;
          break;
        case 'Out':
          punchTypeLabel = localizations.outType;
          break;
        default:
          punchTypeLabel = info.missingPunchType ?? '';
      }
      return '${localizations.unavailableMissingPunch} ($punchTypeLabel)';
    }
    return ''; // Fallback for unknown types
  }

  // Build combined tooltip for multiple requests on same date
  String _buildCombinedTooltip(BuildContext context, List<DisabledDateInfo> infos) {
    return infos.map((info) => _buildTooltipMessage(context, info)).join('\n');
  }

  String _getSelectYearText() {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'ar') {
      return 'اختر السنة';
    }
    return 'Select Year';
  }

  bool _canNavigateToPreviousMonth() {
    final lastDayOfPreviousMonth = DateTime(_currentMonth.year, _currentMonth.month, 0);
    return lastDayOfPreviousMonth.isAfter(widget.firstDate.subtract(const Duration(days: 1)));
  }

  bool _canNavigateToNextMonth() {
    final firstDayOfNextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    return firstDayOfNextMonth.isBefore(widget.lastDate.add(const Duration(days: 1)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: ClipRect(
                child:
                    _isAnimating
                        ? SlideTransition(
                          position: _slideAnimation,
                          child:
                              _showYearPicker
                                  ? _buildYearPickerView()
                                  : Column(
                                    children: [_buildWeekdayHeaders(), const SizedBox(height: 8), _buildCalendarGrid()],
                                  ),
                        )
                        : _showYearPicker
                        ? _buildYearPickerView()
                        : Column(children: [_buildWeekdayHeaders(), const SizedBox(height: 8), _buildCalendarGrid()]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: _showYearPicker ? _hideYearPicker : (_canNavigateToPreviousMonth() ? _previousMonth : null),
          icon: Icon(_showYearPicker ? Icons.arrow_back : Icons.chevron_left),
          padding: const EdgeInsets.all(8),
        ),
        Expanded(
          child: GestureDetector(
            onTap: _showYearPicker ? _hideYearPicker : _toggleYearPicker,
            child: Text(
              _showYearPicker
                  ? _getSelectYearText()
                  : DateFormat.yMMMM(Localizations.localeOf(context).languageCode).format(_currentMonth),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        IconButton(
          onPressed: _showYearPicker ? null : (_canNavigateToNextMonth() ? _nextMonth : null),
          icon: const Icon(Icons.chevron_right),
          padding: const EdgeInsets.all(8),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeaders() {
    final locale = Localizations.localeOf(context);
    final isArabic = locale.languageCode == 'ar';

    // Get localized weekday names (starting from Sunday)
    final weekdays = List.generate(7, (index) {
      final date = DateTime(2024, 1, 7 + index); // January 7, 2024 is a Sunday
      return DateFormat.E(locale.languageCode).format(date);
    });

    // For Arabic, use short names
    final displayWeekdays =
        isArabic
            ? ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س'] // Arabic abbreviations
            : weekdays.map((day) => day.substring(0, 1)).toList(); // First letter for other languages

    return Row(
      children:
          displayWeekdays
              .map(
                (day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;
    final startingEmptyDays = firstDayWeekday % 7;

    final totalCells = startingEmptyDays + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (rowIndex) {
        return Row(
          children: List.generate(7, (colIndex) {
            final cellIndex = rowIndex * 7 + colIndex;

            if (cellIndex < startingEmptyDays) {
              return const Expanded(child: SizedBox(height: 40));
            }

            final day = cellIndex - startingEmptyDays + 1;
            if (day > daysInMonth) {
              return const Expanded(child: SizedBox(height: 40));
            }

            final date = DateTime(_currentMonth.year, _currentMonth.month, day);
            final isSelectable = _isDateSelectable(date);
            final isSelected = _selectedDate != null && _isSameDay(date, _selectedDate!);
            final isToday = _isToday(date);
            final isDisabled =
                widget.disabledDates != null &&
                widget.disabledDates!.any((disabledDateInfo) => _isSameDay(date, disabledDateInfo.date));
            final disabledDateInfos = isDisabled ? _getDisabledDateInfos(date) : <DisabledDateInfo>[];

            Widget dateCell = Container(
              height: 40,
              margin: const EdgeInsets.all(2),
              child: Material(
                color:
                    isSelected
                        ? Theme.of(context).primaryColor
                        : isToday
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : isDisabled
                        ? Colors.red.withOpacity(0.1)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: isSelectable ? () => _selectDate(date) : null,
                  borderRadius: BorderRadius.circular(8),
                  hoverColor: isSelectable && !isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
                  splashColor: isSelectable ? Theme.of(context).primaryColor.withOpacity(0.2) : null,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border:
                          isToday && !isSelected
                              ? Border.all(color: Theme.of(context).primaryColor, width: 1)
                              : isDisabled
                              ? Border.all(color: Colors.red.withOpacity(0.5), width: 1)
                              : null,
                    ),
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            '$day',
                            style: TextStyle(
                              color:
                                  isSelected
                                      ? Colors.white
                                      : isDisabled
                                      ? Colors.red.withOpacity(0.7)
                                      : isSelectable
                                      ? isToday
                                          ? Theme.of(context).primaryColor
                                          : Colors.black87
                                      : Colors.grey[400],
                              fontWeight: isSelected || isToday ? FontWeight.w600 : FontWeight.normal,
                              fontSize: 16,
                              decoration: isDisabled ? TextDecoration.lineThrough : null,
                              decorationColor: Colors.red.withOpacity(0.8),
                              decorationThickness: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );

            // Wrap disabled dates with tooltip
            if (isDisabled && disabledDateInfos.isNotEmpty) {
              final tooltipMessage = _buildCombinedTooltip(context, disabledDateInfos);

              return Expanded(
                child: SafeTooltip(message: tooltipMessage, triggerMode: TooltipTriggerMode.tap, child: dateCell),
              );
            }

            return Expanded(child: dateCell);
          }),
        );
      }),
    );
  }

  Widget _buildYearPickerView() {
    final years = List.generate(
      widget.lastDate.year - widget.firstDate.year + 1,
      (index) => widget.firstDate.year + index,
    );

    // Calculate the index of the current year and center it in view
    final currentYearIndex = _currentMonth.year - widget.firstDate.year;
    final itemHeight = 56.0; // ListTile height
    final viewportHeight = 300.0; // Approximate height of the year picker

    // Validate that we have a reasonable year index and create scroll controller safely
    ScrollController? scrollController;
    if (currentYearIndex >= 0 && currentYearIndex < years.length && years.isNotEmpty) {
      // Center the current year by showing it in the middle of the viewport
      final scrollOffset = (currentYearIndex * itemHeight) - (viewportHeight / 2) + (itemHeight / 2);
      final maxScrollExtent = (years.length * itemHeight) - viewportHeight;
      final clampedOffset = scrollOffset.clamp(0.0, maxScrollExtent.isNegative ? 0.0 : maxScrollExtent);

      // Only create scroll controller with valid offset
      if (clampedOffset.isFinite && clampedOffset >= 0) {
        scrollController = ScrollController(initialScrollOffset: clampedOffset);
      }
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: scrollController, // Can be null, which is fine
            itemCount: years.length,
            itemBuilder: (context, index) {
              final year = years[index];
              final isSelected = year == _currentMonth.year;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                child: ListTile(
                  title: Text(
                    '$year',
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  selected: isSelected,
                  selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onTap: () => _selectYear(year),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
