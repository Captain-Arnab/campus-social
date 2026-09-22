import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/app_branding.dart';
import '../theme/app_theme.dart';

/// Shared auth shell: orange→navy gradient + logos + title.
class AuthGradientScaffold extends StatelessWidget {
  final Widget child;
  final String title;
  final String subtitle;

  /// When false, [child] fills remaining space (for multi-step PageView flows).
  final bool scrollable;

  const AuthGradientScaffold({
    super.key,
    required this.child,
    required this.title,
    required this.subtitle,
    this.scrollable = true,
  });

  static const _gradient = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.accent,
        AppColors.accentDark,
        Color(0xFF2A1F18),
      ],
      stops: [0.0, 0.55, 1.0],
    ),
  );

  Widget _header({required bool compact}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBranding.authScreenMarks(),
        SizedBox(height: compact ? 10.h : 14.h),
        Text(
          title,
          style: GoogleFonts.sora(
            fontSize: compact ? 26.sp : 32.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.4,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: compact ? 4.h : 6.h),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: compact ? 16.h : 24.h),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: _gradient,
        child: SafeArea(
          child: scrollable
              ? Center(
                  child: SingleChildScrollView(
                    padding:
                        EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                    child: Column(
                      children: [
                        _header(compact: false),
                        child,
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _header(compact: true),
                      Expanded(child: child),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class AuthCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  /// When true, expands to fill available height (multi-step auth).
  final bool expand;

  const AuthCard({
    super.key,
    required this.child,
    this.padding,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
    if (!expand) return card;
    return SizedBox.expand(child: card);
  }
}

/// Pill segmented control (Student/Faculty, Email/Mobile, etc.).
class AuthSegmentedControl<T> extends StatelessWidget {
  final List<({T value, String label, IconData? icon})> options;
  final T selected;
  final ValueChanged<T> onChanged;

  const AuthSegmentedControl({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: options.map((opt) {
          final active = opt.value == selected;
          return Expanded(
            child: Material(
              color: active ? AppColors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              child: InkWell(
                onTap: () => onChanged(opt.value),
                borderRadius: BorderRadius.circular(11),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (opt.icon != null) ...[
                        Icon(
                          opt.icon,
                          size: 16.sp,
                          color: active ? Colors.white : AppColors.navyMuted,
                        ),
                        SizedBox(width: 6.w),
                      ],
                      Flexible(
                        child: Text(
                          opt.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: active ? Colors.white : AppColors.navyMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Auth text field with focus border + soft shadow.
class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.maxLines = 1,
    this.inputFormatters,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.focusNode,
    this.onSubmitted,
    this.onChanged,
    this.errorText,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late final FocusNode _focus;
  bool _ownedFocus = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focus = widget.focusNode!;
    } else {
      _focus = FocusNode();
      _ownedFocus = true;
    }
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    if (_ownedFocus) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    final hasError =
        widget.errorText != null && widget.errorText!.trim().isNotEmpty;
    final borderColor = hasError
        ? Colors.red.shade400
        : (focused ? AppColors.accent : AppColors.border);
    final borderWidth = (hasError || focused) ? 2.0 : 1.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.button),
        boxShadow: focused && !hasError
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        keyboardType: widget.keyboardType,
        obscureText: widget.obscureText,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        inputFormatters: widget.inputFormatters,
        textCapitalization: widget.textCapitalization,
        onSubmitted: widget.onSubmitted,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          counterText: '',
          errorText: hasError ? widget.errorText : null,
          prefixIcon: Icon(
            widget.prefixIcon,
            color: hasError ? Colors.red.shade400 : AppColors.accent,
          ),
          suffixIcon: widget.suffixIcon,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
            borderSide: BorderSide(color: borderColor, width: borderWidth),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
            borderSide: BorderSide(color: borderColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
            borderSide: BorderSide(color: Colors.red.shade400, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
            borderSide: BorderSide(color: Colors.red.shade400, width: 2),
          ),
        ),
      ),
    );
  }
}

/// Auth-styled searchable dropdown that matches [AuthTextField] chrome.
/// Expands inline below the field (not a bottom sheet) with a live search filter.
class AuthDropdown<T> extends StatefulWidget {
  final T? value;
  final String label;
  final String? hint;
  final IconData prefixIcon;
  final String? errorText;
  final List<({T value, String label})> items;
  final ValueChanged<T?>? onChanged;
  final String? searchHint;

  const AuthDropdown({
    super.key,
    required this.value,
    required this.label,
    required this.prefixIcon,
    required this.items,
    this.hint,
    this.errorText,
    this.onChanged,
    this.searchHint,
  });

  @override
  State<AuthDropdown<T>> createState() => _AuthDropdownState<T>();
}

class _AuthDropdownState<T> extends State<AuthDropdown<T>>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  late final AnimationController _anim;
  late final Animation<double> _expand;
  late final Animation<double> _chevron;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _expand = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    _chevron = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic),
    );
    _searchCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  String? get _selectedLabel {
    if (widget.value == null) return null;
    for (final item in widget.items) {
      if (item.value == widget.value) return item.label;
    }
    return null;
  }

  List<({T value, String label})> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return widget.items;
    return widget.items
        .where((i) => i.label.toLowerCase().contains(q))
        .toList();
  }

  void _toggle() {
    if (widget.onChanged == null || widget.items.isEmpty) return;
    if (_open) {
      _close();
    } else {
      setState(() => _open = true);
      _anim.forward();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocus.requestFocus();
      });
    }
  }

  void _close() {
    _searchFocus.unfocus();
    _searchCtrl.clear();
    _anim.reverse().whenComplete(() {
      if (mounted) setState(() => _open = false);
    });
  }

  void _select(({T value, String label}) item) {
    widget.onChanged?.call(item.value);
    _close();
  }

  @override
  Widget build(BuildContext context) {
    final hasError =
        widget.errorText != null && widget.errorText!.trim().isNotEmpty;
    final enabled = widget.onChanged != null && widget.items.isNotEmpty;
    final focused = _open;
    final borderColor = hasError
        ? Colors.red.shade400
        : (focused ? AppColors.accent : AppColors.border);
    final borderWidth = (hasError || focused) ? 2.0 : 1.0;
    final displayText = _selectedLabel;
    final showHint = displayText == null || displayText.isEmpty;
    final filtered = _filtered;

    return TapRegion(
      onTapOutside: (_) {
        if (_open) _close();
      },
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.button),
            boxShadow: focused && !hasError
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? _toggle : null,
              borderRadius: BorderRadius.circular(AppRadius.button),
              child: InputDecorator(
                isEmpty: showHint,
                decoration: InputDecoration(
                  labelText: widget.label,
                  hintText: widget.hint ?? 'Select',
                  errorText: hasError ? widget.errorText : null,
                  prefixIcon: Icon(
                    widget.prefixIcon,
                    color: hasError ? Colors.red.shade400 : AppColors.accent,
                  ),
                  suffixIcon: RotationTransition(
                    turns: _chevron,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: hasError
                          ? Colors.red.shade400
                          : (enabled
                              ? AppColors.accent
                              : AppColors.textSecondary),
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    borderSide:
                        BorderSide(color: borderColor, width: borderWidth),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    borderSide: BorderSide(color: borderColor, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    borderSide:
                        BorderSide(color: Colors.red.shade400, width: 2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    borderSide:
                        BorderSide(color: Colors.red.shade400, width: 2),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                child: Text(
                  showHint ? '' : displayText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: _expand,
          axisAlignment: -1,
          child: FadeTransition(
            opacity: _expand,
            child: Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Material(
                color: AppColors.surface,
                elevation: 6,
                shadowColor: AppColors.navy.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.button),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 8.h),
                        child: TextField(
                          controller: _searchCtrl,
                          focusNode: _searchFocus,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText:
                                widget.searchHint ?? 'Search institutions…',
                            isDense: true,
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              size: 20.w,
                              color: AppColors.accent,
                            ),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.close_rounded,
                                      size: 18.w,
                                      color: AppColors.textSecondary,
                                    ),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      _searchFocus.requestFocus();
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: AppColors.surfaceMuted,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 10.h,
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                              borderSide: const BorderSide(
                                color: AppColors.accent,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: 200.h),
                        child: filtered.isEmpty
                            ? Padding(
                                padding: EdgeInsets.fromLTRB(
                                  16.w,
                                  8.h,
                                  16.w,
                                  16.h,
                                ),
                                child: Text(
                                  'No institutions match your search',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                padding: EdgeInsets.only(bottom: 8.h),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  indent: 16.w,
                                  endIndent: 16.w,
                                  color: Colors.grey[200],
                                ),
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  final isSelected =
                                      item.value == widget.value;
                                  return InkWell(
                                    onTap: () => _select(item),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 14.w,
                                        vertical: 12.h,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            widget.prefixIcon,
                                            size: 20.w,
                                            color: isSelected
                                                ? AppColors.accent
                                                : AppColors.textSecondary,
                                          ),
                                          SizedBox(width: 12.w),
                                          Expanded(
                                            child: Text(
                                              item.label,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                                color: AppColors.navy,
                                              ),
                                            ),
                                          ),
                                          if (isSelected)
                                            Icon(
                                              Icons.check_circle_rounded,
                                              size: 18.w,
                                              color: AppColors.accent,
                                            ),
                                        ],
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
            ),
          ),
        ),
      ],
      ),
    );
  }
}

class AuthPrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  State<AuthPrimaryButton> createState() => _AuthPrimaryButtonState();
}

class _AuthPrimaryButtonState extends State<AuthPrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final canTap = widget.onPressed != null && !widget.loading;
    final showAccent = canTap || widget.loading;
    return GestureDetector(
      onTapDown: canTap ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: canTap
          ? (_) {
              setState(() => _pressed = false);
              widget.onPressed?.call();
            }
          : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 110),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            color: showAccent ? AppColors.accent : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(AppRadius.button),
            boxShadow: showAccent
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: widget.loading
                ? SizedBox(
                    width: 22.w,
                    height: 22.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: showAccent ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class AuthStepProgress extends StatelessWidget {
  final int currentStep; // 0-based
  final int totalSteps;
  final List<String> labels;

  const AuthStepProgress({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step ${currentStep + 1} of $totalSteps',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: List.generate(totalSteps, (i) {
            final done = i < currentStep;
            final active = i == currentStep;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i == totalSteps - 1 ? 0 : 6.w),
                height: 5.h,
                decoration: BoxDecoration(
                  color: (done || active) ? AppColors.accent : AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
        SizedBox(height: 6.h),
        Text(
          labels[currentStep.clamp(0, labels.length - 1)],
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
      ],
    );
  }
}
