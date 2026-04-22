import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../logic/viewmodels/auth_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isRegistering = false;

  void _handleAuthAction() async {
    final auth = context.read<AuthViewModel>();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final otp = _otpController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    try {
      if (_isRegistering) {
        if (auth.otpSent) {
          if (otp.length != 6) {
            _showError('Please enter a 6-digit OTP');
            return;
          }
          await auth.registerWithEmailVerified(email, password, otp);
        } else {
          await auth.sendOTP(email);
        }
      } else {
        await auth.signInWithEmailPassword(email, password);
      }
    } catch (e) {
      _showError(e.toString().split(']').last.trim());
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthViewModel>();
    final primaryColor = const Color(0xFF4527A0);
    final accentColor = const Color(0xFF673AB7);
    final bgColor = const Color(0xFFFBF9FF);

    return Scaffold(
      backgroundColor: bgColor,
      // Removed resizeToAvoidBottomInset: false to allow keyboard adjustment
      body: Stack(
        children: [
          // Decorative background circles
          Positioned(
            top: -50,
            left: -50,
            child: _Circle(size: 200, color: accentColor.withOpacity(0.03)),
          ),
          Positioned(
            top: 150,
            right: -30,
            child: _Circle(size: 120, color: accentColor.withOpacity(0.03)),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(), // Less "bouncy" for a static feel
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Top Image Section
                      _buildTopImageSection(context),
                      
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.1, 0),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: Column(
                              key: ValueKey<bool>(_isRegistering),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isRegistering ? 'Create\nAccount' : 'Welcome\nBack',
                                  style: GoogleFonts.outfit(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                
                                if (_isRegistering && !auth.otpSent) ...[
                                  _buildInputField(
                                    controller: _nameController,
                                    hint: 'Name',
                                    icon: Icons.person_outline,
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                _buildInputField(
                                  controller: _emailController,
                                  hint: 'Email',
                                  icon: Icons.email_outlined,
                                ),
                                const SizedBox(height: 16),

                                if (!auth.otpSent) ...[
                                  _buildInputField(
                                    controller: _passwordController,
                                    hint: 'Password',
                                    icon: Icons.lock_outline,
                                    isPassword: true,
                                  ),
                                ],

                                if (_isRegistering && auth.otpSent) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    'Enter the 6-digit code sent to your email',
                                    style: TextStyle(color: primaryColor.withOpacity(0.6), fontSize: 12),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInputField(
                                    controller: _otpController,
                                    hint: '000000',
                                    icon: Icons.verified_user_outlined,
                                    isOtp: true,
                                  ),
                                ],

                                const SizedBox(height: 32),
                                
                                // Action Button (Floating style)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _isRegistering = !_isRegistering;
                                          auth.resetOTP();
                                        });
                                      },
                                      child: Text(
                                        _isRegistering ? 'Have account? Sign In' : 'New user? Register',
                                        style: TextStyle(color: primaryColor.withOpacity(0.6), fontSize: 13),
                                      ),
                                    ),
                                    _buildSubmitButton(auth, accentColor),
                                  ],
                                ),
                                
                                const Spacer(),
                                
                                // Social Login Section
                                _buildSocialButton(
                                  label: 'Continue with Google',
                                  icon: Icons.g_mobiledata_rounded,
                                  onPressed: () => auth.signInWithGoogle(),
                                  primaryColor: primaryColor,
                                ),
                                const SizedBox(height: 12),
                                _buildSocialButton(
                                  label: 'Continue as Guest',
                                  icon: Icons.person_outline_rounded,
                                  onPressed: () => auth.signInAnonymously(),
                                  primaryColor: primaryColor,
                                ),
                                
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopImageSection(BuildContext context) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.28,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(60),
          bottomRight: Radius.circular(60),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(40, 60, 40, 20),
              child: Image.asset(
                'assets/images/login_clipart.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'WorkFlow',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF673AB7).withOpacity(0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isOtp = false,
  }) {
    final primaryColor = const Color(0xFF4527A0);
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isOtp ? TextInputType.number : TextInputType.emailAddress,
      style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: primaryColor.withOpacity(0.4)),
        prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.6), size: 22),
        filled: false,
        fillColor: Colors.transparent,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: primaryColor.withOpacity(0.15), width: 1.5),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildSubmitButton(AuthViewModel auth, Color accentColor) {
    return GestureDetector(
      onTap: auth.isLoading ? null : _handleAuthAction,
      child: Container(
        height: 60,
        width: 80,
        decoration: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: auth.isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required Color primaryColor,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        side: BorderSide(color: primaryColor.withOpacity(0.1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        foregroundColor: primaryColor,
        backgroundColor: Colors.white.withOpacity(0.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: primaryColor.withOpacity(0.8)),
          Expanded(
            child: Center(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 24), // Offset for icon
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  final Color color;

  const _Circle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
