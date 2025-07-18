# Saint BI - Business Intelligence App

## 1. Descripción General

**Saint BI** es una aplicación móvil desarrollada en **Flutter** que funciona como un cliente de Business Intelligence (BI) para el sistema **SAINT Enterprise Administrativo**. La aplicación permite a los usuarios visualizar métricas y resúmenes gerenciales clave de una o varias empresas, conectándose directamente a la API de SAINT.

El objetivo principal es ofrecer una visión clara y consolidada de la salud financiera y operativa de la empresa, incluyendo ventas, compras, cuentas por cobrar, cuentas por pagar, inventario y más.

## 2. Arquitectura del Proyecto

El proyecto sigue una arquitectura por capas, limpia y escalable, fuertemente influenciada por el patrón **BLoC (Business Logic Component)** para la gestión del estado.

* **`/lib/core/bloc`**: Contiene todos los componentes de lógica de negocio (BLoC). Cada subcarpeta gestiona el estado de una característica específica, como la autenticación (`auth`), las conexiones (`connection`) o el resumen de datos (`summary`).

* **`/lib/core/data`**: Encapsula toda la lógica de acceso y manipulación de datos.
    * **`/models`**: Define las clases y estructuras de datos de la aplicación (ej: `Invoice`, `Product`).
    * **`/repositories`**: Abstraen el origen de los datos, sirviendo como intermediarios entre los BLoCs y las fuentes de datos.
    * **`/sources`**: Contiene las implementaciones para acceder a los datos, ya sea desde la API remota (`/remote`) o la base de datos local (`/local`).

* **`/lib/core/services`**: Incluye clases con lógica de negocio específica que no es gestión de estado, como `ManagementSummaryCalculator` para procesar datos brutos o `ForecastingService` para proyecciones.

* **`/lib/core/utils`**: Alberga utilidades transversales a toda la aplicación, como formateadores (`formatters.dart`), constantes (`constants.dart`) y servicios de seguridad (`security_service.dart`).

* **`/lib/ui/pages`**: Contiene los widgets que representan las pantallas completas de la aplicación, como la pantalla de login, la de configuración o la del resumen gerencial.

* **`/lib/ui/widgets`**: Almacena widgets reutilizables. Se divide en `common` (widgets genéricos) y `feature_specific` (widgets diseñados para una característica concreta).

* **`/lib/ui/theme`**: Define la apariencia visual de la aplicación, incluyendo la paleta de colores (`app_colors.dart`) y la configuración del tema global (`app_theme.dart`).

* **`/lib/app.dart`**: Es el widget raíz de la aplicación. Aquí se configuran los proveedores de BLoCs y repositorios para la inyección de dependencias en todo el proyecto.

* **`/lib/main.dart`**: Es el punto de entrada principal de la aplicación. Su función es inicializar los servicios necesarios (como el formateo de fechas) y ejecutar `App`.

## 3. Herramientas y Versiones

Este proyecto se construye sobre las siguientes tecnologías:

* **Lenguaje:** Dart (`~3.x`)
* **Framework:** Flutter (`~3.x`)
* **Gestión de Estado:** `flutter_bloc`
* **Conectividad HTTP:** `http`
* **Base de Datos Local:** `sqflite`
* **Gráficos:** `fl_chart`
* **Información del Paquete:** `package_info_plus`
* **Formateo de Fechas/Números:** `intl`

Se recomienda utilizar siempre las últimas versiones estables de Flutter y las dependencias mencionadas en el `pubspec.yaml`.

## 4. Flujo de Datos y Componentes Clave

### 4.1. Conexión y Autenticación

1.  **Configuración Inicial (`InitialSetupScreen`):** La primera vez que se abre la app, se solicita al usuario una contraseña de administrador para la app y el nombre de usuario por defecto para la API de SAINT. Estos datos se guardan de forma segura en la base de datos local.
2.  **Gestión de Conexiones (`ConnectionSettingsScreen`):** El usuario puede añadir, editar o eliminar múltiples configuraciones de conexión a diferentes instancias de SAINT Enterprise. Cada `ApiConnection` se almacena localmente usando `sqflite` a través del `ConnectionRepository`.
3.  **Inicio de Sesión (`LoginScreen`):**
    * El `ConnectionBloc` carga las conexiones disponibles. El usuario selecciona una.
    * Al pulsar "Ingresar", se dispara un evento `AuthLoginRequested` al `AuthBloc`.
    * El `AuthBloc` utiliza el `AuthRepository` para llamar al endpoint `/login` de la `SaintApi`.
    * Si el login es exitoso, la API devuelve un `authToken` (`Pragma`) que se almacena en el `AuthState`.
    * La app navega a la pantalla de resumen (`ManagementSummaryScreen`).
4.  **Modo Consolidado:** El usuario tiene la opción de autenticarse en *todas* las conexiones configuradas simultáneamente para ver un resumen consolidado de todas las empresas.

### 4.2. Resumen Gerencial

1.  **Carga de Datos (`SummaryBloc`):**
    * Al entrar en `ManagementSummaryScreen`, se dispara un evento `SummaryDataFetched`.
    * El `SummaryBloc` comprueba el estado de autenticación (`AuthBloc`).
    * Utiliza el `SummaryRepository` para realizar múltiples llamadas a la API (`getInvoices`, `getProducts`, etc.) usando el `authToken` activo.
    * Los datos se pueden filtrar por un rango de fechas.
2.  **Cálculo de Métricas (`ManagementSummaryCalculator`):**
    * Una vez que el `SummaryRepository` devuelve todos los datos brutos (`SummaryData`), estos se pasan al `ManagementSummaryCalculator`.
    * Este servicio es el cerebro del sistema: procesa las listas de facturas, productos, cuentas por cobrar, etc., para calcular las métricas finales del `ManagementSummary` (ej: utilidad bruta, ventas netas, impuestos).
3.  **Visualización en la UI:**
    * El `SummaryBloc` emite un nuevo `SummaryState` con el resumen calculado.
    * La `ManagementSummaryScreen` se reconstruye y muestra los datos formateados.
    * El usuario puede navegar a vistas de detalle para explorar las listas de facturas, cuentas por cobrar, etc.

### 4.3. Proyección de Ventas

* La pantalla **`SalesForecastScreen`** utiliza los datos históricos de ventas (`allInvoices` del `SummaryState`) para generar una proyección.
* El **`ForecastingService`** implementa un algoritmo de **Suavización Exponencial Simple (SES)** para predecir las ventas futuras.
* El usuario puede ajustar parámetros como la **granularidad** (diaria, semanal, mensual), el **número de periodos a proyectar** y el **factor de suavización (alfa)** para refinar el modelo.
* Los resultados se visualizan en un gráfico interactivo usando `fl_chart`, diferenciando entre datos históricos y datos proyectados.

## 5. Configuración y Primeros Pasos

Para que un nuevo desarrollador pueda ejecutar el proyecto, debe seguir estos pasos:

1.  **Clonar el Repositorio:**
    ```bash
    git clone <url-del-repositorio>
    cd <nombre-del-proyecto>
    ```
2.  **Instalar Dependencias:**
    ```bash
    flutter pub get
    ```
3.  **Configurar el Entorno de Flutter:** Asegurarse de tener el SDK de Flutter instalado y configurado correctamente.
4.  **Ejecutar la Aplicación:**
    ```bash
    flutter run
    ```
5.  **Primera Ejecución:**
    * La app mostrará la pantalla de configuración inicial.
    * Deberás ingresar un **Usuario API** válido (ej: `SA`) y una **contraseña de administrador** para la aplicación. Esta contraseña se usará para proteger el acceso a la pantalla de configuración de conexiones.
    * Luego, serás redirigido para añadir tu primera conexión a un servidor SAINT Enterprise.

## 6. Puntos a Considerar para Futuros Desarrolladores

* **Manejo de Errores:** La comunicación con la API se gestiona con excepciones personalizadas como `AuthenticationException` y `SessionExpiredException`, que permiten al `SummaryBloc` y `AuthBloc` reaccionar adecuadamente (ej: redirigir al login si la sesión expira).
* **Inmutabilidad:** Los modelos de datos y los estados de los BLoCs son inmutables. Se utilizan métodos `copyWith` para generar nuevas instancias de estado, lo que es una práctica recomendada en la programación funcional y con BLoC.
* **Seguridad:** Las contraseñas (la de administrador de la app y las de las conexiones) se gestionan con cuidado. La contraseña de administrador se hashea usando `sha256` antes de guardarse.
* **Localización:** La app está preparada para ser localizada. Utiliza `intl` para formatear fechas y números según la configuración regional del dispositivo. Se han incluido una gran cantidad de `locales` soportados en la configuración de `MaterialApp`.