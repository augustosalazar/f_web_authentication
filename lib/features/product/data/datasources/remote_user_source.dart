import 'dart:convert';
import 'package:loggy/loggy.dart';
import '../../domain/models/user.dart';
import 'package:http/http.dart' as http;

import 'i_remote_user_source.dart';

class RemoteUserSource implements IRemoteUserSource {
  final http.Client httpClient;

  final String contractKey = '87f1ab21-327b-4dcc-bea0-067a47214eca';
  final String baseUrl = 'http://unidb.openlab.uninorte.edu.co';

  RemoteUserSource({http.Client? client})
      : httpClient = client ?? http.Client();

  @override
  Future<List<User>> getUsers() async {
    List<User> users = [];
    var request = Uri.parse("$baseUrl/$contractKey/data/users/all")
        .resolveUri(Uri(queryParameters: {
      "format": 'json',
    }));

    var response = await httpClient.get(request);

    if (response.statusCode == 200) {
      //logInfo(response.body);
      //final data = jsonDecode(response.body);

      Map<String, dynamic> decodedJson = jsonDecode(response.body);
      final data = decodedJson['data'];

      logInfo(data);

      users = List<User>.from(data.map((x) => User.fromJson(x)));
      //users.removeAt(1);
    } else {
      logError("Got error code ${response.statusCode}");
      return Future.error('Error code ${response.statusCode}');
    }

    return Future.value(users);
  }

  @override
  Future<bool> addUser(User user) async {
    logInfo("Web service, Adding user");

    final response = await httpClient.post(
      Uri.parse("$baseUrl/$contractKey/data/store"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'table_name': 'users',
        'data': user.toJson(),
      }),
    );

    if (response.statusCode == 201) {
      //logInfo(response.body);
      return Future.value(true);
    } else {
      logError("Got error code ${response.statusCode}");
      logError(response.body);
      return Future.value(false);
    }
  }

  @override
  Future<bool> updateUser(User user) async {
    logInfo("Web service, Updating user with id $user");
    final response = await httpClient.put(
      Uri.parse("$baseUrl/$contractKey/data/users/update/${user.id}"),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'data': user.toJsonNoId(),
      }),
    );

    logInfo("updateUser response status code ${response.statusCode}");
    logInfo("updateUser response body ${response.body}");
    if (response.statusCode == 200) {
      return Future.value(true);
    } else {
      logError("Got error code ${response.statusCode}");
      return Future.value(false);
    }
  }

  @override
  Future<bool> deleteUser(User user) async {
    logInfo("Web service, Deleting user with id $user");
    final response = await httpClient.delete(
      Uri.parse("$baseUrl/$contractKey/data/users/delete/${user.id}"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    logInfo("deleteUser response status code ${response.statusCode}");
    logInfo("deleteUser response body ${response.body}");
    if (response.statusCode == 200) {
      //logInfo(response.body);
      return Future.value(true);
    } else {
      logError("Got error code ${response.statusCode}");
      return Future.value(false);
    }
  }

  @override
  Future<bool> deleteUsers() async {
    List<User> users = await getUsers();
    for (var user in users) {
      await deleteUser(user);
    }
    return Future.value(true);
  }
}
