import 'package:f_web_authentication/features/auth/ui/pages/forgot_password_page.dart';
import 'package:f_web_authentication/main.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loggy/loggy.dart';
import '../viewmodels/authentication_controller.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final controllerEmail = TextEditingController(text: 'a@a.com');
  final controllerPassword = TextEditingController(text: 'ThePassword!1');

  final AuthenticationController authenticationController = Get.find();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;

  @override
  void dispose() {
    controllerEmail.dispose();
    controllerPassword.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _login(
      BuildContext context, String email, String password) async {
    logInfo('_login $email $password');
    try {
      await authenticationController.login(email, password);
    } catch (err) {
      messengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(err.toString())),
      );
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final form = _formKey.currentState;
    form!.save();

    if (_formKey.currentState!.validate()) {
      await _login(
        context,
        controllerEmail.text.trim(),
        controllerPassword.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            "Login to access your account",
                            style: TextStyle(fontSize: 20),
                          ),
                          const SizedBox(height: 30),

                          // EMAIL
                          TextFormField(
                            focusNode: _emailFocus,
                            keyboardType: TextInputType.emailAddress,
                            controller: controllerEmail,
                            decoration: const InputDecoration(
                              labelText: "Email address",
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(20)),
                              ),
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => FocusScope.of(context)
                                .requestFocus(_passwordFocus),
                            validator: (String? value) {
                              final v = value?.trim() ?? '';
                              if (v.isEmpty) return "Enter email";
                              if (!v.contains('@')) {
                                return "Enter valid email address";
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // PASSWORD
                          TextFormField(
                            focusNode: _passwordFocus,
                            controller: controllerPassword,
                            decoration: InputDecoration(
                              labelText: "Password",
                              border: const OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(20)),
                              ),
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                tooltip: _obscurePassword
                                    ? 'Mostrar contraseña'
                                    : 'Ocultar contraseña',
                              ),
                            ),
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            validator: (String? value) {
                              final v = value ?? '';
                              if (v.isEmpty) return "Enter password";
                              if (v.length < 6) {
                                return "Password should have at least 6 characters";
                              }
                              return null;
                            },
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  FocusScope.of(context).unfocus();
                                  Get.to(() => const ForgotPasswordPage());
                                },
                                child: const Text("Forgot password?"),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.tonal(
                                  onPressed: _submit,
                                  child: const Text("Login"),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          TextButton(
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              Get.to(() => const SignUpPage());
                            },
                            child: const Text("Create account"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
