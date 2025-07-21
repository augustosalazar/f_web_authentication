import 'package:f_web_authentication/features/auth/ui/pages/forgot_password_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loggy/loggy.dart';
import '../controller/authentication_controller.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final controllerEmail =
      TextEditingController(text: 'augustosalazar@uninorte.edu.co');
  final controllerPassword = TextEditingController(text: 'ThePassword1!');
  AuthenticationController authenticationController = Get.find();

  _login(theEmail, thePassword) async {
    logInfo('_login $theEmail $thePassword');
    try {
      await authenticationController.login(theEmail, thePassword);
    } catch (err) {
      Get.snackbar(
        "Login",
        err.toString(),
        icon: const Icon(Icons.person, color: Colors.red),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Form(
              key: _formKey,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Login to access your account",
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    TextFormField(
                      keyboardType: TextInputType.emailAddress,
                      controller: controllerEmail,
                      decoration: const InputDecoration(
                        labelText: "Email address",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                      ),
                      validator: (String? value) {
                        if (value!.isEmpty) {
                          return "Enter email";
                        } else if (!value.contains('@')) {
                          return "Enter valid email address";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    TextFormField(
                      controller: controllerPassword,
                      decoration: const InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                      ),
                      obscureText: true,
                      validator: (String? value) {
                        if (value!.isEmpty) {
                          return "Enter password";
                        } else if (value.length < 6) {
                          return "Password should have at least 6 characters";
                        }
                        return null;
                      },
                      onFieldSubmitted: (value) async {
                        FocusScope.of(context).requestFocus(FocusNode());
                        final form = _formKey.currentState;
                        form!.save();
                        if (_formKey.currentState!.validate()) {
                          await _login(
                              controllerEmail.text, controllerPassword.text);
                        }
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const ForgotPasswordPage()));
                            },
                            child: const Text("Forgot password?")),
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: FilledButton.tonal(
                                onPressed: () async {
                                  // this line dismiss the keyboard by taking away the focus of the TextFormField and giving it to an unused
                                  FocusScope.of(context)
                                      .requestFocus(FocusNode());
                                  final form = _formKey.currentState;
                                  form!.save();
                                  if (_formKey.currentState!.validate()) {
                                    await _login(controllerEmail.text,
                                        controllerPassword.text);
                                  }
                                },
                                child: const Text("Login"))),
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    TextButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignUpPage()));
                        },
                        child: const Text("Create account"))
                  ]),
            ),
          ],
        ),
      ),
    );
  }
}
