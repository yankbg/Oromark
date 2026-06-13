import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oromark/core/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  int _selectedRole = 0;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _idFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }
  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _idFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }
  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if(!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading    = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    setState(() => _isLoading = false);

    final pwd = _passwordController.text;
    final id = _idController.text.trim();
    if (pwd == '1234') {
      Navigator.of(context).pushReplacementNamed(
        _selectedRole == 0 ? '/student/home' : '/lecturer/courses',
      );
    } else {
      setState(() =>
      _errorMessage = 'Wrong password. Use 1234 for mock login.'
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: Column(
        children: [
          _Header(selectedRole: _selectedRole),
          Expanded(
              child: _FormCard(
                formKey: _formKey,
                selectedRole: _selectedRole,
                onRoleChanged: (v) => setState(() {
                  _selectedRole = v;
                  _errorMessage = null;
                  _idController.clear();
                }),
                idController:     _idController,
                passwordController: _passwordController,
                idFocus:          _idFocus,
                passwordFocus:    _passwordFocus,
                obscurePassword:  _obscurePassword,
                onTogglePassword: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                ),
                errorMessage:     _errorMessage,
                isLoading:        _isLoading,
                onLogin:          _handleLogin,
              ),
          ),
        ],
      ),
    );
  }
}
//  Header — teal section with signal rings
class _Header extends StatelessWidget {
  final int selectedRole;
  const _Header({required this.selectedRole});

  @override
  Widget build(BuildContext context) {
    return  Container(
      color: AppColors.primary,
      child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 200,
            child: Stack(
              children: [
                ..._buildRings(),
                Positioned.fill(
                  child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment:  MainAxisAlignment.end,
                        children: [
                          Image.asset(
                            'assets/oromark.jpg',
                            height: 60,
                            fit:    BoxFit.contain,
                            colorBlendMode: BlendMode.srcIn,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Signal-based attendance · IUEA',
                            style: TextStyle(
                              fontSize:      13,
                              fontWeight:    FontWeight.w400,
                              // use white with reduced opacity for the header
                              color: Colors.white.withOpacity(0.65),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                  ),
                )
              ],
            ),
          )
      ),
    );
  }

  List<Widget> _buildRings() {
    final sizes   = [280.0, 200.0, 120.0];
    final offsets = [-60.0, -20.0, 20.0];
    return List.generate(3, (i) => Positioned(
      top:   -80,
      right: offsets[i],
      child: Container(
        width:  sizes[i],
        height: sizes[i],
        decoration: BoxDecoration(
          shape:  BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
    ));
  }
}
//  Form card — white rounded surface overlapping the header

class _FormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final int                  selectedRole;
  final Function(int)        onRoleChanged;
  final TextEditingController idController;
  final TextEditingController passwordController;
  final FocusNode            idFocus;
  final FocusNode            passwordFocus;
  final bool                 obscurePassword;
  final VoidCallback         onTogglePassword;
  final String?              errorMessage;
  final bool                 isLoading;
  final VoidCallback         onLogin;

  const _FormCard({
    required this.formKey,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.idController,
    required this.passwordController,
    required this.idFocus,
    required this.passwordFocus,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.errorMessage,
    required this.isLoading,
    required this.onLogin,
});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
        offset: const Offset(0, -24),
      child: Container(

          decoration: const BoxDecoration(
            color: AppColors.bgPrimary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sign in',
                    style: TextStyle(
                      fontSize:    22,
                      fontWeight:  FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Select your role to continue',
                    style: TextStyle(
                      fontSize:      14,
                      fontWeight:    FontWeight.w400,
                      // AppColors.textSecondary = #6B7280
                      color:         AppColors.textSecondary,
                      letterSpacing: 0.25,
                      height:        1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _RoleCards(
                    selected:  selectedRole,
                    onChanged: onRoleChanged,
                  ),
                  const SizedBox(height: 20),
                  _SectionDivider(label: 'CREDENTIALS'),
                  const SizedBox(height: 16),

                // ── Error banner ────────────────────────────
                 if (errorMessage != null) ...[
                 _ErrorBanner(message: errorMessage!),
                 const SizedBox(height: 14),
                 ],
                  _FieldLabel(
                  label: selectedRole == 0
                  ? 'STUDENT ID / EMAIL'
                    : 'LECTURER EMAIL',
                  ),
                  const SizedBox(height: 6),
                  _OutlinedField(
                    controller:   idController,
                    focusNode:    idFocus,
                    nextFocus:    passwordFocus,
                    hintText:     selectedRole == 0
                        ? 'e.g. 2023/CS/001'
                        : 'e.g. john@iuea.ac.ug',
                    keyboardType: selectedRole == 0
                        ? TextInputType.text
                        : TextInputType.emailAddress,
                    prefixIcon:   Icons.person_outline_rounded,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return selectedRole == 0
                            ? 'Enter your student ID or email'
                            : 'Enter your email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Password field ─────────────────────────
                  const _FieldLabel(label: 'PASSWORD'),
                  const SizedBox(height: 6),
                  _OutlinedField(
                    controller:  passwordController,
                    focusNode:   passwordFocus,
                    hintText:    '••••••••',
                    obscureText: obscurePassword,
                    prefixIcon:  Icons.lock_outline_rounded,
                    suffixIcon:  obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    onSuffixTap: onTogglePassword,
                    onFieldSubmitted: (_) => onLogin(),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter your password';
                      if (v.length < 4)           return 'Password too short';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // ── Forgot password ────────────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {},
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          fontFamily:    'Inter',
                          fontSize:      12,
                          fontWeight:    FontWeight.w500,
                          color:         AppColors.primary,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Sign in button ─────────────────────────
                  _LoginButton(
                    isLoading: isLoading,
                    onTap:     onLogin,
                  ),
                  const SizedBox(height: 28),

                  // ── Security badges ─────────────────────────
                  const _SecurityBadges(),
              ],
              ),
            ),
          ),
      ),
    );
  }
}
//  Role cards
class _RoleCards extends StatelessWidget {
  final int           selected;
  final Function(int) onChanged;
  const _RoleCards({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RoleCard(
            icon:        Icons.school_outlined,
            label:       'Student',
            description: 'Mark attendance in class',
            isActive:    selected == 0,
            onTap:       () => onChanged(0),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RoleCard(
            icon:        Icons.co_present_outlined,
            label:       'Lecturer',
            description: 'Start and manage sessions',
            isActive:    selected == 1,
            onTap:       () => onChanged(1),
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final String       description;
  final bool         isActive;
  final VoidCallback onTap;
  const _RoleCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve:    Curves.easeInOut,
        padding:  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color:        isActive
              ? AppColors.primary.withOpacity(0.06)
              : AppColors.bgPrimary,
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : const Color(0xFFBEC9C3),
            width: isActive ? 2.0 : 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width:  36,
              height: 36,
              decoration: BoxDecoration(
                color:        isActive
                    ? AppColors.primary
                    : AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size:  18,
                color: isActive
                    ? Colors.white
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily:    'Inter',
                fontSize:      13,
                fontWeight:    FontWeight.w600,
                color:         isActive
                    ? AppColors.primary
                    : AppColors.textPrimary,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize:   10,
                color:      AppColors.textSecondary,
                height:     1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _SectionDivider extends StatelessWidget {
  final String label;
  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.bgTertiary, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily:    'Inter',
              fontSize:      11,
              fontWeight:    FontWeight.w500,
              color:         AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.bgTertiary, thickness: 1)),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily:    'Inter',
        fontSize:      12,
        fontWeight:    FontWeight.w500,
        color:         AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _OutlinedField extends StatelessWidget {
  final TextEditingController      controller;
  final FocusNode?                 focusNode;
  final FocusNode?                 nextFocus;
  final String                     hintText;
  final bool                       obscureText;
  final TextInputType              keyboardType;
  final IconData                   prefixIcon;
  final IconData?                  suffixIcon;
  final VoidCallback?              onSuffixTap;
  final String? Function(String?)? validator;
  final Function(String)?          onFieldSubmitted;

  const _OutlinedField({
    required this.controller,
    this.focusNode,
    this.nextFocus,
    required this.hintText,
    this.obscureText     = false,
    this.keyboardType    = TextInputType.text,
    required this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:      controller,
      focusNode:       focusNode,
      obscureText:     obscureText,
      keyboardType:    keyboardType,
      textInputAction: nextFocus != null
          ? TextInputAction.next
          : TextInputAction.done,
      onFieldSubmitted: (v) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        } else {
          onFieldSubmitted?.call(v);
        }
      },
      validator: validator,
      style: const TextStyle(
        fontSize:    14,
        fontWeight:  FontWeight.w400,
        color:       AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText:  hintText,
        hintStyle: const TextStyle(
          fontSize:   14,
          color:      AppColors.textTertiary,
        ),
        filled:    true,
        fillColor: AppColors.bgPrimary,
        prefixIcon: Icon(
          prefixIcon,
          size:  20,
          color: AppColors.textTertiary,
        ),
        suffixIcon: suffixIcon != null
            ? GestureDetector(
          onTap: onSuffixTap,
          child: Icon(
            suffixIcon,
            size:  20,
            color: AppColors.textTertiary,
          ),
        )
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical:   13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0xFFBEC9C3),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0xFFBEC9C3),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2.0,
          ),
        ),
        errorStyle: const TextStyle(
          fontSize:   12,
          color:      AppColors.error,
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:        AppColors.absentBg,
        border:       Border.all(color: AppColors.error),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size:  16,
            color: AppColors.absentText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize:   12,
                color:      AppColors.absentText,
                height:     1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  final bool         isLoading;
  final VoidCallback onTap;
  const _LoginButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor:         AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
          foregroundColor:         Colors.white,
          elevation:               0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? const SizedBox(
          width:  20,
          height: 20,
          child:  CircularProgressIndicator(
            strokeWidth: 2,
            color:       Colors.white,
          ),
        )
            : const Row(
          mainAxisSize:     MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Sign in',
              style: TextStyle(
                fontSize:      15,
                fontWeight:    FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _SecurityBadges extends StatelessWidget {
  const _SecurityBadges();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Badge(
          label:    'Network secured',
          dotColor: AppColors.success,
        ),
        const SizedBox(width: 8),
        _Badge(
          label:    'End-to-end encrypted',
          dotColor: AppColors.primary,
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color  dotColor;
  const _Badge({required this.label, required this.dotColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:        AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width:  6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize:    11,
              fontWeight:  FontWeight.w400,
              color:       AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}


