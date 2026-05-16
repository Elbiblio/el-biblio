import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/onboarding_notifier.dart';
import '../../../commitments/domain/models/commitment_category.dart';
import '../../../../core/di/app_providers.dart';

/// Step 5: Your Account - setup summary + signup form (merged from ready_view
/// and pre_onboarding_screen).
class YourAccountView extends ConsumerStatefulWidget {
  const YourAccountView({super.key, required this.onSignUp});

  final Future<void> Function(String name, String email, String phone) onSignUp;

  @override
  ConsumerState<YourAccountView> createState() => _YourAccountViewState();
}

class _YourAccountViewState extends ConsumerState<YourAccountView>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _countryCodeController = TextEditingController(text: '+1');
  final _phoneController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  bool _isLoading = false;
  bool _countryDetected = false;

  late final AnimationController _controller;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    _detectCountry();
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
    _countryCodeController.dispose();
    _phoneController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final phone = _phoneController.text.trim();
      final fullPhone = phone.isNotEmpty
          ? '${_countryCodeController.text.trim()}$phone'
          : '';
      await widget.onSignUp(
        _nameController.text.trim(),
        _emailController.text.trim(),
        fullPhone,
      );
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

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: FadeTransition(
        opacity: _fadeIn,
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Checkmark circle
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.check_rounded,
                size: 36,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Your first commitment is almost ready.',
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 20),

            // ---------- Setup summary ----------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Your starting point',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (archetype != null)
                    _buildSummaryRow(
                      context,
                      Icons.person_outline,
                      'Identity',
                      '${archetype.name} (${archetype.identity})',
                    ),
                  if (state.commitmentCategory != null)
                    _buildSummaryRow(
                      context,
                      Icons.flag_outlined,
                      'Commitment direction',
                      CommitmentCategory.fromString(
                        state.commitmentCategory!,
                      ).label,
                    ),
                  if (state.derivedAgeBand != null)
                    _buildSummaryRow(
                      context,
                      Icons.privacy_tip_outlined,
                      'Private age band',
                      state.derivedAgeBand!.replaceAll('_', '-'),
                    ),
                  _buildSummaryRow(
                    context,
                    Icons.eco_outlined,
                    'Spiritual age',
                    state.spiritualAgeStage,
                  ),
                  _buildSummaryRow(
                    context,
                    Icons.wb_sunny_outlined,
                    'Morning',
                    state.morningTime,
                  ),
                  _buildSummaryRow(
                    context,
                    Icons.nightlight_round,
                    'Evening',
                    state.eveningTime,
                  ),
                  if (state.personalDistractions.isNotEmpty)
                    _buildSummaryRow(
                      context,
                      Icons.fitness_center_outlined,
                      'Growth edges',
                      state.personalDistractions.take(2).join(', ') +
                          (state.personalDistractions.length > 2
                              ? ' +${state.personalDistractions.length - 2} more'
                              : ''),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ---------- Signup form ----------
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    'Full name',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    focusNode: _nameFocusNode,
                    controller: _nameController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      hintText: 'Your name',
                      hintStyle: textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.2,
                        ),
                      ),
                    ),
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

                  // Email
                  Text(
                    'Email address',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    focusNode: _emailFocusNode,
                    controller: _emailController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      hintText: 'you@example.com',
                      hintStyle: textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.2,
                        ),
                      ),
                    ),
                    style: textTheme.bodyLarge,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _phoneFocusNode.requestFocus(),
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

                  // Phone
                  Text(
                    'Mobile number (optional)',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          controller: _countryCodeController,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            hintText: '+1',
                          ),
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
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            hintText: '(555) 000-0000',
                            hintStyle: textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          style: textTheme.bodyLarge,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Privacy note
            Text(
              'Next you will choose visibility, join a tribe, and start one commitment.',
              style: textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Begin button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
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
                        'Enter ElBiblio',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
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
