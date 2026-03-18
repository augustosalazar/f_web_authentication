import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loggy/loggy.dart';
import '../viewmodels/authentication_controller.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final controllerName = TextEditingController(text: 'One name');
  final controllerEmail = TextEditingController(text: 'a@a.com');
  final controllerPassword = TextEditingController(text: 'ThePassword!1');
  final controllerConfirmPassword =
      TextEditingController(text: 'ThePassword!1');
  final controllerValidation = TextEditingController();

  final AuthenticationController authenticationController = Get.find();

  // Focus para navegación rápida
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  final _validationFocus = FocusNode();

  bool registerPhase = true;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    controllerName.dispose();
    controllerEmail.dispose();
    controllerPassword.dispose();
    controllerConfirmPassword.dispose();
    controllerValidation.dispose();

    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _validationFocus.dispose();

    super.dispose();
  }

  Future<void> _signup(theName, theEmail, thePassword, direct) async {
    try {
      await authenticationController.signUp(
          theName, theEmail, thePassword, direct);

      if (direct) {
        Get.snackbar(
          "Sign Up",
          'User created successfully',
          icon: const Icon(Icons.person, color: Colors.red),
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      setState(() => registerPhase = false);

      Get.snackbar(
        "Sign Up",
        'User created successfully, check your email for verification',
        icon: const Icon(Icons.person, color: Colors.red),
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (err) {
      logError('SignUp error $err');
      Get.snackbar(
        "Sign Up",
        err.toString(),
        icon: const Icon(Icons.person, color: Colors.red),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _validate(email, validationCode) async {
    try {
      await authenticationController.validate(email, validationCode);
      Get.snackbar(
        "Validation",
        'Email validated successfully',
        icon: const Icon(Icons.check, color: Colors.green),
        snackPosition: SnackPosition.BOTTOM,
      );
      setState(() => registerPhase = true);
    } catch (err) {
      logError('Validation error $err');
      Get.snackbar(
        "Validation",
        err.toString(),
        icon: const Icon(Icons.error, color: Colors.red),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Sign Up"),
        centerTitle: true,
      ),
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
                child: IntrinsicHeight(
                  child: registerPhase
                      ? registerPhaseWidget(context, GlobalKey<FormState>())
                      : validationPhaseWidget(context, GlobalKey<FormState>()),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Form validationPhaseWidget(BuildContext context, GlobalKey<FormState> key) {
    return Form(
      key: key,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Validate your email", style: TextStyle(fontSize: 20)),
          const SizedBox(height: 20),
          TextFormField(
            focusNode: _validationFocus,
            controller: controllerValidation,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: "Validation code"),
            onFieldSubmitted: (_) async {
              FocusScope.of(context).unfocus();
              final form = key.currentState;
              form!.save();
              if (key.currentState!.validate()) {
                logInfo('Validation form ok');
                await _validate(controllerEmail.text.trim(),
                    controllerValidation.text.trim());
              } else {
                logError('Validation form nok');
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                logError('Validation code is empty');
                return "Enter validation code";
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () async {
                  final form = key.currentState;
                  form!.save();
                  FocusScope.of(context).unfocus();

                  if (key.currentState!.validate()) {
                    logInfo('Validation form ok');
                    await _validate(controllerEmail.text.trim(),
                        controllerValidation.text.trim());
                  } else {
                    logError('Validation form nok');
                  }
                },
                child: const Text("Validate"),
              ),
              TextButton(
                onPressed: () => setState(() => registerPhase = true),
                child: const Text("Back"),
              )
            ],
          ),
        ],
      ),
    );
  }

  Form registerPhaseWidget(BuildContext context, GlobalKey<FormState> key) {
    return Form(
      key: key,
      child: AutofillGroup(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Sign Up Information", style: TextStyle(fontSize: 20)),
            const SizedBox(height: 20),

            // NOMBRE
            TextFormField(
              focusNode: _nameFocus,
              controller: controllerName,
              decoration: const InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              onFieldSubmitted: (_) => _emailFocus.requestFocus(),
              validator: (value) {
                final v = value?.trim() ?? '';
                if (v.isEmpty) return "Enter your name";
                return null;
              },
            ),

            const SizedBox(height: 20),

            // EMAIL
            TextFormField(
              focusNode: _emailFocus,
              controller: controllerEmail,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email address",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
              ),
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  logError('SignUp validation empty email');
                  return "Enter email";
                } else if (!value.contains('@')) {
                  logError('SignUp validation invalid email');
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
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  tooltip: _obscurePassword
                      ? 'Mostrar contraseña'
                      : 'Ocultar contraseña',
                ),
              ),
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
              validator: (value) {
                final v = value ?? '';
                if (v.isEmpty) return "Enter password";
                if (v.length < 6) {
                  return "Password should have at least 6 characters";
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // CONFIRM PASSWORD (valida que coincidan)
            TextFormField(
              focusNode: _confirmPasswordFocus,
              controller: controllerConfirmPassword,
              decoration: InputDecoration(
                labelText: "Confirm password",
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword),
                  tooltip: _obscureConfirmPassword
                      ? 'Mostrar contraseña'
                      : 'Ocultar contraseña',
                ),
              ),
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) async {
                FocusScope.of(context).unfocus();
                final form = key.currentState;
                form!.save();

                if (key.currentState!.validate()) {
                  logInfo('SignUp validation form ok');
                  await _signup(
                    controllerName.text.trim(),
                    controllerEmail.text.trim(),
                    controllerPassword.text,
                    true,
                  );
                } else {
                  logError('SignUp validation form nok');
                }
              },
              validator: (value) {
                final v = value ?? '';
                if (v.isEmpty) return "Confirm your password";
                if (v != controllerPassword.text) {
                  return "Passwords do not match";
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () async {
                      final form = key.currentState;
                      form!.save();
                      FocusScope.of(context).unfocus();

                      if (key.currentState!.validate()) {
                        logInfo('SignUp validation form ok');

                        await _signup(
                          controllerName.text.trim(),
                          controllerEmail.text.trim(),
                          controllerPassword.text,
                          true,
                        );
                      } else {
                        logError('SignUp validation form nok');
                      }
                    },
                    child: const Text("Submit"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
