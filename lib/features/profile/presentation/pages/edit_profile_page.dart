import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/indian_phone.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/profile.dart';
import '../bloc/edit_profile_cubit.dart';
import '../widgets/profile_widgets.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<EditProfileCubit>()..load(),
      child: const EditProfileView(),
    );
  }
}

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  static const bioMax = 500;

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _bio = TextEditingController();
  bool _filled = false;

  @override
  void initState() {
    super.initState();
    _fill(context.read<EditProfileCubit>().state.profile);
  }

  void _fill(UserProfile? profile) {
    if (_filled || profile == null) return;
    _filled = true;
    _name.text = profile.name;
    _phone.text = profile.phone == null
        ? ''
        : IndianPhone.local(profile.phone!);
    _bio.text = profile.bio ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _save() {
    FocusScope.of(context).unfocus();
    context.read<EditProfileCubit>().save(
      name: _name.text,
      phone: _phone.text,
      bio: _bio.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditProfileCubit, EditProfileState>(
      listener: (context, state) {
        _fill(state.profile);
        if (state.status == EditProfileStatus.saved) {
          showAppToast(context, 'Profile updated');
          if (context.canPop()) {
            context.pop(true);
          } else {
            context.go(AppRoutes.profile);
          }
        }
      },
      builder: (context, state) {
        final cubit = context.read<EditProfileCubit>();
        return Scaffold(
          body: SafeArea(
            child: switch (state.status) {
              EditProfileStatus.loading => const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: SubpageHeader(lead: 'Personal ', accent: 'details.'),
                  ),
                  Expanded(child: LoadingView()),
                ],
              ),
              EditProfileStatus.loadFailure => ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
                children: [
                  const SubpageHeader(lead: 'Personal ', accent: 'details.'),
                  StateMessage.error(
                    message: state.errorMessage ?? 'Could not load profile.',
                    onRetry: cubit.load,
                  ),
                ],
              ),
              EditProfileStatus.ready ||
              EditProfileStatus.saving ||
              EditProfileStatus.saved => _form(state),
            },
          ),
        );
      },
    );
  }

  Widget _form(EditProfileState state) {
    final saving = state.status == EditProfileStatus.saving;
    final email = state.profile?.email ?? '';
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
      children: [
        const SubpageHeader(
          lead: 'Personal ',
          accent: 'details.',
          subtitle: 'Agents see your name on your requests and in chat.',
        ),
        const SizedBox(height: 24),
        _Field(
          label: 'Full name',
          controller: _name,
          enabled: !saving,
          icon: Symbols.person_rounded,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        _Field(
          label: 'Email',
          initialValue: email,
          enabled: false,
          icon: Symbols.mail_rounded,
          helper: 'Your sign-in email can’t be changed here.',
        ),
        const SizedBox(height: 16),
        _Field(
          label: 'Mobile',
          controller: _phone,
          enabled: !saving,
          prefixText: '+91 ',
          hint: '10-digit mobile number',
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumberNational],
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d\s+\-]')),
            LengthLimitingTextInputFormatter(16),
          ],
        ),
        const SizedBox(height: 16),
        _Field(
          label: 'Bio',
          controller: _bio,
          enabled: !saving,
          hint: 'A line about how you like to travel',
          minLines: 3,
          maxLines: 6,
          maxLength: bioMax,
          textCapitalization: TextCapitalization.sentences,
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: 16),
          _ErrorNote(message: state.errorMessage!),
        ],
        const SizedBox(height: 24),
        AppButton(
          label: 'Save changes',
          style: AppButtonStyle.ink,
          loading: saving,
          onPressed: saving ? null : _save,
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    this.controller,
    this.initialValue,
    this.enabled = true,
    this.icon,
    this.hint,
    this.helper,
    this.prefixText,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.inputFormatters,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
  });

  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final bool enabled;
  final IconData? icon;
  final String? hint;
  final String? helper;
  final String? prefixText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final int? minLines;
  final int maxLines;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.body(13, weight: FontWeight.w600)),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          enabled: enabled,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          autofillHints: autofillHints,
          inputFormatters: inputFormatters,
          minLines: minLines,
          maxLines: maxLines,
          maxLength: maxLength,
          style: AppTypography.body(
            16,
            weight: FontWeight.w500,
            color: enabled ? AppColors.ink : AppColors.textTertiary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            helperText: helper,
            helperStyle: AppTypography.body(12, color: AppColors.textTertiary),
            counterStyle: AppTypography.number(
              11,
              color: AppColors.textTertiary,
              weight: FontWeight.w500,
              tracking: 0,
            ),
            prefixIcon: icon == null ? null : Icon(icon, size: 20),
            prefixText: prefixText,
            prefixStyle: AppTypography.body(16, weight: FontWeight.w600),
            fillColor: enabled ? AppColors.card : AppColors.muted,
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(color: AppColors.hairline),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorNote extends StatelessWidget {
  const _ErrorNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.dangerTint,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(
              Symbols.error_rounded,
              size: 18,
              color: AppColors.danger,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTypography.body(
                  14,
                  color: AppColors.accentOnTint,
                  weight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
