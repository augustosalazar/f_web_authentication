import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loggy/loggy.dart';
import '../controller/authentication_controller.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final controllerEmail =
      TextEditingController(text: 'augustosalazar@uninorte.edu.co');
  final controllerPassword = TextEditingController(text: 'ThePassword1!');
  final controllerValidation = TextEditingController();
  AuthenticationController authenticationController = Get.find();
  bool registerPhase = true;

  _signup(theEmail, thePassword) async {
    try {
      await authenticationController.signUp(theEmail, thePassword);

      setState(() {
        registerPhase = false;
      });

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

  _validate(email, validationCode) async {
    try {
      await authenticationController.validate(email, validationCode);
      Get.snackbar(
        "Validation",
        'Email validated successfully',
        icon: const Icon(Icons.check, color: Colors.green),
        snackPosition: SnackPosition.BOTTOM,
      );
      setState(() {
        registerPhase = true;
      });
      //Get.offAllNamed('/login');
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
        appBar: AppBar(),
        body: Center(
            child: Container(
                padding: const EdgeInsets.all(20),
                child: registerPhase
                    ? registerPhaseWidget(context, GlobalKey<FormState>())
                    : validationPhaseWidget(context, GlobalKey<FormState>()))));
  }

  Form validationPhaseWidget(BuildContext context, GlobalKey<FormState> key) {
    return Form(
      key: key,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text(
          "Validate your email",
          style: TextStyle(fontSize: 20),
        ),
        const SizedBox(
          height: 20,
        ),
        TextFormField(
          keyboardType: TextInputType.emailAddress,
          controller: controllerValidation,
          decoration: const InputDecoration(labelText: "Validation code"),
          validator: (value) {
            if (value == null || value.isEmpty) {
              logError('Validation code is empty');
              return "Enter validation code";
            }
            return null;
          },
        ),
        const SizedBox(
          height: 20,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
                onPressed: () async {
                  final form = key.currentState;
                  form!.save();
                  FocusScope.of(context).requestFocus(FocusNode());
                  if (key.currentState!.validate()) {
                    logInfo('Validation form ok');
                    await _validate(
                        controllerEmail.text, controllerValidation.text);
                  } else {
                    logError('Validation form nok');
                  }
                },
                child: const Text("Validate")),
            TextButton(
                onPressed: () {
                  setState(() {
                    registerPhase = true;
                  });
                },
                child: const Text("Back"))
          ],
        ),
      ]),
    );
  }

  Form registerPhaseWidget(BuildContext context, GlobalKey<FormState> key) {
    return Form(
      key: key,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text(
          "Sign Up Information",
          style: TextStyle(fontSize: 20),
        ),
        const SizedBox(
          height: 20,
        ),
        TextFormField(
          keyboardType: TextInputType.emailAddress,
          controller: controllerEmail,
          decoration: const InputDecoration(labelText: "Email address"),
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
        const SizedBox(
          height: 20,
        ),
        TextFormField(
          controller: controllerPassword,
          decoration: const InputDecoration(labelText: "Password"),
          keyboardType: TextInputType.number,
          obscureText: true,
          validator: (value) {
            if (value!.isEmpty) {
              return "Enter password";
            } else if (value.length < 6) {
              return "Password should have at least 6 characters";
            }
            return null;
          },
        ),
        const SizedBox(
          height: 20,
        ),
        TextButton(
            onPressed: () async {
              final form = key.currentState;
              form!.save();
              // this line dismiss the keyboard by taking away the focus of the TextFormField and giving it to an unused
              FocusScope.of(context).requestFocus(FocusNode());
              if (key.currentState!.validate()) {
                logInfo('SignUp validation form ok');
                await _signup(controllerEmail.text, controllerPassword.text);
              } else {
                logError('SignUp validation form nok');
              }
            },
            child: const Text("Submit")),
      ]),
    );
  }
}
