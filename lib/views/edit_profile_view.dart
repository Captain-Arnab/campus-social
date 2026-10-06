import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/profile_controller.dart';
import '../base/constant.dart';
import '../data/interest_catalog.dart';
import '../modal/model_user.dart';
import '../theme/app_theme.dart';
import '../utils/sweetalert_helper.dart';
import '../widgets/app_network_image.dart';
import '../widgets/campus_app_bar.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final ProfileController controller = Get.find<ProfileController>();
  final nameCtrl = TextEditingController();
  final bioCtrl = TextEditingController();
  final deptClassCtrl = TextEditingController();
  final interestSearchCtrl = TextEditingController();
  final FocusNode _interestFocusNode = FocusNode();
  File? selectedImage;

  List<String> _selectedInterests = [];
  late final String _initialName;
  late final String _initialBio;
  late final String _initialDept;
  late final List<String> _initialInterests;

  static const int _defaultSuggestionCount = 8;
  static const int _maxSearchResults = 12;

  List<String> _catalog = InterestCatalog.current;

  @override
  void initState() {
    super.initState();
    InterestCatalog.load().then((list) {
      if (mounted) setState(() => _catalog = list);
    });
    final user = controller.userData.value;
    nameCtrl.text = user.fullName ?? "";
    bioCtrl.text = user.bio ?? "";
    deptClassCtrl.text = user.departmentClass ?? "";

    // "General" is the placeholder saved when no interests are picked.
    final existingInterests = user.interests ?? "";
    if (existingInterests.isNotEmpty && existingInterests != 'General') {
      _selectedInterests = existingInterests
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    _initialName = nameCtrl.text;
    _initialBio = bioCtrl.text;
    _initialDept = deptClassCtrl.text;
    _initialInterests = List.of(_selectedInterests);
  }

  bool get _hasChanges =>
      selectedImage != null ||
      nameCtrl.text.trim() != _initialName.trim() ||
      bioCtrl.text.trim() != _initialBio.trim() ||
      deptClassCtrl.text.trim() != _initialDept.trim() ||
      !listEquals(_selectedInterests, _initialInterests);

  bool _isSelected(String interest) =>
      _selectedInterests.any((s) => s.toLowerCase() == interest.toLowerCase());

  void _addInterest(String interest) {
    final value = InterestCatalog.normalize(interest);
    if (value == null) return;
    setState(() {
      if (!_isSelected(value)) _selectedInterests.add(value);
      interestSearchCtrl.clear();
    });
  }

  void _removeInterest(String interest) {
    setState(() => _selectedInterests.remove(interest));
  }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your edits to this profile have not been saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final user = controller.userData.value;
    final isStudent = user.isStudent ?? true;
    final institution = user.institutionName?.trim() ?? '';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!_hasChanges || await _confirmDiscard()) {
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: CampusAppBar(
          titleText: 'Edit profile',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 24.h),
            children: [
              _buildPhotoPicker(user),

              _EditSection(
                title: 'Basic information',
                child: _EditCard(
                  children: [
                    const _FieldLabel('Full name'),
                    TextField(
                      controller: nameCtrl,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      style: _inputTextStyle,
                      decoration: _inputDecoration(hint: 'Enter your full name'),
                    ),
                    SizedBox(height: 16.h),
                    const _FieldLabel('Department / Class'),
                    TextField(
                      controller: deptClassCtrl,
                      textInputAction: TextInputAction.next,
                      style: _inputTextStyle,
                      decoration: _inputDecoration(
                        hint: 'e.g. CSE 3rd Year, Section A',
                        helper: 'Shown on your profile and used when you register as a participant.',
                      ),
                    ),
                    SizedBox(height: 16.h),
                    _ReadOnlyField(
                      label: 'Institution',
                      value: institution.isNotEmpty ? institution : 'Not set',
                      note: 'Set at registration and cannot be changed here.',
                    ),
                  ],
                ),
              ),

              _EditSection(
                title: 'Account',
                child: _EditCard(
                  children: [
                    _ReadOnlyField(
                      label: 'Account type',
                      value: isStudent ? 'Student' : 'Faculty',
                      note: isStudent
                          ? 'You sign in with your roll number. Contact support to change the account type.'
                          : 'You sign in with your employee ID. Contact support to change the account type.',
                    ),
                  ],
                ),
              ),

              _EditSection(
                title: 'About',
                child: _EditCard(
                  children: [
                    const _FieldLabel('Bio'),
                    TextField(
                      controller: bioCtrl,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 3,
                      maxLines: 6,
                      style: _inputTextStyle.copyWith(height: 1.45),
                      decoration: _inputDecoration(
                        hint: 'A few lines about you, your clubs, or what you are into',
                      ),
                    ),
                  ],
                ),
              ),

              _EditSection(
                title: 'Interests',
                trailing: _selectedInterests.isEmpty
                    ? null
                    : Text(
                        '${_selectedInterests.length} selected',
                        style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
                      ),
                child: _EditCard(children: _buildInterestEditor()),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
              child: Obx(() {
                final saving = controller.isLoading.value;
                return SizedBox(
                  height: 50.h,
                  child: FilledButton(
                    onPressed: saving ? null : _saveProfile,
                    style: FilledButton.styleFrom(
                      disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.6),
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                          )
                        : Text(
                            'Save changes',
                            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
                          ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPicker(ModelUser user) {
    final hasNetworkImage = user.image != null && user.image!.isNotEmpty;
    final ImageProvider? image = selectedImage != null
        ? FileImage(selectedImage!)
        : hasNetworkImage
            ? appNetworkImageProvider("${Constant.uploadsBaseUrl}profiles/${user.image}")
            : null;

    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: CircleAvatar(
                  radius: 46.r,
                  backgroundColor: AppColors.surfaceMuted,
                  backgroundImage: image,
                  child: image == null
                      ? Icon(Icons.person_rounded, size: 44.r, color: AppColors.textSecondary)
                      : null,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 2,
                child: Container(
                  width: 32.r,
                  height: 32.r,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                  child: Icon(Icons.photo_camera_rounded, size: 16.r, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 6.h),
        TextButton(
          onPressed: _pickImage,
          style: TextButton.styleFrom(foregroundColor: AppColors.accent),
          child: Text(
            selectedImage != null ? 'Choose a different photo' : 'Change photo',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildInterestEditor() {
    final query = interestSearchCtrl.text.trim();
    final q = query.toLowerCase();
    final available = _catalog.where((o) => !_isSelected(o));
    List<String> suggestions;
    var hiddenMatches = 0;
    if (q.isEmpty) {
      suggestions = available.take(_defaultSuggestionCount).toList();
    } else {
      final matches = available.where((o) => o.toLowerCase().contains(q)).toList()
        ..sort((a, b) {
          final as = a.toLowerCase().startsWith(q) ? 0 : 1;
          final bs = b.toLowerCase().startsWith(q) ? 0 : 1;
          return as != bs ? as - bs : a.length - b.length;
        });
      hiddenMatches = (matches.length - _maxSearchResults).clamp(0, matches.length);
      suggestions = matches.take(_maxSearchResults).toList();
    }
    final normalizedQuery = InterestCatalog.normalize(query);
    final isNewInterest = query.isNotEmpty &&
        !_isSelected(query) &&
        !InterestCatalog.containsIgnoreCase(_catalog, query);
    final canAddCustom = isNewInterest && normalizedQuery != null;
    final tooLong = isNewInterest && query.length > InterestCatalog.maxLength;

    return [
      if (_selectedInterests.isEmpty)
        Text(
          'No interests yet. Pick a few below so we can suggest events you will like.',
          style: TextStyle(fontSize: 13.5.sp, color: AppColors.textSecondary, height: 1.4),
        )
      else
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _selectedInterests
              .map((i) => _SelectedInterestChip(label: i, onRemove: () => _removeInterest(i)))
              .toList(),
        ),
      SizedBox(height: 16.h),
      TextField(
        controller: interestSearchCtrl,
        focusNode: _interestFocusNode,
        textInputAction: TextInputAction.done,
        style: _inputTextStyle,
        onChanged: (_) => setState(() {}),
        onSubmitted: (value) {
          _addInterest(value);
          _interestFocusNode.requestFocus();
        },
        decoration: _inputDecoration(
          hint: 'Search or add an interest',
          prefix: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
          suffix: query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                  onPressed: () => setState(interestSearchCtrl.clear),
                ),
        ),
      ),
      SizedBox(height: 14.h),
      if (suggestions.isNotEmpty) ...[
        Text(
          query.isEmpty ? 'Popular' : 'Matches',
          style: _hintLabelStyle,
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: suggestions.map((s) => _SuggestionChip(label: s, onTap: () => _addInterest(s))).toList(),
        ),
        if (query.isEmpty && _catalog.where((o) => !_isSelected(o)).length > suggestions.length) ...[
          SizedBox(height: 10.h),
          Text('Search to see more interests.', style: _hintNoteStyle),
        ] else if (hiddenMatches > 0) ...[
          SizedBox(height: 10.h),
          Text('$hiddenMatches more — keep typing to narrow down.', style: _hintNoteStyle),
        ],
      ],
      if (canAddCustom) ...[
        if (suggestions.isNotEmpty) SizedBox(height: 16.h),
        Text(
          suggestions.isEmpty ? 'Not in the list yet' : 'Not what you are looking for?',
          style: _hintLabelStyle,
        ),
        SizedBox(height: 8.h),
        Align(
          alignment: Alignment.centerLeft,
          child: _SuggestionChip(
            label: 'Add "$normalizedQuery" as a new interest',
            highlighted: true,
            onTap: () => _addInterest(query),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'New interests are added to the shared list when you save, so others can pick them too.',
          style: _hintNoteStyle,
        ),
      ] else if (tooLong)
        Text(
          'Keep interests under ${InterestCatalog.maxLength} characters.',
          style: _hintNoteStyle.copyWith(color: AppColors.error),
        )
      else if (suggestions.isEmpty)
        Text(
          query.isEmpty ? 'You have added every suggestion.' : 'Already added.',
          style: _hintNoteStyle,
        ),
    ];
  }

  TextStyle get _hintLabelStyle => TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      );

  TextStyle get _hintNoteStyle => TextStyle(fontSize: 12.sp, color: AppColors.textSecondary, height: 1.35);

  TextStyle get _inputTextStyle => TextStyle(fontSize: 15.sp, color: AppColors.navy);

  InputDecoration _inputDecoration({
    String? hint,
    String? helper,
    Widget? prefix,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary.withValues(alpha: 0.8)),
      helperText: helper,
      helperMaxLines: 2,
      helperStyle: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary, height: 1.35),
      prefixIcon: prefix,
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.cream,
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
      border: border(AppColors.border),
      enabledBorder: border(AppColors.border),
      focusedBorder: border(AppColors.accent, 1.5),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? img = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (img != null) {
        if (!mounted) return;
        setState(() => selectedImage = File(img.path));
      }
    } catch (e) {
      if (!mounted) return;
      SweetAlertHelper.showError(context, "Error", "Failed to pick image");
    }
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    if (nameCtrl.text.trim().isEmpty) {
      SweetAlertHelper.showError(context, "Required", "Please enter your name");
      return;
    }

    final interestsString = _selectedInterests.isEmpty
        ? 'General'
        : _selectedInterests.join(', ');

    final success = await controller.updateProfile(
      nameCtrl.text.trim(),
      bioCtrl.text.trim(),
      interestsString,
      selectedImage,
      departmentClass: deptClassCtrl.text.trim(),
    );

    if (success) {
      unawaited(InterestCatalog.contribute(_selectedInterests));
      Get.back();
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    bioCtrl.dispose();
    deptClassCtrl.dispose();
    interestSearchCtrl.dispose();
    _interestFocusNode.dispose();
    super.dispose();
  }
}

class _EditSection extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _EditSection({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4.w, right: 4.w, bottom: 8.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _EditCard extends StatelessWidget {
  final List<Widget> children;

  const _EditCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h, left: 2.w),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.navyMuted,
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final String? note;

  const _ReadOnlyField({required this.label, required this.value, this.note});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel(label),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(fontSize: 15.sp, color: AppColors.navyMuted),
                ),
              ),
              Icon(Icons.lock_outline_rounded, size: 16.sp, color: AppColors.textSecondary),
            ],
          ),
        ),
        if (note != null) ...[
          SizedBox(height: 6.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: Text(
              note!,
              style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary, height: 1.35),
            ),
          ),
        ],
      ],
    );
  }
}

class _SelectedInterestChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _SelectedInterestChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 12.w, right: 4.w),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.accentDark,
            ),
          ),
          InkResponse(
            onTap: onRemove,
            radius: 16,
            child: Padding(
              padding: EdgeInsets.all(6.w),
              child: const Icon(Icons.close_rounded, size: 16, color: AppColors.accentDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  const _SuggestionChip({required this.label, required this.onTap, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    final color = highlighted ? AppColors.accent : AppColors.navyMuted;
    return Material(
      color: AppColors.surface,
      shape: StadiumBorder(
        side: BorderSide(color: highlighted ? AppColors.accent : AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 16, color: color),
              SizedBox(width: 4.w),
              Text(
                label,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
