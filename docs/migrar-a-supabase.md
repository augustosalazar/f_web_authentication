# Cuánto cuesta cambiar Roble por Supabase

Medido sobre el código de hoy. La pregunta de fondo no es Supabase: es **cuánto
de esta app sabe con quién está hablando**. La respuesta sirve igual para
Firebase, para un backend propio o para lo que venga.

## El número

| | |
|---|---|
| Ficheros en `lib/` | 62 |
| Ficheros que nombran `Roble` | **16** |
| Líneas que nombran `Roble` | **72** de 4202 (**1,7 %**) |

El 98 % del código no sabe que Roble existe. Eso no es casualidad: es lo que
compra la estructura por features con interfaces en cada costura.

## Por capas

| Capa | Toca Roble | Qué pasaría al migrar |
|---|---|---|
| `ui/pages` | 0 de 10 | **nada** |
| `ui/widgets` | 0 de 2 | **nada** |
| `ui/viewmodels` | 1 de 5 | solo el de sesión, y por dos tipos |
| `domain/models` | 1 de 4 | solo una fábrica en `AuthenticationUser` |
| `domain/repositories` | 1 de 4 | solo una firma en `IAuthRepository` |
| `data/repositories` | 1 de 4 | solo una firma en `AuthRepository` |
| `data/datasources` | **4 de 4** | **se reescriben enteras** |

Las pantallas, los widgets y los repositorios de productos, chat y archivos no
se tocan. Siguen pidiendo lo mismo a las mismas interfaces.

## Qué se reescribe entero

Las cuatro fuentes y el constructor del cliente. Es exactamente donde tiene que
doler:

| Fichero | Líneas | Equivalente en Supabase |
|---|---|---|
| `authentication_source_service_roble.dart` | 98 | `supabase.auth` |
| `remote_product_roble_source.dart` | 114 | `supabase.from('productos')` (PostgREST) |
| `chat_source_roble.dart` | 75 | tabla + `supabase.channel(...)` |
| `files_source_roble.dart` | 53 | `supabase.storage.from(bucket)` |
| `core/roble_client.dart` | 69 | `Supabase.initialize(...)` |
| **Total** | **≈ 410** | |

Se escriben cuatro clases nuevas que implementan `IAuthenticationSource`,
`IProductSource`, `IChatSource` e `IFilesSource`, se registran en los
`*_dependencies.dart` en lugar de las de Roble, y el resto de la app no se
entera. Las pruebas de controlador siguen pasando sin tocar una línea, porque
hablan con las interfaces.

## Qué se retoca (no se reescribe)

Seis ficheros donde un tipo de Roble asoma por encima de la capa de datos:

| Fichero | Qué asoma | Arreglo |
|---|---|---|
| `authentication_controller.dart` | `RobleAuthState`, `RobleUser` | cambiar el tipo del flujo |
| `i_auth_repository.dart` | `RobleAuthState` | una firma |
| `auth_repository.dart` | `RobleAuthState` | una firma |
| `i_authentication_source.dart` | `RobleAuthState` | una firma |
| `authentication_user.dart` | `RobleUser` | la fábrica `fromRoble` |
| `core/error_message.dart` | `RobleApiException` | el tipo que se comprueba |

Son **9 líneas** en total. Merecen su propio apartado porque son deuda
consciente: hasta hace poco existía `AuthSession`, un modelo del dominio que
traducía el estado del paquete y dejaba `lib/features/*/domain` y `ui` sin una
sola mención a Roble. Se borró a propósito —45 líneas de traducción uno a uno
que no aportaban nada una vez el paquete devolvió el perfil ya tipado— y el
precio es este: la autenticación consume el tipo del SDK directamente, como se
hace con Supabase o Firebase.

Si algún día la migración deja de ser hipotética, ese espejo se reconstruye en
media hora y vuelve a aislar las seis.

## Lo que de verdad cuesta: dos conceptos sin equivalente directo

El trabajo mecánico son esas 410 líneas. El trabajo de pensar es otro:

**1. El árbol JSON del chat.** `db.json.read` / `push` / `watch` es una base
estilo Firebase RTDB: sin esquema, la colección nace con el primer mensaje, y
la clave que genera el servidor sirve además para ordenar. Supabase no tiene
eso. Hay que crear una tabla de verdad con su esquema, cambiar el orden por
clave a un orden por columna, y montar la suscripción con `channel` y
Postgres Changes. La interfaz `IChatSource` aguanta el cambio; la decisión de
«ordenar por clave del servidor y no por la fecha del cliente» hay que volver a
tomarla con otras herramientas —y sigue siendo la decisión correcta—.

**2. Las consultas guardadas.** `getOutOfStockProducts` ejecuta por nombre una
consulta definida en la consola de Roble. En Supabase eso es una vista o una
función RPC, que se despliegan con migraciones y no desde una consola web. Lo
mismo con `getPublicProducts`, que aquí es un endpoint `public-read` y allí es
una política RLS.

Ninguno de los dos es difícil. Los dos cambian **dónde vive la configuración**:
de una consola a un fichero de migración en el repo.

## Las pruebas

| | |
|---|---|
| Ficheros de prueba | 18 |
| Que importan Roble | **9** |

Los que se reescriben son los de fuentes —`chat_source_test`,
`out_of_stock_filter_test`, `public_catalog_test`, la parte de fuente de
`app_test`— porque comprueban el contrato del cable: a qué endpoint se pega,
qué cabeceras van, cómo se traduce lo que llega. Ese contrato cambia entero.

Los de controlador, página y modelo (`files_controller_test`,
`chat_controller_test`, `authentication_controller_test`, `login_page_test`…)
**no se tocan**: hablan con interfaces y con dobles escritos a mano. Son la red
que dice si la migración salió bien.

Los `*_dependencies_test` cambian una línea: el cliente que se les pasa.

## Resumen honesto

- **Un día de trabajo mecánico**: cuatro fuentes nuevas, el cliente, los
  registros. Guiado por interfaces que ya existen y con las pruebas de
  controlador de testigo.
- **Unos días de trabajo de diseño**: el chat sobre una tabla real, y las
  consultas guardadas como vistas o RPC con sus políticas.
- **Cero trabajo** en pantallas, widgets, navegación, caché de productos,
  manejo de errores en la interfaz y estado de los controladores.

Lo que hace que esto sea un día y no un mes es que cada feature tenga su
`IXxxSource`, que los repositorios no sepan de HTTP y que los controladores
hablen con el dominio. Si mañana se añade un módulo nuevo, la regla que
mantiene esta propiedad es una sola: **`package:roble` no sube de
`data/datasources/`** —con la excepción, consciente y documentada arriba, de la
sesión—.
