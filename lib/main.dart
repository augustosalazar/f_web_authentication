import 'package:f_web_authentication/data/repositories/repository.dart';
import 'package:f_web_authentication/domain/use_case/user_usecase.dart';
import 'package:f_web_authentication/ui/central.dart';
import 'package:f_web_authentication/ui/controller/authentication_controller.dart';
import 'package:f_web_authentication/ui/controller/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import 'data/datasources/remote/authentication_datasource.dart';
import 'data/datasources/remote/users/remote_user_source.dart';
import 'domain/repositories/i_repository.dart';
import 'domain/use_case/authentication_usecase.dart';

void main() {
  Loggy.initLoggy(
    logPrinter: const PrettyPrinter(
      showColors: true,
    ),
  );

  Get.put<AuthenticationDatatasource>(AuthenticationDatatasource());
  Get.put<RemoteUserSource>(RemoteUserSource());
  Get.put<IRepository>(Repository(Get.find(), Get.find()));
  Get.put(AuthenticationUseCase());
  Get.put(UserUseCase(Get.find()));
  Get.put(AuthenticationController());
  Get.put(UserController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Central(),
    );
  }
}
