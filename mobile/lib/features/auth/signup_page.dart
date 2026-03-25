import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/session_controller.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/email_validator.dart';
import '../../shared/widgets/auth_input_field.dart';
import '../../shared/widgets/auth_shell.dart';
import '../../shared/widgets/gradient_button.dart';
import '../about/about_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  static const String routeName = '/signup';

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isSubmitting = false;
  String? _feedbackMessage;
  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName(String value) {
    if (value.trim().isEmpty) {
      return 'Informe seu nome.';
    }

    return null;
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

  String? _validatePhone(String value) {
    if (value.trim().isEmpty) {
      return 'Informe seu telefone.';
    }

    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) {
      return 'Informe uma senha.';
    }

    if (value.length < 6) {
      return 'A senha precisa ter pelo menos 6 caracteres.';
    }

    return null;
  }

  String? _validateConfirmPassword(String password, String confirmPassword) {
    if (confirmPassword.isEmpty) {
      return 'Confirme sua senha.';
    }

    if (password != confirmPassword) {
      return 'Senha e confirmacao de senha devem ser iguais.';
    }

    return null;
  }

  void _handleNameChanged(String value) {
    final nextError = _nameError == null ? null : _validateName(value);

    if (nextError != _nameError || _feedbackMessage != null) {
      setState(() {
        _nameError = nextError;
        _feedbackMessage = null;
      });
    }
  }

  void _handleEmailChanged(String value) {
    final nextError = _emailError == null ? null : _validateEmail(value);

    if (nextError != _emailError || _feedbackMessage != null) {
      setState(() {
        _emailError = nextError;
        _feedbackMessage = null;
      });
    }
  }

  void _handlePhoneChanged(String value) {
    final nextError = _phoneError == null ? null : _validatePhone(value);

    if (nextError != _phoneError || _feedbackMessage != null) {
      setState(() {
        _phoneError = nextError;
        _feedbackMessage = null;
      });
    }
  }

  void _handlePasswordChanged(String value) {
    final nextPasswordError =
        _passwordError == null ? null : _validatePassword(value);
    final nextConfirmPasswordError = _confirmPasswordError == null
        ? null
        : _validateConfirmPassword(value, _confirmPasswordController.text);

    if (nextPasswordError != _passwordError ||
        nextConfirmPasswordError != _confirmPasswordError ||
        _feedbackMessage != null) {
      setState(() {
        _passwordError = nextPasswordError;
        _confirmPasswordError = nextConfirmPasswordError;
        _feedbackMessage = null;
      });
    }
  }

  void _handleConfirmPasswordChanged(String value) {
    final nextError = _confirmPasswordError == null
        ? null
        : _validateConfirmPassword(_passwordController.text, value);

    if (nextError != _confirmPasswordError || _feedbackMessage != null) {
      setState(() {
        _confirmPasswordError = nextError;
        _feedbackMessage = null;
      });
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final nameError = _validateName(name);
    final emailError = _validateEmail(email);
    final phoneError = _validatePhone(phone);
    final passwordError = _validatePassword(password);
    final confirmPasswordError =
        _validateConfirmPassword(password, confirmPassword);

    setState(() {
      _feedbackMessage = null;
      _nameError = nameError;
      _emailError = emailError;
      _phoneError = phoneError;
      _passwordError = passwordError;
      _confirmPasswordError = confirmPasswordError;
    });

    if (nameError != null ||
        emailError != null ||
        phoneError != null ||
        passwordError != null ||
        confirmPasswordError != null) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await context.read<SessionController>().signUp(
        name: name,
        email: email,
        phone: phone,
        password: password,
        confirmPassword: confirmPassword,
      );
    } on AuthFailure catch (error) {
      _showFeedback(error.message);
    } catch (_) {
      _showFeedback('Falha no cadastro. Tente novamente.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showFeedback(String message) {
    setState(() => _feedbackMessage = message);
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      headerSubtitle: 'Crie sua conta',
      cardTitle: 'Cadastro',
      cardSubtitle:
          'O cadastro usa Firebase Authentication para armazenar as credenciais.',
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AuthInputField(
            label: 'Nome do usuario',
            controller: _nameController,
            hintText: 'Seu nome',
            textInputAction: TextInputAction.next,
            errorText: _nameError,
            onChanged: _handleNameChanged,
          ),
          const SizedBox(height: 16),
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
            label: 'Numero de telefone',
            controller: _phoneController,
            hintText: '(16) 99999-9999',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            errorText: _phoneError,
            onChanged: _handlePhoneChanged,
          ),
          const SizedBox(height: 16),
          AuthInputField(
            label: 'Senha',
            controller: _passwordController,
            obscureText: true,
            textInputAction: TextInputAction.next,
            errorText: _passwordError,
            onChanged: _handlePasswordChanged,
          ),
          const SizedBox(height: 16),
          AuthInputField(
            label: 'Confirmacao de senha',
            controller: _confirmPasswordController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            errorText: _confirmPasswordError,
            onChanged: _handleConfirmPasswordChanged,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 22),
          GradientButton(
            label: 'Cadastrar',
            isLoading: _isSubmitting,
            onPressed: _submit,
          ),
          if (_feedbackMessage != null) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              _feedbackMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFF87171),
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
                'Ja tem uma conta? ',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white60,
                    ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Faca login'),
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
