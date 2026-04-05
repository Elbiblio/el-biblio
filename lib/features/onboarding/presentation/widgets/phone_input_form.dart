import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/app_providers.dart';

class PhoneInputForm extends ConsumerStatefulWidget {
  const PhoneInputForm({super.key});

  @override
  ConsumerState<PhoneInputForm> createState() => _PhoneInputFormState();
}

class _PhoneInputFormState extends ConsumerState<PhoneInputForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countryCodeController = TextEditingController(text: '+1');
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

        // Mark phone setup as complete
        await ref.read(settingsProvider.notifier).updatePhoneSetupCompleted(true);

        if (mounted) {
          // Navigate to main app
          context.go('/today');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to create account. Please try again.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('An error occurred. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name field
          Text(
            'Your Name',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1a2418),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
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
              hintText: 'Enter your name',
              hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.4)
                    : const Color(0xFF1a2418).withValues(alpha: 0.4),
              ),
            ),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 20,
              color: isDark
                  ? Colors.white
                  : const Color(0xFF1a2418),
            ),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Email field
          Text(
            'Email Address',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1a2418),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
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
              hintText: 'Enter your email',
              hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.4)
                    : const Color(0xFF1a2418).withValues(alpha: 0.4),
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

          // Phone field
          Text(
            'Phone Number',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1a2418),
            ),
          ),
          const SizedBox(height: 8),
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
                            ? const Color(0xFF638B6C).withValues(alpha:0.2)
                            : const Color(0xFF1a2418).withValues(alpha:0.2),
                      ),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFF638B6C),
                      ),
                    ),
                    hintText: '+1',
                    hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.4)
                          : const Color(0xFF1a2418).withValues(alpha: 0.4),
                    ),
                  ),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                  controller: _phoneController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF638B6C).withValues(alpha:0.2)
                            : const Color(0xFF1a2418).withValues(alpha:0.2),
                      ),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFF638B6C),
                      ),
                    ),
                    hintText: '(555) 000-0000',
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
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF638B6C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
                  : Text(
                      'Continue',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: 16, 
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
