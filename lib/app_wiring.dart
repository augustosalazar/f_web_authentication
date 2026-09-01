import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:roble/roble.dart';

import 'central.dart';
import 'core/session_expiry.dart';
import 'features/auth/ui/viewmodels/authentication_controller.dart';
import 'features/product/domain/repositories/i_product_repository.dart';

/// Las reglas que cruzan módulos.
///
/// Los `register*` de cada feature dicen cómo se construye lo suyo. Aquí van
/// las decisiones que ningún módulo puede tomar solo porque involucran a otro:
/// que al salir se tire la caché de productos, o que una sesión caída saque a
/// quien la tenía.
///
/// Están fuera de las features a propósito. Si la autenticación supiera que
/// existen los productos, cada módulo nuevo con algo que limpiar habría que
/// añadirlo dentro de `logOut`, y cerrar sesión reventaría en cuanto ese módulo
/// no estuviera registrado. Esto es lo único que conoce a todos.
///
/// Y están fuera de [Central] también a propósito, aunque sea la pantalla que
/// mira la sesión: `Central` se reconstruye cada vez que cambia `logged`, y
/// enlazar desde un `build` pondría un escuchador nuevo en cada reconstrucción.
///
/// Devuelve con qué deshacer todos los enlaces. La app no lo usa —vive lo que
/// vive ella—, pero las pruebas sí: sin poder soltarlos, una prueba dejaría los
/// suyos puestos y la siguiente se encontraría con los anteriores escuchando.
VoidCallback wireApp(RobleApiDataBase roble) {
  final soltarCaches = clearCachesOnLogOut();
  final soltarSesion = closeSessionWhenItExpires(roble);

  return () {
    soltarCaches();
    soltarSesion();
  };
}

/// Al cerrar sesión, tirar lo que se guardó de la sesión anterior.
VoidCallback clearCachesOnLogOut() {
  final auth = Get.find<AuthenticationController>();

  final vigilante = ever<bool>(auth.logged, (isLogged) {
    if (isLogged) return;
    Get.find<IProductRepository>().clearCache();
  });

  return vigilante.dispose;
}

/// Cuando la sesión se cae sola, sacar a quien la tenía.
///
/// Se entra por dos sitios. El bueno es el aviso del paquete: se entera al
/// fallar el refresco, sin depender de que nadie estuviera mirando. El otro es
/// la bandera de `core`, que levantan los controladores al ver un
/// [RobleApiAuthException]; cubre lo que el paquete no ve —el socket de tiempo
/// real, sobre todo— y llega al mismo sitio.
///
/// Los dos acaban en `logOut`, que baja `logged`, y de ahí sale solo el resto:
/// [Central] vuelve a la pantalla de entrada y [clearCachesOnLogOut] tira lo
/// que quedara guardado.
VoidCallback closeSessionWhenItExpires(RobleApiDataBase roble) {
  final auth = Get.find<AuthenticationController>();

  Future<void> cerrar() async {
    // Si ya está fuera no hay nada que hacer: el aviso puede llegar de una
    // llamada que salió antes de cerrar sesión a mano.
    if (!auth.isLogged) return;

    await auth.logOut();
    auth.error.value = 'Tu sesión caducó. Vuelve a entrar.';
  }

  final suscripcion = roble.onSessionExpired.listen((_) => cerrar());

  final vigilante = ever<bool>(sessionExpired, (caida) {
    if (!caida) return;
    // Se baja aquí para que la próxima vez vuelva a avisar: `ever` solo salta
    // cuando el valor cambia.
    sessionExpired.value = false;
    cerrar();
  });

  return () {
    suscripcion.cancel();
    vigilante.dispose();
  };
}
