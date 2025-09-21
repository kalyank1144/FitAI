import 'package:fitai/core/theme/tokens.dart';
import 'package:fitai/features/auth/data/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:async';

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
  bool _isEmailVerificationPending = false;
  Timer? _networkCheckTimer;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _networkCheckTimer?.cancel();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    final email = value.trim();
    
    // Check for basic format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    
    // Check for common email issues
    if (email.contains('..')) {
      return 'Email cannot contain consecutive dots';
    }
    
    if (email.startsWith('.') || email.endsWith('.')) {
      return 'Email cannot start or end with a dot';
    }
    
    // Check length
    if (email.length > 254) {
      return 'Email address is too long';
    }
    
    return null;
  }

  int _passwordStrength = 0;

  String? _validatePassword(String? value) {
    if (_authMode == AuthMode.forgotPassword) return null;
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (_authMode == AuthMode.signUp) {
      // Comprehensive password validation for sign-up
      if (value.length < 8) {
        return 'Password must be at least 8 characters long';
      }
      
      if (value.length > 128) {
        return 'Password is too long (max 128 characters)';
      }
      
      // Check for at least one letter and one number
      if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(value)) {
        return 'Password must contain at least one letter and one number';
      }
      
      // Check for special characters (recommended but not required)
      final hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value);
      final hasUpperCase = RegExp(r'[A-Z]').hasMatch(value);
      final hasLowerCase = RegExp(r'[a-z]').hasMatch(value);
      
      // Provide strength feedback
      int strength = 0;
      if (value.length >= 12) strength++;
      if (hasSpecialChar) strength++;
      if (hasUpperCase && hasLowerCase) strength++;
      
      // Store password strength for UI feedback (optional)
      _passwordStrength = strength;
      
      // Check for common weak patterns
      if (RegExp(r'^(123|abc|qwe|password)', caseSensitive: false).hasMatch(value)) {
        return 'Password is too common. Please choose a stronger password';
      }
      
    } else {
      // Simpler validation for sign-in
      if (value.length < 6) {
        return 'Password must be at least 6 characters long';
      }
    }
    
    return null;
  }

  /// Enhanced error handling for Supabase authentication errors
  String _getReadableErrorMessage(dynamic error) {
    final errorMessage = error.toString().toLowerCase();
    
    if (error is AuthException) {
      switch (error.message.toLowerCase()) {
        case 'invalid login credentials':
          return 'Invalid email or password. Please check your credentials and try again.';
        case 'email not confirmed':
          return 'Please verify your email address before signing in. Check your inbox for a verification link.';
        case 'too many requests':
          return 'Too many login attempts. Please wait a few minutes before trying again.';
        case 'user not found':
          return 'No account found with this email address. Please sign up first.';
        case 'weak password':
          return 'Password is too weak. Please choose a stronger password.';
        case 'email already registered':
          return 'An account with this email already exists. Please sign in instead.';
        case 'invalid email':
          return 'Please enter a valid email address.';
        case 'signup disabled':
          return 'New account registration is currently disabled.';
        default:
          return error.message;
      }
    }
    
    if (errorMessage.contains('network') || errorMessage.contains('connection')) {
      return 'Network connection error. Please check your internet connection and try again.';
    }
    
    if (errorMessage.contains('timeout')) {
      return 'Request timed out. Please check your connection and try again.';
    }
    
    if (errorMessage.contains('server')) {
      return 'Server error. Please try again in a few moments.';
    }
    
    // Remove technical prefixes for cleaner error messages
    return error.toString()
        .replaceAll('Exception: ', '')
        .replaceAll('AuthException: ', '')
        .replaceAll('PostgrestException: ', '');
  }

  /// Check network connectivity
  Future<bool> _checkNetworkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('supabase.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Enhanced session management
  Future<void> _handleSuccessfulAuth() async {
    try {
      // Verify session is properly established
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        setState(() {
          _errorMessage = null;
          _successMessage = 'Successfully signed in!';
          _isEmailVerificationPending = false;
        });
        
        // Navigate to home after a brief delay to show success message
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) context.go('/');
      } else {
        throw Exception('Session not established properly');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Authentication failed. Please try again.';
      });
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address first.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: _emailController.text.trim(),
      );
      
      if (mounted) {
        setState(() {
          _successMessage = 'Verification email resent! Please check your inbox.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getReadableErrorMessage(e);
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

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;

    // Check network connectivity first
    final hasConnection = await _checkNetworkConnectivity();
    if (!hasConnection) {
      setState(() {
        _errorMessage = 'No internet connection. Please check your network and try again.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
      _isEmailVerificationPending = false;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      
      switch (_authMode) {
        case AuthMode.signIn:
          final response = await authRepo.signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );
          
          // Check if email verification is required
          if (response.user != null && response.user!.emailConfirmedAt != null) {
            await _handleSuccessfulAuth();
          } else if (response.user != null && response.user!.emailConfirmedAt == null) {
            setState(() {
              _isEmailVerificationPending = true;
              _successMessage = 'Please verify your email address. Check your inbox for a verification link.';
            });
          }
          
        case AuthMode.signUp:
          final response = await authRepo.signUpWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );
          
          if (mounted) {
            setState(() {
              _isEmailVerificationPending = true;
              _successMessage = 'Account created successfully! Please check your email to verify your account before signing in.';
              _authMode = AuthMode.signIn;
              _passwordController.clear(); // Clear password for security
            });
          }
          
        case AuthMode.forgotPassword:
          await authRepo.resetPassword(_emailController.text.trim());
          if (mounted) {
            setState(() {
              _successMessage = 'Password reset email sent! Check your inbox and follow the instructions.';
              _authMode = AuthMode.signIn;
            });
          }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getReadableErrorMessage(e);
          
          // Handle specific email verification cases
          if (e.toString().toLowerCase().contains('email not confirmed')) {
            _isEmailVerificationPending = true;
          }
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
    // Check network connectivity first
    final hasConnection = await _checkNetworkConnectivity();
    if (!hasConnection) {
      setState(() {
        _errorMessage = 'No internet connection. Please check your network and try again.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      if (mounted) {
        await _handleSuccessfulAuth();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e.toString().toLowerCase().contains('cancelled') || 
              e.toString().toLowerCase().contains('canceled')) {
            _errorMessage = 'Google sign-in was cancelled.';
          } else {
            _errorMessage = _getReadableErrorMessage(e);
          }
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
    // Check network connectivity first
    final hasConnection = await _checkNetworkConnectivity();
    if (!hasConnection) {
      setState(() {
        _errorMessage = 'No internet connection. Please check your network and try again.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).signInWithApple();
      if (mounted) {
        await _handleSuccessfulAuth();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e.toString().toLowerCase().contains('cancelled') || 
              e.toString().toLowerCase().contains('canceled')) {
            _errorMessage = 'Apple sign-in was cancelled.';
          } else {
            _errorMessage = _getReadableErrorMessage(e);
          }
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

  Future<void> _skipAuthentication() async {
    // Set dev bypass flag in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dev_auth_bypass', true);
    
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
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
              
              // Email verification pending message with resend option
              if (_isEmailVerificationPending) ...[                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.email_outlined, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Email verification required',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Didn\'t receive the email?',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _isLoading ? null : _resendVerificationEmail,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Resend verification email',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
                          borderSide: const BorderSide(color: AppTokens.neonTeal),
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
                            borderSide: const BorderSide(color: AppTokens.neonTeal),
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
                  side: const BorderSide(color: AppTokens.neonIndigo),
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
                  side: const BorderSide(color: AppTokens.neonCoral),
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
