import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/pig_mascot.dart';
import '../widgets/chunky_container.dart';
import '../widgets/sparkly_background.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl     = TextEditingController();
  final _pigNameCtrl  = TextEditingController(text: 'Buddy');
  final _formKey      = GlobalKey<FormState>();

  bool _isSignUp        = false;
  bool _isLoading       = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _pigNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final auth = ref.read(authServiceProvider);
      if (_isSignUp) {
        await auth.signUp(
          _emailCtrl.text.trim(),
          _passwordCtrl.text.trim(),
          _nameCtrl.text.trim(),
          pigName: _pigNameCtrl.text.trim().isEmpty
              ? 'Buddy'
              : _pigNameCtrl.text.trim(),
        );
      } else {
        await auth.signIn(_emailCtrl.text.trim(), _passwordCtrl.text.trim());
      }
    } catch (e) {
      setState(() => _errorMessage = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String e) {
    if (e.contains('user-not-found') || e.contains('wrong-password') || e.contains('invalid-credential')) {
      return 'Wrong email or password. Try again!';
    }
    if (e.contains('email-already-in-use')) return 'This email is already registered.';
    if (e.contains('weak-password'))        return 'Password must be at least 6 characters.';
    if (e.contains('network-request-failed')) return 'No internet. Check your connection.';
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SparklyBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
              children: [
                const SizedBox(height: 24),

                // Logo
                Image.asset(
                  'assets/images/logo.png',
                  height: 140,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Column(
                    children: [
                      PigMascot(
                        pigState: _isLoading ? PigState.excited : PigState.happy,
                        size: 120,
                      ),
                      const SizedBox(height: 12),
                      Text('TinySaver Kids',
                        style: Theme.of(context).textTheme.displayMedium),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _isSignUp ? 'Create your parent account' : 'Welcome back, parent! 👋',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 32),

                // Form card — chunky 3D
                ChunkyContainer(
                  color: AppColors.surfaceContainerLowest,
                  shelfColor: AppColors.surfaceContainerHigh,
                  shelfHeight: 8,
                  radius: 32,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      if (_isSignUp) ...[
                        _field(
                          controller: _nameCtrl,
                          label: "Child's Name",
                          icon: Icons.child_care_rounded,
                          validator: (v) => (v == null || v.isEmpty) ? 'Enter a name' : null,
                        ),
                        const SizedBox(height: 14),
                        _field(
                          controller: _pigNameCtrl,
                          label: "Pig's Name 🐷",
                          icon: Icons.pets_rounded,
                          validator: (v) => null,
                        ),
                        const SizedBox(height: 14),
                      ],
                      _field(
                        controller: _emailCtrl,
                        label: 'Parent Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                      ),
                      const SizedBox(height: 14),
                      _field(
                        controller: _passwordCtrl,
                        label: 'Password',
                        icon: Icons.lock_outlined,
                        obscureText: _obscurePassword,
                        suffix: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                            color: AppColors.onSurfaceVariant, size: 20),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) =>
                            (v == null || v.length < 6) ? 'At least 6 characters' : null,
                      ),

                      // Error message
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.tertiaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                color: AppColors.tertiaryDark, size: 18),
                              const SizedBox(width: 10),
                              Expanded(child: Text(_errorMessage!,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.tertiaryDark, fontWeight: FontWeight.w600))),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ChunkyButton(
                          onTap: _isLoading ? null : _submit,
                          disabled: _isLoading,
                          gradient: _isLoading ? null : AppColors.primaryGradient,
                          color: _isLoading ? AppColors.surfaceContainerHigh : null,
                          shelfColor: _isLoading
                              ? AppColors.surfaceContainer
                              : AppColors.primaryDark,
                          shelfHeight: 7,
                          radius: 48,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: _isLoading
                              ? const Center(child: SizedBox(width: 24, height: 24,
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryDark, strokeWidth: 2.5)))
                              : Text(
                                  _isSignUp ? 'Create Account 🐷' : 'Sign In 🐷',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.primaryDark, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Toggle
                GestureDetector(
                  onTap: () => setState(() { _isSignUp = !_isSignUp; _errorMessage = null; }),
                  child: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        TextSpan(text: _isSignUp
                            ? 'Already have an account? '
                            : "Don't have an account? "),
                        TextSpan(
                          text: _isSignUp ? 'Sign In' : 'Sign Up',
                          style: const TextStyle(
                            color: AppColors.secondaryDark,
                            fontWeight: FontWeight.w800,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w600, color: AppColors.onSurface),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.secondaryDark, size: 20),
        suffixIcon: suffix,
      ),
      validator: validator,
    );
  }
}
