import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/session_controller.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/email_validator.dart';
import '../../shared/widgets/auth_input_field.dart';
import '../../shared/widgets/auth_shell.dart';
import '../../shared/widgets/gradient_button.dart';
import '../about/about_page.dart';
import 'forgot_password_page.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static const String routeName = '/login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isSubmitting = false;
  String? _feedbackMessage;
  bool _isError = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String value) {
    final email = value.trim().toLowerCase();

    if (email.isEmpty) {
      return 'Informe seu e-mail.';
    }

    if (!EmailValidator.isValid(email)) {
      return 'Informe um e-mail valido.';
    }

    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) {
      return 'Informe sua senha.';
    }

    return null;
  }

  void _handleEmailChanged(String value) {
    final nextEmailError = _emailError == null ? null : _validateEmail(value);

    if (nextEmailError != _emailError || _feedbackMessage != null) {
      setState(() {
        _emailError = nextEmailError;
        _feedbackMessage = null;
      });
    }
  }

  void _handlePasswordChanged(String value) {
    final nextPasswordError =
        _passwordError == null ? null : _validatePassword(value);

    if (nextPasswordError != _passwordError || _feedbackMessage != null) {
      setState(() {
        _passwordError = nextPasswordError;
        _feedbackMessage = null;
      });
    }
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final emailError = _validateEmail(email);
    final passwordError = _validatePassword(password);

    setState(() {
      _feedbackMessage = null;
      _isError = false;
      _emailError = emailError;
      _passwordError = passwordError;
    });

    if (emailError != null || passwordError != null) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await context.read<SessionController>().login(
        email: email,
        password: password,
      );
    } on AuthFailure catch (error) {
      _showFeedback(error.message, isError: true);
    } catch (_) {
      _showFeedback(
        'Falha ao entrar. Tente novamente.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showFeedback(String message, {required bool isError}) {
    setState(() {
      _feedbackMessage = message;
      _isError = isError;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      headerSubtitle: 'Acesse sua conta',
      cardTitle: 'Login',
      cardSubtitle:
          'A autenticacao de clientes agora usa Firebase Authentication.',
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AuthInputField(
            label: 'Email',
            controller: _emailController,
            hintText: 'seu@email.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            errorText: _emailError,
            onChanged: _handleEmailChanged,
          ),
          const SizedBox(height: 16),
          AuthInputField(
            label: 'Senha',
            controller: _passwordController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            errorText: _passwordError,
            onChanged: _handlePasswordChanged,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed(ForgotPasswordPage.routeName);
              },
              child: const Text('Esqueceu a senha?'),
            ),
          ),
          const SizedBox(height: 6),
          GradientButton(
            label: 'Entrar',
            isLoading: _isSubmitting,
            onPressed: _submit,
          ),
          if (_feedbackMessage != null) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              _feedbackMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _isError
                    ? const Color(0xFFF87171)
                    : const Color(0xFF6EE7B7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
      footer: Column(
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(
                'Nao tem uma conta? ',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white60,
                    ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(SignUpPage.routeName);
                },
                child: const Text('Cadastre-se'),
              ),
            ],
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushNamed(AboutPage.routeName);
            },
            child: const Text('Sobre o projeto'),
          ),
        ],
      ),
    );
  }
}
