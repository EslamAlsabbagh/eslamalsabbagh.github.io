import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/data/repos/auth/auth_repo.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_event.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_state.dart';
import 'package:hrms_demo/presentation/update_password/bloc/update_password_bloc.dart';
import 'package:hrms_demo/presentation/update_password/widgets/update_password_content.dart';
import 'package:hrms_demo/presentation/widgets/app_button.dart';
import 'package:hrms_demo/presentation/widgets/app_text_field.dart';
import 'package:hrms_demo/presentation/widgets/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return _ProfileContent(authRepo: context.read<AuthRepo>());
  }
}

class _ProfileContent extends StatefulWidget {
  final AuthRepo authRepo;

  const _ProfileContent({required this.authRepo});

  @override
  State<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<_ProfileContent> {
  // Self-service editing of the phone/address fields. These are the only
  // fields on this page the employee can change about themselves; everything
  // else is read-only display sourced from UserBloc.
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isEditing = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _startEditing(UserModel user) {
    _phoneController.text = user.phoneNumber ?? '';
    _addressController.text = user.address ?? '';
    setState(() => _isEditing = true);
  }

  void _cancelEditing() {
    setState(() => _isEditing = false);
  }

  void _save(UserModel user) {
    if (user.id == null) return;
    if (_formKey.currentState?.validate() ?? false) {
      context.read<UserBloc>().add(
        UpdateUserContactInfo(
          code: user.id!,
          phoneNumber: _phoneController.text.trim(),
          address: _addressController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserBloc, UserState>(
      listenWhen: (previous, current) => previous.contactUpdateStatus != current.contactUpdateStatus,
      listener: (context, state) {
        if (state.contactUpdateStatus == Status.success) {
          setState(() => _isEditing = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.contactInfoUpdated)));
        } else if (state.contactUpdateStatus == Status.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.contactInfoUpdateFailed), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        if (state.status == Status.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == Status.failure) {
          return Center(child: Text(state.error ?? 'Something went wrong'));
        }

        final user = state.user;

        if (user == null) {
          // Routing is owned by AuthGate; ProfilePage must never navigate to
          // login (that redirect was half of the recursive loop). Show a spinner
          // for any unexpected transient null-user state instead.
          return const Center(child: CircularProgressIndicator());
        }

        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        final isSaving = state.contactUpdateStatus == Status.loading;

        return MainLayout(
          title: AppLocalizations.of(context)!.profile,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 500,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              _ProfileListItem(
                                title: AppLocalizations.of(context)!.name,
                                value: isArabic ? user.arabicName ?? "" : user.englishName ?? "",
                              ),
                              _ProfileListItem(title: AppLocalizations.of(context)!.email, value: user.email ?? ""),
                              _ProfileListItem(
                                title: AppLocalizations.of(context)!.title,
                                value: isArabic ? user.title ?? "" : user.englishTitle ?? "",
                              ),
                              _ProfileListItem(
                                title: AppLocalizations.of(context)!.department,
                                value: isArabic ? user.department ?? "" : user.englishDepartment ?? "",
                              ),
                              _ProfileListItem(
                                title: AppLocalizations.of(context)!.hireDate,
                                value: user.hireDate ?? "",
                              ),
                              _ProfileListItem(
                                title: AppLocalizations.of(context)!.code,
                                value: user.id?.toString() ?? "",
                              ),
                              _ProfileListItem(
                                title: AppLocalizations.of(context)!.location,
                                value: user.location ?? "",
                              ),
                              if (user.n1 != null)
                                _ProfileListItem(
                                  title: AppLocalizations.of(context)!.firstLineManager,
                                  value: isArabic ? user.n1ArabicName ?? "" : user.n1EnglishName ?? "",
                                ),
                              if (user.n2 != null)
                                _ProfileListItem(
                                  title: AppLocalizations.of(context)!.secondLineManager,
                                  value: isArabic ? user.n2ArabicName ?? "" : user.n2EnglishName ?? "",
                                ),
                              const SizedBox(height: 8),
                              _buildContactSection(
                                context: context,
                                user: user,
                                isArabic: isArabic,
                                isSaving: isSaving,
                              ),
                              const SizedBox(height: 16),
                              Align(
                                alignment: isArabic ? Alignment.bottomRight : Alignment.bottomLeft,
                                child: AppButton(
                                  label: AppLocalizations.of(context)!.updatePassword,
                                  onPressed: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder:
                                            (_) => MultiBlocProvider(
                                              providers: [
                                                BlocProvider(
                                                  create: (context) => UpdatePasswordBloc(authRepo: widget.authRepo),
                                                ),
                                              ],
                                              child: const UpdatePasswordContent(),
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// The phone/address block: read-only rows with an Edit affordance, or an
  /// inline Form with Save/Cancel while editing.
  Widget _buildContactSection({
    required BuildContext context,
    required UserModel user,
    required bool isArabic,
    required bool isSaving,
  }) {
    final l10n = AppLocalizations.of(context)!;

    if (!_isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileListItem(title: l10n.phoneNumber, value: user.phoneNumber ?? ""),
          _ProfileListItem(title: l10n.address, value: user.address ?? ""),
          Align(
            alignment: isArabic ? Alignment.bottomRight : Alignment.bottomLeft,
            child: TextButton.icon(
              onPressed: () => _startEditing(user),
              icon: const Icon(Icons.edit, size: 16),
              label: Text(l10n.edit),
            ),
          ),
        ],
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            label: l10n.phoneNumber,
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            autofocus: false,
            width: double.infinity,
            // Optional field — no required validation.
            validator: (_) => null,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]'))],
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: l10n.address,
            controller: _addressController,
            keyboardType: TextInputType.streetAddress,
            autofocus: false,
            width: double.infinity,
            validator: (_) => null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              AppButton(label: l10n.save, isLoading: isSaving, width: 120, onPressed: () => _save(user)),
              const SizedBox(width: 12),
              if (!isSaving) TextButton(onPressed: _cancelEditing, child: Text(l10n.cancel)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileListItem extends StatelessWidget {
  const _ProfileListItem({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
              ),
              child: Text(
                value.isEmpty ? '-' : value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: value.isEmpty ? Colors.grey.withValues(alpha: 0.6) : Colors.grey[800],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
