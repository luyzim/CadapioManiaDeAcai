import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/session_controller.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/email_validator.dart';
import '../../shared/widgets/auth_input_field.dart';
import '../../shared/widgets/auth_shell.dart';
import '../../shared/widgets/gradient_button.dart';
import '../about/about_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  static const String routeName = '/forgot-password';

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();

  bool _isSubmitting = false;
  String? _feedbackMessage;
  bool _isError = false;
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
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

  void _handleEmailChanged(String value) {
    final nextEmailError = _emailError == null ? null : _validateEmail(value);

    if (nextEmailError != _emailError || _feedbackMessage != null) {
      setState(() {
        _emailError = nextEmailError;
        _feedbackMessage = null;
      });
    }
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim().toLowerCase();
    final emailError = _validateEmail(email);

    setState(() {
      _feedbackMessage = null;
      _isError = false;
      _emailError = emailError;
    });

    if (emailError != null) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final message = await context
          .read<SessionController>()
          .requestPasswordReset(email: email);
      _emailController.clear();
      _showFeedback(message, isError: false);
    } on AuthFailure catch (error) {
      _showFeedback(error.message, isError: true);
    } catch (_) {
      _showFeedback(
        'Falha ao solicitar a recuperacao de senha.',
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
      headerSubtitle: 'Recuperacao de senha',
      cardTitle: 'Esqueceu a senha?',
      cardSubtitle:
          'Informe o email cadastrado para receber as instrucoes de redefinicao.',
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AuthInputField(
            label: 'Email cadastrado',
            controller: _emailController,
            hintText: 'seu@email.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            errorText: _emailError,
            onChanged: _handleEmailChanged,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 22),
          GradientButton(
            label: 'Solicitar recuperacao',
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
                'Lembrou da senha? ',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white60,
                    ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Voltar para o login'),
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
