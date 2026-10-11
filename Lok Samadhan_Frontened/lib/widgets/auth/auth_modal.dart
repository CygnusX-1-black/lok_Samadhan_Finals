import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../theme/app_colors.dart';

enum AuthViewMode {
  signIn,
  createAccount,
  forgotPassword,
}

class AuthModal extends StatefulWidget {
  final AuthViewMode initialMode;
  final VoidCallback? onSuccess;

  const AuthModal({
    super.key,
    this.initialMode = AuthViewMode.signIn,
    this.onSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    AuthViewMode initialMode = AuthViewMode.signIn,
    VoidCallback? onSuccess,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AuthModal(
        initialMode: initialMode,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<AuthModal> createState() => _AuthModalState();
}

class _AuthModalState extends State<AuthModal> {
  late AuthViewMode _viewMode;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _viewMode = widget.initialMode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _switchMode(AuthViewMode mode) {
    Provider.of<AuthProvider>(context, listen: false).clearMessages();
    setState(() {
      _viewMode = mode;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _handleEmailSubmit(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;

    bool success = false;
    if (_viewMode == AuthViewMode.signIn) {
      success = await auth.signInWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } else if (_viewMode == AuthViewMode.createAccount) {
      success = await auth.register(
        fullName: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      );
    } else if (_viewMode == AuthViewMode.forgotPassword) {
      success = await auth.forgotPassword(_emailController.text);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              auth.successMessage ?? 'Password reset link sent to your email.',
              style: GoogleFonts.notoSans(color: Colors.white),
            ),
            backgroundColor: AppColors.emeraldPrimary,
            duration: const Duration(seconds: 4),
          ),
        );
        _switchMode(AuthViewMode.signIn);
      }
      return;
    }

    if (success && mounted) {
      widget.onSuccess?.call();
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.successMessage ?? 'Authenticated successfully',
            style: GoogleFonts.notoSans(color: Colors.white),
          ),
          backgroundColor: AppColors.emeraldPrimary,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleGoogleSignIn(AuthProvider auth) async {
    final success = await auth.signInWithGoogle();
    if (success && mounted) {
      widget.onSuccess?.call();
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.successMessage ?? 'Signed in with Google',
            style: GoogleFonts.notoSans(color: Colors.white),
          ),
          backgroundColor: AppColors.emeraldPrimary,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _fillDemoCredentials() {
    setState(() {
      _emailController.text = 'srijan.verma@example.com';
      _passwordController.text = 'SrijanPassword123!';
      if (_viewMode == AuthViewMode.createAccount) {
        _nameController.text = 'Srijan Verma';
        _confirmPasswordController.text = 'SrijanPassword123!';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isGujarati = Provider.of<LanguageProvider>(context).isGujarati;
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 500;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 24,
        vertical: 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Govt Tricolor accent bar
                  Container(
                    height: 5,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.saffronPrimary,
                          Colors.white,
                          AppColors.emeraldPrimary,
                        ],
                      ),
                    ),
                  ),

                  // Header section
                  _buildHeader(isGujarati),

                  // Scrollable Form content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Error or Success Banner
                            if (auth.errorMessage != null) ...[
                              _buildAlertBanner(
                                message: auth.errorMessage!,
                                isError: true,
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (auth.successMessage != null && _viewMode != AuthViewMode.signIn) ...[
                              _buildAlertBanner(
                                message: auth.successMessage!,
                                isError: false,
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Option 1: Continue with Google (shown in signIn and createAccount)
                            if (_viewMode != AuthViewMode.forgotPassword) ...[
                              _buildGoogleButton(auth, isGujarati),
                              const SizedBox(height: 20),
                              _buildOrDivider(isGujarati),
                              const SizedBox(height: 20),
                            ],

                            // Option 2: Email & Password Fields
                            if (_viewMode == AuthViewMode.createAccount) ...[
                              _buildTextField(
                                controller: _nameController,
                                label: isGujarati ? 'સંપૂર્ણ નામ (Full Name)' : 'Full Name',
                                hint: 'e.g. Srijan Verma',
                                icon: Icons.person_outline,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter your full name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                            ],

                            _buildTextField(
                              controller: _emailController,
                              label: isGujarati ? 'ઈમેલ સરનામું (Email Address)' : 'Email Address',
                              hint: 'name@example.com',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Email address is required';
                                }
                                if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(val.trim())) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),

                            if (_viewMode != AuthViewMode.forgotPassword) ...[
                              const SizedBox(height: 14),
                              _buildTextField(
                                controller: _passwordController,
                                label: isGujarati ? 'પાસવર્ડ (Password)' : 'Password',
                                hint: '••••••••',
                                icon: Icons.lock_outline,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    size: 20,
                                    color: AppColors.textMuted,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Password is required';
                                  }
                                  if (val.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                            ],

                            if (_viewMode == AuthViewMode.createAccount) ...[
                              const SizedBox(height: 14),
                              _buildTextField(
                                controller: _confirmPasswordController,
                                label: isGujarati ? 'પાસવર્ડની પુષ્ટિ કરો (Confirm Password)' : 'Confirm Password',
                                hint: '••••••••',
                                icon: Icons.lock_reset_outlined,
                                obscureText: _obscureConfirm,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    size: 20,
                                    color: AppColors.textMuted,
                                  ),
                                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                ),
                                validator: (val) {
                                  if (val != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                            ],

                            // Forgot Password Link (in SignIn mode)
                            if (_viewMode == AuthViewMode.signIn) ...[
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => _switchMode(AuthViewMode.forgotPassword),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    isGujarati ? 'પાસવર્ડ ભૂલી ગયા? (Forgot Password?)' : 'Forgot Password?',
                                    style: GoogleFonts.notoSans(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.navyMedium,
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 18),

                            // Submit Primary Action Button
                            ElevatedButton(
                              onPressed: auth.isLoading ? null : () => _handleEmailSubmit(auth),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _viewMode == AuthViewMode.createAccount
                                    ? AppColors.emeraldPrimary
                                    : AppColors.saffronPrimary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: auth.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _viewMode == AuthViewMode.signIn
                                              ? Icons.login_rounded
                                              : (_viewMode == AuthViewMode.createAccount
                                                  ? Icons.person_add_rounded
                                                  : Icons.mail_outline_rounded),
                                          size: 19,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _getSubmitButtonText(isGujarati),
                                          style: GoogleFonts.notoSans(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),

                            const SizedBox(height: 18),

                            // Toggle Sign In / Create Account links
                            _buildFooterLinks(isGujarati),

                            const SizedBox(height: 12),

                            // Auto-fill Demo credentials helper
                            _buildDemoHelper(isGujarati),
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
    );
  }

  Widget _buildHeader(bool isGujarati) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 22, 20, 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // National Portal Badge Emblem
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.saffronLight.withOpacity(0.8), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/emblem_india.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.account_balance,
                  color: AppColors.saffronPrimary,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Titles
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getHeaderTitle(isGujarati),
                  style: GoogleFonts.notoSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyDark,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _getHeaderSubtitle(isGujarati),
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          // Close button
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textMuted, size: 22),
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            splashRadius: 20,
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleButton(AuthProvider auth, bool isGujarati) {
    return OutlinedButton(
      onPressed: auth.isLoading ? null : () => _handleGoogleSignIn(auth),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.2),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Google Logo
          _buildGoogleLogo(),
          const SizedBox(width: 12),
          Text(
            isGujarati ? 'Google સાથે આગળ વધો' : 'Continue with Google',
            style: GoogleFonts.notoSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleLogo() {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: GoogleLogoPainter(),
      ),
    );
  }

  Widget _buildOrDivider(bool isGujarati) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            isGujarati ? 'અથવા ઈમેલ દ્વારા લોગિન કરો' : 'OR CONTINUE WITH EMAIL',
            style: GoogleFonts.notoSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.notoSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: GoogleFonts.notoSans(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.notoSans(color: AppColors.textMuted, fontSize: 13.5),
            prefixIcon: Icon(icon, size: 20, color: AppColors.textMuted),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.navyMedium, width: 1.6),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.warningRed, width: 1.4),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildAlertBanner({required String message, required bool isError}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isError ? const Color(0xFFFCA5A5) : const Color(0xFF6EE7B7),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? AppColors.warningRed : AppColors.emeraldPrimary,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.notoSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: isError ? const Color(0xFF991B1B) : const Color(0xFF065F46),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLinks(bool isGujarati) {
    if (_viewMode == AuthViewMode.signIn) {
      return Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          Text(
            isGujarati ? 'ખાતું નથી? ' : "Don't have an account? ",
            style: GoogleFonts.notoSans(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          InkWell(
            onTap: () => _switchMode(AuthViewMode.createAccount),
            child: Text(
              isGujarati ? 'ખાતું બનાવો (Create Account)' : 'Create Account',
              style: GoogleFonts.notoSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.emeraldPrimary,
              ),
            ),
          ),
        ],
      );
    } else if (_viewMode == AuthViewMode.createAccount) {
      return Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          Text(
            isGujarati ? 'પહેલેથી ખાતું છે? ' : 'Already have an account? ',
            style: GoogleFonts.notoSans(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          InkWell(
            onTap: () => _switchMode(AuthViewMode.signIn),
            child: Text(
              isGujarati ? 'સાઇન ઇન કરો (Sign In)' : 'Sign In',
              style: GoogleFonts.notoSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.saffronPrimary,
              ),
            ),
          ),
        ],
      );
    } else {
      return Center(
        child: TextButton.icon(
          onPressed: () => _switchMode(AuthViewMode.signIn),
          icon: const Icon(Icons.arrow_back, size: 16, color: AppColors.navyMedium),
          label: Text(
            isGujarati ? 'સાઇન ઇન પર પાછા જાઓ' : 'Back to Sign In',
            style: GoogleFonts.notoSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.navyMedium,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildDemoHelper(bool isGujarati) {
    return InkWell(
      onTap: _fillDemoCredentials,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          children: [
            const Icon(Icons.flash_on, size: 14, color: AppColors.saffronPrimary),
            Text(
              isGujarati ? 'ઝડપી પરીક્ષણ: ડેમો સિટિઝન ઓટો-ફિલ' : 'Quick Demo Citizen: Click to auto-fill',
              style: GoogleFonts.notoSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getHeaderTitle(bool isGujarati) {
    switch (_viewMode) {
      case AuthViewMode.signIn:
        return isGujarati ? 'લોક સમાધાનમાં સાઇન ઇન કરો' : 'Sign In to Lok Samadhan';
      case AuthViewMode.createAccount:
        return isGujarati ? 'નાગરિક ખાતું બનાવો' : 'Create Citizen Account';
      case AuthViewMode.forgotPassword:
        return isGujarati ? 'પાસવર્ડ રીસેટ કરો' : 'Reset Your Password';
    }
  }

  String _getHeaderSubtitle(bool isGujarati) {
    switch (_viewMode) {
      case AuthViewMode.signIn:
        return isGujarati
            ? 'તમારી ફરિયાદો અને અરજીની સ્થિતિ ઍક્સેસ કરો.'
            : 'Access your grievances, complaints and application status.';
      case AuthViewMode.createAccount:
        return isGujarati
            ? 'સરકારી સેવાઓ અને ઝડપી ઉકેલ માટે નોંધણી કરો.'
            : 'Register for fast grievance redressal and real-time SLA updates.';
      case AuthViewMode.forgotPassword:
        return isGujarati
            ? 'પાસવર્ડ પુનઃપ્રાપ્તિ માટે તમારું ઈમેલ દાખલ કરો.'
            : 'Enter your registered email address to receive password reset link.';
    }
  }

  String _getSubmitButtonText(bool isGujarati) {
    switch (_viewMode) {
      case AuthViewMode.signIn:
        return isGujarati ? 'સાઇન ઇન (Sign In)' : 'Sign In';
      case AuthViewMode.createAccount:
        return isGujarati ? 'ખાતું બનાવો (Create Account)' : 'Create Account';
      case AuthViewMode.forgotPassword:
        return isGujarati ? 'રીસેટ લિંક મોકલો' : 'Send Reset Link';
    }
  }
}

/// Official 4-color Google G icon vector painter
class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Red
    final paintRed = Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.fill;
    // Blue
    final paintBlue = Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.fill;
    // Yellow
    final paintYellow = Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.fill;
    // Green
    final paintGreen = Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.fill;

    // Draw Blue bar & arc
    final pathBlue = Path()
      ..moveTo(w * 0.98, h * 0.5)
      ..lineTo(w * 0.5, h * 0.5)
      ..lineTo(w * 0.5, h * 0.68)
      ..lineTo(w * 0.81, h * 0.68)
      ..arcToPoint(Offset(w * 0.72, h * 0.85), radius: Radius.circular(w * 0.5))
      ..lineTo(w * 0.88, h * 0.98)
      ..arcToPoint(Offset(w * 0.98, h * 0.5), radius: Radius.circular(w * 0.5))
      ..close();
    canvas.drawPath(pathBlue, paintBlue);

    // Draw Green arc
    final pathGreen = Path()
      ..moveTo(w * 0.5, h)
      ..arcToPoint(Offset(w * 0.88, h * 0.98), radius: Radius.circular(w * 0.5), clockwise: false)
      ..lineTo(w * 0.72, h * 0.85)
      ..arcToPoint(Offset(w * 0.5, h * 0.82), radius: Radius.circular(w * 0.32), clockwise: false)
      ..lineTo(w * 0.5, h)
      ..close();
    canvas.drawPath(pathGreen, paintGreen);

    // Draw Yellow arc
    final pathYellow = Path()
      ..moveTo(w * 0.18, h * 0.75)
      ..arcToPoint(Offset(w * 0.5, h), radius: Radius.circular(w * 0.5), clockwise: false)
      ..lineTo(w * 0.5, h * 0.82)
      ..arcToPoint(Offset(w * 0.28, h * 0.68), radius: Radius.circular(w * 0.32), clockwise: false)
      ..lineTo(w * 0.18, h * 0.75)
      ..close();
    canvas.drawPath(pathYellow, paintYellow);

    // Draw Red arc
    final pathRed = Path()
      ..moveTo(w * 0.5, 0)
      ..arcToPoint(Offset(w * 0.92, h * 0.22), radius: Radius.circular(w * 0.5))
      ..lineTo(w * 0.76, h * 0.35)
      ..arcToPoint(Offset(w * 0.5, h * 0.18), radius: Radius.circular(w * 0.32), clockwise: false)
      ..arcToPoint(Offset(w * 0.28, h * 0.32), radius: Radius.circular(w * 0.32), clockwise: false)
      ..lineTo(w * 0.14, h * 0.22)
      ..arcToPoint(Offset(w * 0.5, 0), radius: Radius.circular(w * 0.5))
      ..close();
    canvas.drawPath(pathRed, paintRed);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
