import 'package:fitai/core/theme/tokens.dart';
import 'package:fitai/features/auth/data/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum AuthMode { signIn, signUp, forgotPassword }

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  AuthMode _authMode = AuthMode.signIn;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (_authMode == AuthMode.forgotPassword) return null;
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (_authMode == AuthMode.signUp && value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      
      switch (_authMode) {
        case AuthMode.signIn:
          await authRepo.signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );
          if (mounted) context.go('/');
          
        case AuthMode.signUp:
          await authRepo.signUpWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );
          if (mounted) {
            setState(() {
              _successMessage = 'Account created! Please check your email to verify your account.';
              _authMode = AuthMode.signIn;
            });
          }
          
        case AuthMode.forgotPassword:
          await authRepo.resetPassword(_emailController.text.trim());
          if (mounted) {
            setState(() {
              _successMessage = 'Password reset email sent! Check your inbox.';
              _authMode = AuthMode.signIn;
            });
          }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to sign in with Google: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).signInWithApple();
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to sign in with Apple: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _skipAuthentication() {
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text(
                _getTitle(),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: AppTokens.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _getSubtitle(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTokens.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Error/Success Messages
              if (_errorMessage != null) ...[                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTokens.neonCoral.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTokens.neonCoral),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTokens.neonCoral,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_successMessage != null) ...[                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text(
                    _successMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Email/Password Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTokens.neonTeal),
                        ),
                        filled: true,
                        fillColor: AppTokens.surface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (_authMode != AuthMode.forgotPassword)
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        validator: _validatePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTokens.neonTeal),
                          ),
                          filled: true,
                          fillColor: AppTokens.surface,
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              
              // Main Action Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleEmailAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTokens.neonTeal,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(_getButtonText()),
              ),
              
              const SizedBox(height: 16),
              
              // Mode Toggle Buttons
              if (_authMode != AuthMode.forgotPassword)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _authMode = AuthMode.forgotPassword;
                      _errorMessage = null;
                      _successMessage = null;
                    });
                  },
                  child: Text(
                    'Forgot Password?',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTokens.neonTeal,
                    ),
                  ),
                ),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getToggleText(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTokens.onSurface.withOpacity(0.7),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _authMode = _getNextMode();
                        _errorMessage = null;
                        _successMessage = null;
                      });
                    },
                    child: Text(
                      _getToggleButtonText(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTokens.neonTeal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Divider
              Row(
                children: [
                  Expanded(
                    child: Divider(color: AppTokens.onSurface.withOpacity(0.3)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTokens.onSurface.withOpacity(0.7),
                    ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: AppTokens.onSurface.withOpacity(0.3)),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // OAuth Buttons
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _signInWithGoogle,
                icon: const Icon(Icons.login),
                label: const Text('Continue with Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTokens.neonTeal,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _signInWithApple,
                icon: const Icon(Icons.apple),
                label: const Text('Continue with Apple'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTokens.onSurface,
                  side: BorderSide(color: AppTokens.neonIndigo),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Skip Authentication Button (Development)
              OutlinedButton(
                onPressed: _skipAuthentication,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTokens.neonCoral,
                  side: BorderSide(color: AppTokens.neonCoral),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Skip Authentication (Dev)'),
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'By continuing you agree to our Terms.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTokens.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getTitle() {
    switch (_authMode) {
      case AuthMode.signIn:
        return 'Welcome Back';
      case AuthMode.signUp:
        return 'Create Account';
      case AuthMode.forgotPassword:
        return 'Reset Password';
    }
  }
  
  String _getSubtitle() {
    switch (_authMode) {
      case AuthMode.signIn:
        return 'Sign in to your account';
      case AuthMode.signUp:
        return 'Create a new account to get started';
      case AuthMode.forgotPassword:
        return 'Enter your email to reset your password';
    }
  }
  
  String _getButtonText() {
    switch (_authMode) {
      case AuthMode.signIn:
        return 'Sign In';
      case AuthMode.signUp:
        return 'Create Account';
      case AuthMode.forgotPassword:
        return 'Send Reset Email';
    }
  }
  
  String _getToggleText() {
    switch (_authMode) {
      case AuthMode.signIn:
        return "Don't have an account?";
      case AuthMode.signUp:
        return 'Already have an account?';
      case AuthMode.forgotPassword:
        return 'Remember your password?';
    }
  }
  
  String _getToggleButtonText() {
    switch (_authMode) {
      case AuthMode.signIn:
        return 'Sign Up';
      case AuthMode.signUp:
        return 'Sign In';
      case AuthMode.forgotPassword:
        return 'Sign In';
    }
  }
  
  AuthMode _getNextMode() {
    switch (_authMode) {
      case AuthMode.signIn:
        return AuthMode.signUp;
      case AuthMode.signUp:
        return AuthMode.signIn;
      case AuthMode.forgotPassword:
        return AuthMode.signIn;
    }
  }
}