# **SAINT BI: Plan de Desarrollo**

## **1. Pendientes**

### **1.1. Modelos Estadísticos**

* [X] **Análisis de Canasta de Mercado:**
    * [X] Crear `MarketBasketService` para implementar el algoritmo Apriori o FP-Growth sobre los ítems de las facturas.
    * [X] Crear la pantalla `market_basket_screen.dart` para visualizar las reglas de asociación de productos.

* [X] **Unificacion de los modelos de proyeccion de ventas:**
    * [X] Sobreponer el grafico de las proyecciones de ventas por minimo cuadrado y suavizacion exponencial. De manera que sea un solo grafico de proyecciones.

### **1.2. Indicadores de Gestión (KPIs)**

* [X] **Márgenes de Utilidad:** Calcular y mostrar los márgenes de utilidad bruta y neta en el resumen gerencial.
* [X] **Ticket Promedio:** Calcular y mostrar el valor promedio por factura de venta.
* [X] **Rotación y Días de Inventario:** Calcular y mostrar ambos KPIs en una nueva sección de inventario.
* [X] **Días de Cuentas por Cobrar (DSO):** Calcular y mostrar este indicador en una nueva sección de cobranza.
* [X] **Cambiar el slider de los KPI's principales de horizontal a vertical.**

### **1.3. Funcionalidades de la Aplicación**

* [] **Consolidación Selectiva:**
    * [] Añadir la opción `includeInConsolidation` a la tabla y modelo de `ApiConnection`.
    * [] Agregar un `Switch` en la pantalla de configuración para activar o desactivar cada empresa del consolidado.
    * [] Modificar el `SummaryBloc` para que solo consolide las conexiones marcadas.
* [] **Popup explicativo de cada aspecto de la aplicacion:**
    * [] Agregar un pequeño boton en cada en forma de '(i)' donde al presionarlo se muestre un pequeña explicacion de cada KPI, grafico y modelo estadistico.

---

## **2. Versiones**

### **Version 1.2.0**
* Agregada funcionalidad de comparacion de periodos. Al seleccionar un numero de dias en el filtro de fechas, se calcula automaticamente el mismo numero de dias del periodo anterior y se coloca el porcentaje de diferencia en cada uno de las variables calculadas.
* Agregado grafico de dona donde se comparan las ventas a credito y a contado.

### **Versión 1.1.0**
* Agregada la posibilidad de consultar el resumen gerencial consolidado, sumando los datos de todas las conexiones configuradas.

---

## **3. Descripción General**

**Saint BI** es una aplicación móvil en **Flutter** para Business Intelligence (BI) del sistema **SAINT Enterprise Administrativo**. Permite visualizar métricas gerenciales de una o varias empresas a través de la API de SAINT, ofreciendo una visión consolidada de la salud financiera y operativa del negocio.

---

## **4. Arquitectura**

El proyecto usa una arquitectura por capas limpia basada en el patrón **BLoC**.

* `/lib/core/bloc`: Lógica de negocio y gestión de estado (Auth, Connection, Summary).
* `/lib/core/data`: Acceso a datos (`models`, `repositories`, `sources`).
* `/lib/core/services`: Lógica de negocio específica (cálculos, proyecciones).
* `/lib/core/utils`: Utilidades transversales (constantes, formateadores, seguridad).
* `/lib/ui`: Capa de presentación (`pages`, `widgets`, `theme`).
* `/lib/app.dart`: Widget raíz con inyección de dependencias (BLoCs y repositorios).
* `/lib/main.dart`: Punto de entrada de la aplicación.

---

## **5. Stack Tecnológico**

* **Lenguaje:** Dart (`3.8.1`)
* **Framework:** Flutter (`3.32.3`)
* **Gestión de Estado:** `flutter_bloc`
* **Base de Datos Local:** `sqflite`
* **Gráficos:** `fl_chart`
* **Dependencias Clave:** `http`, `intl`, `package_info_plus`

---

## **6. Flujo de Datos**

### **6.1. Conexión y Autenticación**

1.  **Configuración Inicial:** Al primer uso, la app solicita una contraseña de administrador y un usuario API por defecto, que se guardan localmente.
2.  **Gestión de Conexiones:** El usuario puede administrar múltiples conexiones a servidores SAINT, que se almacenan en `sqflite`.
3.  **Inicio de Sesión:** El usuario selecciona una conexión y el `AuthBloc` obtiene un `authToken` (`Pragma`) de la `SaintApi`, que se guarda en el estado.
4.  **Modo Consolidado:** Permite autenticarse en todas las conexiones activas para ver un resumen combinado.

### **6.2. Resumen Gerencial**

1.  **Carga de Datos:** El `SummaryBloc` utiliza el `authToken` para obtener los datos brutos de la API a través del `SummaryRepository`.
2.  **Cálculo de Métricas:** El `ManagementSummaryCalculator` procesa los datos para generar las métricas del resumen gerencial.
3.  **Visualización:** La `ManagementSummaryScreen` recibe el estado del BLoC y muestra los KPIs calculados.

---

## **7. Guía de Inicio Rápido**

1.  **Clonar Repositorio:**
    ```bash
    git clone <url-del-repositorio>
    cd <nombre-del-proyecto>
    ```
2.  **Instalar Dependencias:**
    ```bash
    flutter pub get
    ```
3.  **Ejecutar la App:**
    ```bash
    flutter run
    ```
4.  **Configuración Inicial:** En la primera ejecución, sigue las instrucciones para configurar el usuario API y la contraseña de administrador. Luego, añade tu primera conexión al servidor SAINT Enterprise.