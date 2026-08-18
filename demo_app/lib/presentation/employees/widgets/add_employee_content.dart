import 'package:hrms_demo/core/extensions/context_extensions.dart';
import 'package:hrms_demo/presentation/widgets/app_button.dart';
import 'package:hrms_demo/presentation/widgets/custom_date_picker.dart';
import 'package:hrms_demo/presentation/widgets/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/presentation/employees/bloc/employees_bloc.dart';
import 'package:hrms_demo/presentation/employees/bloc/employees_event.dart';
import 'package:hrms_demo/presentation/employees/bloc/employees_state.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:hrms_demo/data/repos/users/users_repo.dart';
import 'package:hrms_demo/core/constants/department.dart';
import 'package:hrms_demo/core/constants/locations.dart';

class AddEmployeePage extends StatefulWidget {
  const AddEmployeePage({super.key});

  @override
  State<AddEmployeePage> createState() => _AddEmployeePageState();
}

class _AddEmployeePageState extends State<AddEmployeePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _arabicNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _arabicTitleController = TextEditingController();
  final _englishTitleController = TextEditingController();
  final _codeController = TextEditingController();
  // Dropdown value for location
  String? _selectedLocation = 'RIVERSIDE'; // Default value
  String? _selectedCostCenter;
  final _nPlus1Controller = TextEditingController();
  final _nPlus2Controller = TextEditingController();
  final _hireDateController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _arabicNicknameController = TextEditingController();
  final _englishNicknameController = TextEditingController();

  String? _selectedArabicDepartment;
  String? _selectedEnglishDepartment;
  String? _selectedLeavesEligibility = '15'; // Default value
  String? _selectedWorkingDays = '5';

  // Dropdown value for shift hours
  String? _selectedShiftHours = '8'; // Default value

  bool _isLoading = false;

  // N+1 and N+2 user info
  UserModel? _nPlus1User;
  UserModel? _nPlus2User;
  bool _isLoadingN1 = false;
  bool _isLoadingN2 = false;

  // Users repository
  late final UsersRepo _usersRepo;

  @override
  void initState() {
    super.initState();
    _usersRepo = context.read<UsersRepo>();
    _addListeners();
  }

  void _addListeners() {
    _nPlus1Controller.addListener(() {
      _onN1Changed();
      _onN2Changed();
    });
    //_nPlus2Controller.addListener(() => _onN2Changed());

    // Auto-fill English nickname when English name changes
    _nameController.addListener(() {
      if (_nameController.text.isNotEmpty) {
        _englishNicknameController.text = _extractNickname(_nameController.text);
      }
    });

    // Auto-fill Arabic nickname when Arabic name changes
    _arabicNameController.addListener(() {
      if (_arabicNameController.text.isNotEmpty) {
        _arabicNicknameController.text = _extractNickname(_arabicNameController.text);
      }
    });
  }

  Future<void> _onN1Changed() async {
    final code = _nPlus1Controller.text.trim();
    if (code.isEmpty) {
      setState(() {
        _nPlus1User = null;
      });
      return;
    }

    final codeInt = int.tryParse(code);
    if (codeInt == null) {
      setState(() {
        _nPlus1User = null;
      });
      return;
    }

    setState(() {
      _isLoadingN1 = true;
    });

    try {
      final user = await _usersRepo.getEmployeeById(codeInt);
      setState(() {
        _nPlus1User = user;
        _isLoadingN1 = false;
      });
    } catch (e) {
      setState(() {
        _nPlus1User = null;
        _isLoadingN1 = false;
      });
    }
  }

  Future<void> _onN2Changed() async {
    final code = _nPlus1Controller.text.trim();
    if (code.isEmpty) {
      setState(() {
        _nPlus2User = null;
      });
      return;
    }

    final codeInt = int.tryParse(code);
    if (codeInt == null) {
      setState(() {
        _nPlus2User = null;
      });
      return;
    }

    setState(() {
      _isLoadingN2 = true;
    });

    try {
      final user = await _usersRepo.getEmployeeById(codeInt);
      final usern2 = await _usersRepo.getEmployeeById(user.n1!);
      setState(() {
        _nPlus2User = usern2;
        _isLoadingN2 = false;
        _nPlus2Controller.text = user.n1.toString();
      });
    } catch (e) {
      setState(() {
        _nPlus2User = null;
        _isLoadingN2 = false;
      });
    }
  }

  String _extractNickname(String fullName) {
    final parts = fullName.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0];
    return '${parts.first} ${parts.last}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _arabicNameController.dispose();
    _emailController.dispose();
    _arabicTitleController.dispose();
    _codeController.dispose();
    // No controller to dispose for location dropdown

    _nPlus1Controller.dispose();
    _nPlus2Controller.dispose();
    _hireDateController.dispose();
    _nationalIdController.dispose();
    _arabicNicknameController.dispose();
    _englishNicknameController.dispose();

    // No controller to dispose for shift hours dropdown
    // No controller to dispose for working days dropdown
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: AppLocalizations.of(context)!.addEmployee,
      child: Scaffold(
        body: BlocListener<EmployeesBloc, EmployeesState>(
          listener: (context, state) {
            if (state.status == EmployeesStatus.adding) {
              setState(() => _isLoading = true);
            } else {
              setState(() => _isLoading = false);

              if (state.status == EmployeesStatus.loaded) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.employeeAddedSuccessfully)));
                Navigator.of(context).pop();
              } else if (state.status == EmployeesStatus.error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage ?? AppLocalizations.of(context)!.operationFailed),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          flex: 1,
                          child: Column(
                            children: [
                              _buildTextField(
                                controller: _nameController,
                                label: AppLocalizations.of(context)!.fullName,
                                icon: Icons.person,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return AppLocalizations.of(context)!.pleaseEnterEmployeeName;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              _buildTextField(
                                controller: _englishNicknameController,
                                label: AppLocalizations.of(context)!.englishNickname,
                                icon: Icons.badge_outlined,
                              ),
                              const SizedBox(height: 16),

                              _buildTextField(
                                controller: _arabicNameController,
                                label: AppLocalizations.of(context)!.arabicName,
                                icon: Icons.person,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return AppLocalizations.of(context)!.pleaseEnterArabicName;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              _buildTextField(
                                controller: _arabicNicknameController,
                                label: AppLocalizations.of(context)!.arabicNickname,
                                icon: Icons.badge_outlined,
                              ),
                              const SizedBox(height: 16),

                              _buildCostCenterDropdown(),
                              const SizedBox(height: 16),

                              _buildLeavesEligibilityDropdown(),
                              const SizedBox(height: 16),

                              _buildWorkingDaysDropdown(),

                              const SizedBox(height: 16),

                              _buildShiftHoursDropdown(),
                              const SizedBox(height: 16),

                              _buildTextField(
                                controller: _emailController,
                                label: AppLocalizations.of(context)!.email,
                                icon: Icons.email,
                                validator: (value) {
                                  if (value != null &&
                                      value.isNotEmpty &&
                                      !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}').hasMatch(value)) {
                                    return AppLocalizations.of(context)!.pleaseEnterValidEmail;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _hireDateController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context)!.hireDate,
                                  prefixIcon: Icon(Icons.calendar_today),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return AppLocalizations.of(context)!.pleaseEnterHireDate;
                                  }
                                  return null;
                                },
                                onTap: () async {
                                  final DateTime? picked = await showCustomDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(1950),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    final DateFormat format = DateFormat("d-MMM-yyyy");
                                    setState(() {
                                      _hireDateController.text = format.format(picked);
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
                        Flexible(
                          flex: 1,
                          child: Column(
                            children: [
                              _buildTextField(
                                controller: _arabicTitleController,
                                label: AppLocalizations.of(context)!.jobTitleInArabic,
                                icon: Icons.work,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return AppLocalizations.of(context)!.pleaseEnterJobTitle;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              _buildTextField(
                                controller: _englishTitleController,
                                label: AppLocalizations.of(context)!.jobTitleInEnglish,
                                icon: Icons.work,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return AppLocalizations.of(context)!.pleaseEnterJobTitle;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              _buildArabicDepartmentDropdown(),

                              const SizedBox(height: 16),

                              _buildEnglishDepartmentDropdown(),

                              const SizedBox(height: 16),

                              _buildTextField(
                                controller: _codeController,
                                label: AppLocalizations.of(context)!.employeeCode,
                                icon: Icons.badge,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return AppLocalizations.of(context)!.pleaseEnterEmployeeCode;
                                  }
                                  if (int.tryParse(value) == null) {
                                    return AppLocalizations.of(context)!.pleaseEnterValidNumber;
                                  }
                                  if (value.length != 6 && value.length != 8) {
                                    return AppLocalizations.of(context)!.pleaseEnterValidEmployeeCode;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              _buildTextField(
                                controller: _nationalIdController,
                                label: AppLocalizations.of(context)!.nationalId,
                                icon: Icons.credit_card,
                              ),
                              const SizedBox(height: 16),

                              _buildLocationDropdown(),
                              const SizedBox(height: 16),

                              _buildNPlusField(
                                controller: _nPlus1Controller,
                                label: 'N+1 (${AppLocalizations.of(context)!.directManager})',
                                icon: Icons.supervisor_account,
                                user: _nPlus1User,
                                isLoading: _isLoadingN1,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return AppLocalizations.of(context)!.pleaseEnterN1Manager;
                                  }
                                  if (int.tryParse(value) == null) {
                                    return AppLocalizations.of(context)!.pleaseEnterValidNumber;
                                  }
                                  if (value.length != 6 && value.length != 8) {
                                    return AppLocalizations.of(context)!.pleaseEnterValidN1ManagerCode;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              _buildNPlusField(
                                controller: _nPlus2Controller,
                                readOnly: true,
                                label: 'N+2 (${AppLocalizations.of(context)!.managersManager})',
                                icon: Icons.business_center,
                                user: _nPlus2User,
                                isLoading: _isLoadingN2,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return AppLocalizations.of(context)!.pleaseEnterN2Manager;
                                  }
                                  if (int.tryParse(value) == null) {
                                    return AppLocalizations.of(context)!.pleaseEnterValidNumber;
                                  }
                                  if (value.length != 6 && value.length != 8) {
                                    return AppLocalizations.of(context)!.pleaseEnterValidN2ManagerCode;
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24),
                    // Action Buttons
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: context.screenWidth * 0.3),
                          child: AppButton(
                            color: Colors.red,
                            label: AppLocalizations.of(context)!.cancel,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: context.screenWidth * 0.3),
                          child: AppButton(
                            label:
                                _isLoading
                                    ? '${AppLocalizations.of(context)!.loading}...'
                                    : AppLocalizations.of(context)!.saveEmployee,
                            onPressed: _saveEmployee,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildNPlusField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required UserModel? user,
    required bool isLoading,
    required String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: TextInputType.number,
          validator: validator,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        if (isLoading)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.loading, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
        if (!isLoading && user != null)
          Container(
            margin: const EdgeInsets.only(top: 8.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.green[50],
              border: Border.all(color: Colors.green[200]!),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.englishName ?? '',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800]),
                      ),
                      if (user.arabicName != null)
                        Text(user.arabicName!, style: TextStyle(color: Colors.green[700], fontSize: 12)),
                      if (user.title != null)
                        Text(
                          user.title!,
                          style: TextStyle(color: Colors.green[600], fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (!isLoading && controller.text.isNotEmpty && user == null)
          Container(
            margin: const EdgeInsets.only(top: 8.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.red[50],
              border: Border.all(color: Colors.red[200]!),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.noEmployeeFound,
                  style: TextStyle(color: Colors.red[800], fontSize: 12),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildArabicDepartmentDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedArabicDepartment,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.departmentInArabic,
        prefixIcon: Icon(Icons.business),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items:
          Department.getAllArabicTextLabels().map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
      onChanged: (newValue) {
        setState(() {
          _selectedArabicDepartment = newValue;
          // Automatically set corresponding English department
          if (newValue != null) {
            _selectedEnglishDepartment = Department.getEnglishFromArabic(newValue);
          }
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)!.pleaseSelectDepartment;
        }
        return null;
      },
    );
  }

  Widget _buildEnglishDepartmentDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedEnglishDepartment,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.departmentInEnglish,
        prefixIcon: Icon(Icons.business),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items:
          Department.getAllEnglishTextLabels().map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
      onChanged: (newValue) {
        setState(() {
          _selectedEnglishDepartment = newValue;
          // Automatically set corresponding Arabic department
          if (newValue != null) {
            _selectedArabicDepartment = Department.getArabicFromEnglish(newValue);
          }
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)!.pleaseSelectDepartment;
        }
        return null;
      },
    );
  }

  Widget _buildShiftHoursDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedShiftHours,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.shiftHours,
        prefixIcon: Icon(Icons.access_time),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items:
          ['8', '9', '12'].map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
      onChanged: (newValue) {
        setState(() {
          _selectedShiftHours = newValue;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)!.pleaseSelectShiftHours;
        }
        return null;
      },
    );
  }

  Widget _buildLocationDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedLocation,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.location,
        prefixIcon: Icon(Icons.location_on),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items:
          kEmployeeLocations.map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
      onChanged: (newValue) {
        setState(() {
          _selectedLocation = newValue;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)!.pleaseSelectLocation;
        }
        return null;
      },
    );
  }

  Widget _buildWorkingDaysDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedWorkingDays,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.workingDays,
        prefixIcon: Icon(Icons.calendar_today),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items:
          ['5', '6'].map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
      onChanged: (newValue) {
        setState(() {
          _selectedWorkingDays = newValue;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)!.pleaseSelectWorkingDays;
        }
        return null;
      },
    );
  }

  Widget _buildLeavesEligibilityDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedLeavesEligibility,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.leavesEligibility,
        prefixIcon: Icon(Icons.calendar_today),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items:
          ['15', '21', '30'].map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
      onChanged: (newValue) {
        setState(() {
          _selectedLeavesEligibility = newValue;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)!.pleaseSelectLeavesEligibility;
        }
        return null;
      },
    );
  }

  Widget _buildCostCenterDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCostCenter,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.costCenter,
        prefixIcon: Icon(Icons.attach_money),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items:
          ['RIVERSIDE', 'HARBOUR', 'GATEWAY', 'Company', 'MARINA'].map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
      onChanged: (newValue) {
        setState(() {
          _selectedCostCenter = newValue;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)!.pleaseSelectCostCenter;
        }
        return null;
      },
    );
  }

  void _saveEmployee() {
    if (_formKey.currentState!.validate()) {
      final employee = UserModel(
        englishName: _nameController.text.trim(),
        arabicName: _arabicNameController.text.trim(),
        nationalId: _nationalIdController.text.trim().isEmpty ? null : _nationalIdController.text.trim(),
        englishNickname: _englishNicknameController.text.trim().isEmpty ? null : _englishNicknameController.text.trim(),
        arabicNickname: _arabicNicknameController.text.trim().isEmpty ? null : _arabicNicknameController.text.trim(),
        costCenter: _selectedCostCenter ?? '',
        leavesEligibility: int.tryParse(_selectedLeavesEligibility ?? ''),
        workingDays: int.tryParse(_selectedWorkingDays ?? ''),
        shiftHours: int.tryParse(_selectedShiftHours ?? ''),
        email: _emailController.text.trim(),
        title: _arabicTitleController.text.trim(),
        englishTitle: _englishTitleController.text.trim(),
        department: _selectedArabicDepartment,
        englishDepartment: _selectedEnglishDepartment,
        hireDate: _hireDateController.text.trim(),
        id: int.tryParse(_codeController.text.trim()),
        location: _selectedLocation,
        n1: int.tryParse(_nPlus1Controller.text.trim()),
        n2: int.tryParse(_nPlus2Controller.text.trim()),
        // "Leave Balance" / annual_remaining_balance are no longer seeded to the
        // full eligibility here — they are projected from hire date + eligibility
        // by initialize_new_hire_leave_balance (called in UsersRepoImpl.addEmployee).
      );

      context.read<EmployeesBloc>().add(AddEmployee(employee));
    }
  }
}
