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
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor:          Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    return const Scaffold(
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
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment:  MainAxisAlignment.end,
                      children: [
                        Image.asset(
                          'assets/oromark.jpg',
                          height: 30,
                          fit:    BoxFit.contain,
                          color:  Colors.white,
                          colorBlendMode: BlendMode.srcIn,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Signal-based attendance · IUEA',
                          style: TextStyle(
                            fontFamily:    'Inter',
                            fontSize:      13,
                            fontWeight:    FontWeight.w400,
                            // AppColors.textSecondary would be too dark here
                            // use white with reduced opacity for the header
                            color: Colors.white.withOpacity(0.65),
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
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
