import 'package:get/get.dart';
import 'package:roble/roble.dart';

import 'error_message.dart';

/// Se levanta cuando la sesión se cae sola, sin que nadie haya cerrado sesión.
///
/// No la baja nadie desde aquí: quien la escucha —`main`— cierra la sesión, y
/// eso ya devuelve a la pantalla de entrada. Se vuelve a bajar al armar el
/// enlace, que es lo que ocurre al arrancar.
final sessionExpired = false.obs;

/// Lo mismo que [errorMessage], pero además se fija en si lo que falló dice
/// que la sesión ya no vale.
///
/// Los controladores llaman a esto en sus `catch` en vez de a [errorMessage].
/// No conocen la autenticación —ni deben—: solo levantan la bandera, y quien
/// puede hacer algo con ella la escucha desde `main`.
///
/// El aviso bueno es el del paquete ([RobleApiDataBase.onSessionExpired]), que
/// se entera antes y sin depender de que nadie llame a nada. Esto es la red de
/// abajo: sirve para las rutas que el paquete no cubre —el socket de tiempo
/// real, un token rechazado sin intento de refresco— y para cuando el paquete
/// es más viejo que la app.
String reportError(Object error, {String? fallback}) {
  if (error is RobleApiAuthException) sessionExpired.value = true;
  return errorMessage(error, fallback: fallback);
}
