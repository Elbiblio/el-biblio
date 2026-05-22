import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/onboarding_notifier.dart';
import '../../../commitments/domain/models/commitment_category.dart';
import '../../../../core/di/app_providers.dart';

/// Step 5: Your Account - setup summary + signup form (merged from ready_view
/// and pre_onboarding_screen).
class YourAccountView extends ConsumerStatefulWidget {
  const YourAccountView({
    super.key,
    required this.onSignUp,
    required this.onSignIn,
    this.initialSignInMode = false,
  });

  final Future<void> Function(
    String name,
    String email,
    String password,
    String phone,
  )
  onSignUp;
  final Future<void> Function(String email, String password) onSignIn;
  final bool initialSignInMode;

  @override
  ConsumerState<YourAccountView> createState() => _YourAccountViewState();
}

class _YourAccountViewState extends ConsumerState<YourAccountView>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _countryCodeController = TextEditingController(text: '+1');
  final _phoneController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  bool _isLoading = false;
  bool _countryDetected = false;
  late bool _signInMode;

  late final AnimationController _controller;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _signInMode = widget.initialSignInMode;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    _detectCountry();
  }

  @override
  void didUpdateWidget(covariant YourAccountView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSignInMode != widget.initialSignInMode) {
      _signInMode = widget.initialSignInMode;
    }
  }

  Future<void> _detectCountry() async {
    if (_countryDetected) return;
    try {
      final countryCode = await ref
          .read(countryServiceProvider)
          .detectCountryCode();
      if (!mounted) return;
      _countryCodeController.text = countryCode;
      _countryDetected = true;
    } catch (_) {
      // Keep the editable +1 fallback.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _countryCodeController.dispose();
    _phoneController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      if (_signInMode) {
        await widget.onSignIn(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        final phone = _phoneController.text.trim();
        final fullPhone = phone.isNotEmpty
            ? '${_countryCodeController.text.trim()}$phone'
            : '';
        await widget.onSignUp(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
          fullPhone,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final archetype = notifier.primaryArchetype;
    final hasStartingPoint =
        archetype != null ||
        state.commitmentCategory != null ||
        state.derivedAgeBand != null;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final labelStyle = textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
    );

    InputDecoration fieldDecoration(String hint) {
      return InputDecoration(
        border: InputBorder.none,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: theme.colorScheme.primary),
        ),
        hintText: hint,
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.22),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      child: FadeTransition(
        opacity: _fadeIn,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
                child: Icon(
                  _signInMode ? Icons.lock_open_rounded : Icons.check_rounded,
                  size: 34,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _signInMode ? 'Welcome back.' : 'Create your account.',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() => _signInMode = !_signInMode);
                      },
                child: Text(
                  _signInMode
                      ? 'Create a new account'
                      : 'I already have an account',
                ),
              ),
              const SizedBox(height: 12),
              if (!_signInMode && hasStartingPoint) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.08,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Starting point',
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (archetype != null)
                        _buildSummaryRow(
                          context,
                          Icons.person_outline,
                          'Compass',
                          '${archetype.name} (${archetype.identity})',
                        ),
                      if (state.commitmentCategory != null)
                        _buildSummaryRow(
                          context,
                          Icons.flag_outlined,
                          'Commitment',
                          CommitmentCategory.fromString(
                            state.commitmentCategory!,
                          ).label,
                        ),
                      if (state.derivedAgeBand != null)
                        _buildSummaryRow(
                          context,
                          Icons.privacy_tip_outlined,
                          'Age band',
                          state.derivedAgeBand!.replaceAll('_', '-'),
                        ),
                      if (state.spiritualAgeScore > 0)
                        _buildSummaryRow(
                          context,
                          Icons.eco_outlined,
                          'Stage',
                          state.spiritualAgeStage,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_signInMode) ...[
                    Text('Full name', style: labelStyle),
                    const SizedBox(height: 4),
                    TextFormField(
                      focusNode: _nameFocusNode,
                      controller: _nameController,
                      decoration: fieldDecoration('Your name'),
                      style: textTheme.bodyLarge,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                  Text('Email address', style: labelStyle),
                  const SizedBox(height: 4),
                  TextFormField(
                    focusNode: _emailFocusNode,
                    controller: _emailController,
                    decoration: fieldDecoration('you@example.com'),
                    style: textTheme.bodyLarge,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Text('Password', style: labelStyle),
                  const SizedBox(height: 4),
                  TextFormField(
                    focusNode: _passwordFocusNode,
                    controller: _passwordController,
                    decoration: fieldDecoration('Password'),
                    obscureText: true,
                    style: textTheme.bodyLarge,
                    textInputAction: _signInMode
                        ? TextInputAction.done
                        : TextInputAction.next,
                    onFieldSubmitted: (_) => _signInMode
                        ? _submit()
                        : _phoneFocusNode.requestFocus(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (!_signInMode && value.length < 8) {
                        return 'Use at least 8 characters';
                      }
                      return null;
                    },
                  ),
                  if (!_signInMode) ...[
                    const SizedBox(height: 24),
                    Text('Mobile number (optional)', style: labelStyle),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            controller: _countryCodeController,
                            textAlign: TextAlign.center,
                            decoration: fieldDecoration('+1'),
                            style: textTheme.bodyLarge,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            focusNode: _phoneFocusNode,
                            controller: _phoneController,
                            decoration: fieldDecoration('(555) 000-0000'),
                            style: textTheme.bodyLarge,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Text(
                          _signInMode ? 'Sign in' : 'Create account',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
