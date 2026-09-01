import 'package:roble/roble.dart';

/// Texto que se le enseña a quien está usando la app cuando algo falla.
///
/// El mensaje del servidor cuando lo hay, porque suele ser más útil que
/// cualquier cosa que se pueda escribir aquí sin saber qué pasó: el caso que
/// más se da en clase es que al proyecto le falte algo —un bucket sin conectar,
/// una consulta guardada que todavía no existe— y el servidor lo dice ya con
/// qué hacer y dónde.
///
/// Para lo que no viene de Roble hay dos posturas, y cada pantalla elige:
/// sin [fallback] se enseña la excepción tal cual, que es lo que quiere una
/// pantalla de desarrollo; con [fallback], una frase fija que no filtra nada.
String errorMessage(Object error, {String? fallback}) {
  if (error is RobleApiException) return error.message;
  return fallback ?? error.toString();
}
