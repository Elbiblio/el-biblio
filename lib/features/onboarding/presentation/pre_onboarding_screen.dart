import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/di/app_providers.dart';

class PreOnboardingScreen extends ConsumerStatefulWidget {
  const PreOnboardingScreen({super.key});

  @override
  ConsumerState<PreOnboardingScreen> createState() => _PreOnboardingScreenState();
}

class _PreOnboardingScreenState extends ConsumerState<PreOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countryCodeController = TextEditingController(text: '+1');
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  bool _isLoading = false;
  bool _countryDetected = false;

  @override
  void initState() {
    super.initState();
    _detectCountry();
  }

  Future<void> _detectCountry() async {
    if (_countryDetected) return;
    try {
      final countryCode = await ref.read(countryServiceProvider).detectCountryCode();
      if (mounted) {
        _countryCodeController.text = countryCode;
        _countryDetected = true;
      }
    } catch (e) {
      // Keep default +1 if detection fails
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _countryCodeController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final countryCode = _countryCodeController.text.trim();
      final phone = _phoneController.text.trim();
      final fullPhone = '$countryCode$phone';

      // Signup with name, email and phone
      final success = await ref.read(authProvider.notifier).signUpWithDetails(
        name: name,
        email: email,
        phone: fullPhone,
      );

      if (success) {
        // Mark pre-onboarding as complete and proceed
        await ref.read(settingsProvider.notifier).completePreOnboarding(
          name: name,
          phone: fullPhone,
        );
        if (mounted) {
          context.go(AppRoutes.home);
        }
      } else {
        if (mounted) {
          final authState = ref.read(authProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(authState.error ?? 'Signup failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back and more buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: isDark ? Colors.white : const Color(0xFF1a2418),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.more_horiz,
                      color: isDark ? Colors.white : const Color(0xFF1a2418),
                    ),
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(32, 0, 32, bottomInset + 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        children: [
                          const SizedBox(height: 14),

                          // Logo
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : const Color(0xFF1a2418).withValues(alpha: 0.1),
                              ),
                              borderRadius: BorderRadius.circular(16),
                              color: isDark
                                  ? Colors.white.withValues(alpha: 5)
                                  : Colors.white.withValues(alpha: 50),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Image.asset(
                                'assets/images/penheart.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),

                          const SizedBox(height: 48),

                          // Title
                          Text(
                            'Almost there!',
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1a2418),
                              letterSpacing: -0.5,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Subtitle
                          Text(
                            'Create your account to get started.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : const Color(0xFF1a2418).withValues(alpha: 0.6),
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 40),

                          // Form fields
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Name field
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Full Name',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                        color: isDark
                                            ? const Color(0xFF638B6C).withValues(alpha: 0.6)
                                            : const Color(0xFF1a2418).withValues(alpha: 0.4),
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
                                            color: isDark
                                                ? const Color(0xFF638B6C).withValues(alpha: 0.2)
                                                : const Color(0xFF1a2418).withValues(alpha: 0.2),
                                          ),
                                        ),
                                        focusedBorder: const UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Color(0xFF638B6C),
                                          ),
                                        ),
                                        hintText: 'e.g. Julian Vane',
                                        hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.1)
                                              : const Color(0xFF1a2418).withValues(alpha: 0.2),
                                        ),
                                      ),
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontSize: 20,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1a2418),
                                      ),
                                      textInputAction: TextInputAction.next,
                                      onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Please enter your name';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 32),

                                // Email field
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Email Address',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                        color: isDark
                                            ? const Color(0xFF638B6C).withValues(alpha: 0.6)
                                            : const Color(0xFF1a2418).withValues(alpha: 0.4),
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
                                            color: isDark
                                                ? const Color(0xFF638B6C).withValues(alpha: 0.2)
                                                : const Color(0xFF1a2418).withValues(alpha: 0.2),
                                          ),
                                        ),
                                        focusedBorder: const UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Color(0xFF638B6C),
                                          ),
                                        ),
                                        hintText: 'e.g. julian@example.com',
                                        hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.1)
                                              : const Color(0xFF1a2418).withValues(alpha: 0.2),
                                        ),
                                      ),
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontSize: 20,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1a2418),
                                      ),
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
                                  ],
                                ),

                                const SizedBox(height: 32),

                                // Phone field
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mobile Number',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                        color: isDark
                                            ? const Color(0xFF638B6C).withValues(alpha: 0.6)
                                            : const Color(0xFF1a2418).withValues(alpha: 0.4),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 90,
                                          child: TextFormField(
                                            controller: _countryCodeController,
                                            textAlign: TextAlign.center,
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              enabledBorder: UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: isDark
                                                      ? const Color(0xFF638B6C).withValues(alpha: 0.2)
                                                      : const Color(0xFF1a2418).withValues(alpha: 0.2),
                                                ),
                                              ),
                                              focusedBorder: const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Color(0xFF638B6C),
                                                ),
                                              ),
                                              hintText: '+1',
                                              hintStyle: TextStyle(
                                                color: isDark
                                                    ? Colors.white.withValues(alpha: 0.4)
                                                    : const Color(0xFF1a2418).withValues(alpha: 0.4),
                                              ),
                                            ),
                                            style: TextStyle(
                                              fontSize: 20,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF1a2418),
                                            ),
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
                                                  color: isDark
                                                      ? const Color(0xFF638B6C).withValues(alpha: 0.2)
                                                      : const Color(0xFF1a2418).withValues(alpha: 0.2),
                                                ),
                                              ),
                                              focusedBorder: const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Color(0xFF638B6C),
                                                ),
                                              ),
                                              hintText: '(555) 000-0000',
                                              hintStyle: TextStyle(
                                                color: isDark
                                                    ? Colors.white.withValues(alpha: 0.1)
                                                    : const Color(0xFF1a2418).withValues(alpha: 0.2),
                                              ),
                                            ),
                                            style: TextStyle(
                                              fontSize: 20,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF1a2418),
                                            ),
                                            keyboardType: TextInputType.phone,
                                            textInputAction: TextInputAction.done,
                                            onFieldSubmitted: (_) => _submit(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Privacy note
                          Text(
                            'Used for personalization only.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.5)
                                  : const Color(0xFF1a2418).withValues(alpha: 0.5),
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 24),

                          // Buttons
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF638B6C),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                                shadowColor: const Color(0xFF638B6C).withValues(alpha: 0.2),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'PROCEED',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.explore, size: 20),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 40),
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
    );
  }
}
