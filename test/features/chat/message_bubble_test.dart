import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f_web_authentication/core/app_theme.dart';
import 'package:f_web_authentication/features/chat/domain/models/message.dart';
import 'package:f_web_authentication/features/chat/ui/widgets/message_bubble.dart';

Message mensaje({String sender = 'ana@correo.com'}) => Message(
      id: 'k1',
      content: 'hola',
      sender: sender,
      sentAt: DateTime(2026, 8, 26, 12, 0),
    );

void main() {
  /// Color de fondo de la burbuja tal como queda pintada.
  Color fondo(WidgetTester tester) {
    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(MessageBubble),
            matching: find.byType(Container),
          )
          .first,
    );
    return (container.decoration as BoxDecoration).color!;
  }

  Future<void> montar(
    WidgetTester tester, {
    required ThemeData tema,
    bool isMine = true,
    String sender = 'ana@correo.com',
  }) async {
    await tester.pumpWidget(MaterialApp(
      theme: tema,
      home: Scaffold(
        body: MessageBubble(
          message: mensaje(sender: sender),
          isMine: isMine,
          showSender: true,
        ),
      ),
    ));
    // MaterialApp interpola entre temas con AnimatedTheme: justo tras el pump
    // el arbol todavia lleva el anterior, y montar dos veces en una prueba
    // leeria el color viejo.
    await tester.pumpAndSettle();
  }

  testWidgets('la burbuja propia toma el acento del tema', (tester) async {
    await montar(tester, tema: AppTheme.light);

    expect(fondo(tester), AppTheme.light.colorScheme.primaryContainer);
  });

  testWidgets('y cambia con el tema, no se queda fija', (tester) async {
    await montar(tester, tema: AppTheme.dark);

    // El color de WhatsApp estaba clavado: se veía en claro y desaparecía en
    // oscuro, que es un modo que la app toma del sistema.
    expect(fondo(tester), AppTheme.dark.colorScheme.primaryContainer);
    expect(
      AppTheme.dark.colorScheme.primaryContainer,
      isNot(AppTheme.light.colorScheme.primaryContainer),
    );
  });

  testWidgets('la ajena se distingue de la propia', (tester) async {
    await montar(tester, tema: AppTheme.light, isMine: false);

    expect(fondo(tester), isNot(AppTheme.light.colorScheme.primaryContainer));
  });

  testWidgets('el color del autor se aclara en tema oscuro', (tester) async {
    Color colorDelAutor(WidgetTester t) =>
        t.widget<Text>(find.text('ana@correo.com')).style!.color!;

    await montar(tester, tema: AppTheme.light, isMine: false);
    final claro = HSLColor.fromColor(colorDelAutor(tester)).lightness;

    await montar(tester, tema: AppTheme.dark, isMine: false);
    final oscuro = HSLColor.fromColor(colorDelAutor(tester)).lightness;

    // Un tono fijo y oscuro se lee sobre fondo claro y se pierde sobre uno
    // oscuro, así que la luminosidad la pone el tema.
    expect(oscuro, greaterThan(claro));
  });

  testWidgets('cada autor tiene su color', (tester) async {
    Color colorDe(String sender) =>
        tester.widget<Text>(find.text(sender)).style!.color!;

    await montar(tester, tema: AppTheme.light, isMine: false, sender: 'a@a.com');
    final uno = colorDe('a@a.com');

    await montar(tester, tema: AppTheme.light, isMine: false, sender: 'b@b.com');

    expect(colorDe('b@b.com'), isNot(uno));
  });
}
