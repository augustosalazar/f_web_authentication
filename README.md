# Flutter web template with Roble services

A Flutter project to test authentication and data services based on Roble following clean architecture principles.

An improved immplementation of the datasources has beeen implemented, using an unified error handling and reducing code repetition.

Now we use Flutter's snackbar implementation instead of GetX's one to help with error messaging and testing.

Add this on the AndroidManifest.xml (just bellow the manifest xmlns:android="http://schemas.android.com/apk/res/android" line)
```
<uses-permission android:name="android.permission.INTERNET" />
```

Backend server:   

```
https://roble.openlab.uninorte.edu.co/
```

To generate ICONS:
1. Copy the icon on assets/launcher_icon/
2. Run
```
flutter pub run flutter_launcher_icons:main
```

Use the .env.sample as template to include Roble´s project contract

## Running on web

Fix the port. Don't use a plain `flutter run -d chrome`:

```
flutter run -d chrome --web-port=5001
```

The SSO return destination registered in the Roble console (`ROBLE_SSO_REDIRECT`
in `.env`) points at a specific URL — `http://localhost:5001` for local
development. Without `--web-port`, Flutter picks a **different port on every
run**, so Google authenticates correctly and then sends the browser back to a
port where nothing is listening. What you see is:

```
This site can't be reached — localhost refused to connect
ERR_CONNECTION_REFUSED
```

It looks like a login failure and it isn't: the `?code=...` in that URL means
the provider did its job. That code is single-use, so retry from the login
button rather than reloading the failed URL.

Two related gotchas:

- `localhost` and `127.0.0.1` are **different origins** to the provider, even
  though they are the same machine. Open the app on whichever one is registered.
- When the app moves to a real domain, register a **second** return destination
  in the console (`mi-app-web` → `https://domain`) instead of repointing the
  local one, and switch `ROBLE_SSO_REDIRECT` per build. Otherwise deploying
  breaks local development.

Using this structure:


<img width="657" height="497" alt="image" src="https://github.com/user-attachments/assets/bb3bf21c-a2d4-4982-b6d0-a048cb1cff69" />




## Google sign-in

Two paths, picked automatically:

- **Movil**: SDK nativo (`google_sign_in`). Se abre el selector de cuentas del
  sistema, la app recibe un `id_token` y Roble lo valida. Sin navegador, sin
  esquema de URL propio y sin retorno que enrutar.
- **Web, o movil sin configurar**: el flujo de navegador de siempre, que sigue
  funcionando igual.

La decision vive en `AuthenticationSourceServiceRoble`: si hay un
`IGoogleIdTokenSource` y la plataforma lo soporta, va por el nativo. La interfaz
de usuario y el repositorio no se enteran, siguen llamando a `signInWithGoogle`.

### Configuracion

**Google se configura en la consola de Roble, no aqui.** La app pide los
proveedores a `/auth/providers` y de ahi saca el Client ID **web**, que es la
audiencia para la que Google emite el token y la que el servidor comprueba
despues. Al venir de un solo sitio, no hay dos copias que puedan separarse.

En `.env` solo queda el de iOS, que es por plataforma y Roble no guarda:

```
GOOGLE_IOS_CLIENT_ID=<client id de iOS>.apps.googleusercontent.com   # solo iOS
```

Si el proyecto no tiene Google configurado, la app cae al flujo de navegador.

### Android

1. En Google Cloud, un OAuth client de tipo **Android** con el nombre del
   paquete (`com.example.f_web_authentication`) y la huella SHA-1 de la firma.
   Para depurar:

   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```

2. No hace falta ponerlo en ningun sitio: el SDK lo resuelve por la firma del
   APK. El que Roble necesita, y el que la app recibe de `/auth/providers`, es
   el **web**.
3. `google_sign_in` 7 usa Credential Manager, que pide `minSdk` 23. El proyecto
   hereda `flutter.minSdkVersion`; si el build se queja, subelo en
   `android/app/build.gradle.kts`.

### iOS

1. Un OAuth client de tipo **iOS**, y su Client ID en `GOOGLE_IOS_CLIENT_ID`.
2. En `ios/Runner/Info.plist`, el esquema inverso como URL scheme:

   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>com.googleusercontent.apps.TU-CLIENT-ID-DE-IOS</string>
       </array>
     </dict>
   </array>
   ```

### Nonce

Cada intento genera uno nuevo, viaja a Google dentro de `initialize` y vuelve en
el token; Roble compara los dos literalmente. Es lo que impide reutilizar un
`id_token` capturado. La guia de Supabase no lo menciona para Flutter, pero el
paquete lo admite y el servidor lo valida, asi que se manda.

## Testing

### Pure widget tests

On these test we test the UI mocking the controllers.

1. add_product_page_test
2. list_product_page_test
3. login_page_test

### Widget test up to data source 

On this test we verify the UI, controllers, repositories, and the data source, but we mock the http client and shared preferences.

1. product_data_source_test

Run all tests with:

```
flutter test
```

Or run a specific test with:

```
flutter test test/path_to_test.dart
```

### Integration test

On this test we verify the entire flow of the app, from the UI to the backend, using a mock http client and shared preferences.

Run the integration test with:

```
flutter test integration_test/app_test.dart
```

or for web:

```
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d chrome
```

<p align="center">
  <img src="https://github.com/user-attachments/assets/211904b7-abc7-4cbe-8a85-6e1ff0a28654" alt="IntegrationTest" width="350"/>
</p>



