import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'central.dart';
import 'features/auth/ui/viewmodels/authentication_controller.dart';
import 'features/product/domain/repositories/i_product_repository.dart';

/// Las reglas que cruzan módulos.
///
/// Los `register*` de cada feature dicen cómo se construye lo suyo. Aquí va lo
/// que ningún módulo puede decidir solo porque involucra a otro. Hoy es una
/// sola cosa: que al salir se tire la caché de productos.
///
/// Está fuera de las features a propósito. Si la autenticación supiera que
/// existen los productos, cada módulo nuevo con algo que limpiar habría que
/// añadirlo dentro de `logOut`, y cerrar sesión reventaría en cuanto ese módulo
/// no estuviera registrado. Esto es lo único que conoce a todos.
///
/// Y está fuera de [Central] también a propósito, aunque sea la pantalla que
/// mira la sesión: `Central` se reconstruye cada vez que cambia `logged`, y
/// enlazar desde un `build` pondría un escuchador nuevo en cada reconstrucción.
///
/// Sacar a quien se le cae la sesión **no** está aquí: desde que la sesión es
/// un flujo del paquete, la autenticación se entera sola y no necesita que
/// nadie se lo diga desde fuera.
///
/// Devuelve con qué deshacer los enlaces. La app no lo usa —vive lo que vive
/// ella—, pero las pruebas sí: sin poder soltarlos, una prueba dejaría el suyo
/// puesto y la siguiente se encontraría con el anterior escuchando.
VoidCallback wireApp() => clearCachesOnLogOut();

/// Al cerrar sesión, tirar lo que se guardó de la sesión anterior.
VoidCallback clearCachesOnLogOut() {
  final auth = Get.find<AuthenticationController>();

  final vigilante = ever<bool>(auth.logged, (isLogged) {
    if (isLogged) return;
    Get.find<IProductRepository>().clearCache();
  });

  return vigilante.dispose;
}
