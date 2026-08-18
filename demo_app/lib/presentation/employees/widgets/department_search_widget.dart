import 'package:flutter/material.dart';
import 'package:hrms_demo/core/constants/department.dart';
import 'package:hrms_demo/core/constants/department_helpers.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';

/// Example widget showing how to use the department enum for search
class DepartmentSearchWidget extends StatefulWidget {
  final Function(Department?) onDepartmentSelected;
  final Department? initialDepartment;

  const DepartmentSearchWidget({super.key, required this.onDepartmentSelected, this.initialDepartment});

  @override
  State<DepartmentSearchWidget> createState() => _DepartmentSearchWidgetState();
}

class _DepartmentSearchWidgetState extends State<DepartmentSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<Department> _filteredDepartments = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _filteredDepartments = Department.allDepartments;
    if (widget.initialDepartment != null) {
      _searchController.text = widget.initialDepartment!.label;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredDepartments = Department.allDepartments;
      } else {
        _filteredDepartments = DepartmentHelpers.searchDepartments(query);
      }
    });
  }

  void _onDepartmentSelected(Department department) {
    setState(() {
      _searchController.text = department.label;
      _isSearching = false;
      _filteredDepartments = Department.allDepartments;
    });
    widget.onDepartmentSelected(department);
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _isSearching = false;
      _filteredDepartments = Department.allDepartments;
    });
    widget.onDepartmentSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.department, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.pleaseSelectDepartment,
            prefixIcon: const Icon(Icons.search),
            suffixIcon:
                _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: _clearSearch)
                    : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          onChanged: _onSearchChanged,
          onTap: () {
            setState(() {
              _isSearching = true;
              _filteredDepartments = Department.allDepartments;
            });
          },
        ),
        if (_isSearching && _filteredDepartments.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredDepartments.length,
              itemBuilder: (context, index) {
                final department = _filteredDepartments[index];
                return Material(
                  color: Colors.transparent,
                  child: ListTile(
                    title: Text(department.getEnglishText()),
                    subtitle: Text(department.getArabicText()),
                    onTap: () => _onDepartmentSelected(department),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
