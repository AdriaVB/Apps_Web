# Balance Mensual — versión Web

**Esto es una copia independiente**, creada a partir de `Apps_GooglePlay/AppGastos` (la app Android original, que sigue viva y sin tocar en su propio repo privado). Vive aquí, en el repo público `Apps_Web`, para poder publicarla con GitHub Pages y que cualquiera con el enlace la use en su propio navegador (incluido iPhone, vía Safari → "Añadir a pantalla de inicio") — cada persona con sus propios datos, guardados solo en su navegador, sin servidor ni cuenta.

**Diferencias respecto a la app Android** (el resto de este documento describe la lógica compartida, que es la misma en las dos):
- **Base de datos**: `sqflite` (nativo) no existe en un navegador. Se sustituye por `sqflite_common_ffi_web` — SQLite compilado a WebAssembly, guardando en IndexedDB — activado en `main.dart` con `if (kIsWeb) databaseFactory = databaseFactoryFfiWeb;`. Necesita los binarios instalados una vez con `dart run sqflite_common_ffi_web:setup` (genera `web/sqlite3.wasm` y `web/sqflite_sw.js`, que si se necesitan regenerar tras un cambio de versión del paquete es con `--force`).
- **Sin `dart:io`**: cualquier archivo que lo importe rompe la compilación a web. `AppDatabase.paraPruebas()` (solo usado en tests) aísla su uso con import condicional (`ruta_temporal_pruebas_io.dart` / `_stub.dart`, según `dart.library.io`). `exportar_csv.dart` se reescribió para generar el CSV en memoria (`XFile.fromData`) en vez de escribir a un archivo real.
- **Sin widget de Android ni Auto Backup**: no existen en web. Se ha eliminado `home_widget` de las dependencias y `lib/utils/widget_inicio.dart` directamente (no solo desactivado) — si algún día hace falta un backup manual para esta versión, la exportación a CSV ya existente sirve como base.
- **Renderer**: `web/flutter_bootstrap.js` fija `canvasKitBaseUrl: "canvaskit/"` (copia local del SDK) en vez de la CDN de Google — mismo motivo y mismo patrón que en CheckList (ver `Apps_Web/CLAUDE.md`).
- **Publicación**: `flutter build web --base-href /Apps_Web/balance/`, copiado a `Apps_Web/docs/balance/`.

Cualquier mejora de la lógica de negocio (nuevas funciones, cambios de cálculo...) que se haga aquí **no se aplica sola** a la versión Android, y viceversa — son dos copias de código independientes desde el momento de la separación, no un mismo proyecto con dos builds.

---

App Flutter de seguimiento manual de ingresos y gastos mensuales. Sin conexión bancaria: el usuario registra todo a mano. Plataforma objetivo: Android (principal), Web (opcional). No se ha hecho `flutter create` todavía — este documento es el resultado de la fase de diseño de producto, antes de escribir código.

Estudio completo con comparativa de apps existentes, razonamiento y diagrama de bloques: [Balance Mensual (Artifact)](https://claude.ai/code/artifact/355b8f0e-0f7c-426f-9eaa-6aa0b1e727f7). Este archivo es el resumen de referencia rápida que se actualiza conforme avanza el proyecto — el Artifact es el histórico narrado, este `CLAUDE.md` es el estado actual de las decisiones.

## Entorno de desarrollo (ya instalado)

- Flutter 3.47.0 stable en `C:\flutter` (en el PATH del usuario)
- Android SDK en `C:\Android\Sdk` (platform-tools, android-35, android-36, build-tools 28.0.3 y 35.0.0, licencias aceptadas)
- Visual Studio (necesario solo para build nativo de Windows desktop) — **no instalado**, fuera de alcance salvo que se pida explícitamente

## Concepto central

- Dos formas de registrar dinero: **gastos/ingresos fijos** (plantillas recurrentes con periodicidad propia — mensual, trimestral, anual...— se configuran una vez) y **movimientos variables** (puntuales, se añaden cada vez que ocurren).
- Pantalla principal: mes y día actual (según el ciclo configurado), historial de burbujas (mensual y anual), botón **+** flotante.
- Configuración (engranaje): ciclo de mes, gastos/ingresos fijos, categorías.

## Ciclo de mes

- El usuario elige el **día de inicio de su mes** (1 = mes natural; p. ej. 25 = ciclo de nómina). Es un único número (offset sobre el calendario).
- **Bug encontrado en pruebas manuales (y corregido):** la primera implementación recalculaba el ciclo actual desde cero cada vez (hoy + día configurado), sin memoria de cuándo había empezado de verdad el ciclo ya abierto. Cambiar el día a mitad de mes generaba al instante una clave de ciclo nueva, dejando el resto del mes en curso como un mini-ciclo huérfano — visible como burbujas duplicadas "ago 2026" en el Historial con balances distintos. Reproducido cambiando el día 3 veces seguidas.
- **Solución implementada:** `ConfiguracionUsuario` guarda un cambio en cola (`diaInicioMesPendiente` + `fechaAplicacionPendiente`), calculado con `fechaTransicionCiclo` (`lib/utils/ciclo_mes.dart`) — **la próxima vez que llegue el nuevo día, este mes o el que viene, lo que toque antes**. `AppDatabase.obtenerConfiguracion()` resuelve el cambio en cola solo cuando le toca, así el ciclo ya abierto nunca se ve alterado a media. `CicloMesScreen` pide confirmación explicando la fecha exacta de transición antes de guardar, y muestra el cambio en cola (con opción de cancelarlo) si ya hay uno.

## Gastos/Ingresos fijos (con periodicidad)

**Decisión revisada:** originalmente "gastos fijos" (siempre mensuales) y "gastos anuales" eran dos conceptos separados en la app. Se fusionaron en uno solo tras notar que son la misma idea — "un movimiento que se repite y no hay que dar de alta cada vez" — solo que con distinta periodicidad, y que hay gastos reales que no son ni mensuales ni anuales (seguros trimestrales, cuotas cuatrimestrales...). Ya no existe una pantalla ni un modelo separado para "gastos anuales".

**Segunda decisión revisada:** el mismo concepto se extendió para cubrir también **ingresos fijos** (nómina, alquiler cobrado...), no solo gastos — es la misma mecánica (plantilla recurrente con periodicidad) con el signo cambiado. Una única pantalla "Gastos/Ingresos fijos" cubre ambos, con un interruptor Gasto/Ingreso en el formulario (mismo componente `ToggleTipo` que ya usaba el alta de movimientos variables).

- Se crean y editan **solo desde Configuración** (nunca desde el botón +), en una única pantalla "Gastos/Ingresos fijos". **Bug encontrado en pruebas manuales (y corregido):** tocar "editar" sobre un movimiento fijo desde el detalle de un mes abría el formulario de ese movimiento suelto, no la plantilla — contradecía esta misma decisión, y el cambio se "perdía" al mes siguiente. `DetalleCicloScreen._editar` ahora redirige a `GastoFijoFormScreen` con la plantilla cuando el movimiento es de origen fijo (con fallback al formulario suelto si la plantilla ya se borró).
- **Mismo criterio aplicado también al borrado (hecho):** tocar "borrar" sobre un movimiento fijo desde el detalle de un mes ya no lo borra suelto ahí — muestra un aviso explicando que los fijos solo se borran desde "Gastos/Ingresos fijos", con un botón directo a esa pantalla (con fallback al borrado suelto si la plantilla ya no existe). Para que esto no dejara un fijo ya generado sin ninguna forma de borrarse, `borrarGastoFijo` ahora también quita el movimiento ya generado en el ciclo actual (nunca de meses ya cerrados, mismo criterio que `sincronizarGastoFijoEnCicloActual`).
- Cada uno tiene: nombre, **tipo (gasto/ingreso)**, importe (el importe de cada pago completo), y **periodicidad**: mensual (por defecto), trimestral, cuatrimestral, semestral o anual — presets fijos, no un número libre, igual que el resto de decisiones de la app (simplicidad deliberada sobre flexibilidad total). La categoría **solo se pide si es un gasto** — un ingreso fijo no la necesita, igual que ya pasaba con los ingresos variables del botón +.
- Si la periodicidad no es mensual, lleva además: **mes del próximo/primer pago del año** y un toggle **repartir en esos meses** (prorratear para que la vista mensual no se dispare el mes de pago) o **golpear el importe completo en cada mes de pago**. A elección del usuario, por gasto/ingreso. Los meses de pago siguientes se derivan solos (mes de pago + periodicidad, repetido).
- Si es mensual, se aplica automáticamente cada mes con el **último importe conocido** — sin preguntar activamente cada mes si sigue siendo correcto (se descartó esa opción por generar fricción sin aportar valor).
- **Cualquier mes pasado es editable**: si al usuario se le pasó actualizar el importe (p. ej. subida de renta), corrige el mes concreto donde se aplicó mal.
- Ejemplo aclarado: la hipoteca es fija de importe constante (casi nunca se toca); la luz y el agua son fijas de importe variable (se ajustan cuando llega el recibo real, pero nunca hay que acordarse de darlas de alta cada mes — eso es lo que las hace "fijas", no el importe). El IBI o un seguro anual son el mismo concepto con periodicidad anual. La nómina es el mismo concepto con `tipo: ingreso`.
- **Luz y agua se confirmaron explícitamente como gastos fijos** (no variables) tras evaluar la alternativa de convertirlas en variables con recordatorio — se descartó por añadir complejidad sin necesidad, y porque el modelo de importe heredado + histórico editable ya cubre el caso de uso.

## Categorías

**Tres catálogos separados** (decisión revisada tras probar la UI — ver nota abajo):

- **Recurrentes** (gastos fijos): `luz · agua · alquiler · hipoteca · seguros · impuestos · otros`
- **Variables** (gastos puntuales del botón +): `comida · restaurantes · ocio · gasolina · gastos coche · gastos casa · salud/higiene · otros`
- **Ingreso** (cualquier ingreso, fijo o variable): `nómina · autónomo/freelance · bizum · alquiler cobrado · ventas · reembolsos/devoluciones · ayudas/pensión · otros`

- ~~La categoría como campo universal compartido~~ — **decisión revertida**. Se diseñó así al principio para poder sumar gasto por categoría viniera de donde viniera, pero en la práctica no tenía sentido: un gasto fijo (luz, hipoteca...) nunca se registra como movimiento variable, así que esa lista compartida solo mostraba categorías de "día a día" (comida, ocio...) al crear un gasto fijo, y viceversa. Cada catálogo se filtra por su propio contexto (`tipo: recurrente | variable | ingreso` en la tabla `categoria`).
- `impuestos` se añadió al catálogo recurrente porque IBI e impuesto de circulación (los ejemplos que usamos para gastos anuales) no encajaban en ninguna categoría existente.
- **Catálogo de ingreso añadido** tras notar que los ingresos (fijos y variables) tenían un nombre libre pero ninguna categoría — no se podía distinguir "de dónde viene el dinero" (nómina vs. Bizum vs. venta...) ni filtrar por ello. Un único catálogo para ambos (fijo y variable) porque el origen del dinero no depende de si el ingreso se repite o no. Investigado brevemente (fuentes de ingreso más comunes en apps de finanzas personales + contexto español, donde Bizum es un canal habitual): nómina, autónomo/freelance, bizum, alquiler cobrado, ventas, reembolsos/devoluciones, ayudas/pensión, otros. Antes de este cambio, el campo Categoría se ocultaba por completo al elegir Ingreso; ahora se muestra siempre, con el catálogo que corresponda al tipo.

## Movimientos variables (botón +)

- Siempre variables — los fijos nunca se crean aquí.
- Se abre siempre en modo **Gasto** por defecto, con un **interruptor visible e interactivo** para pasar a Ingreso (y volver) sin cerrar el formulario.
- Campos: tipo (gasto/ingreso), nombre descriptivo, importe, categoría.

## Edición y borrado (requisito explícito)

**Todos los ingresos y gastos —fijos (de cualquier periodicidad) y variables— deben poder editarse y también borrarse.** No es solo "corregir el importe": el usuario tiene que poder eliminar cualquier movimiento o plantilla por completo cuando ya no aplique.

## Cierre de mes y de año

- Balance del mes = ingresos − (fijos según su periodicidad e importe correspondiente al mes + variables del mes).
- Burbuja de mes: verde si el balance es positivo, roja si es negativo.
- Burbuja de año: suma de las 12 burbujas de mes, mismo código de color. Se genera al cerrarse el último ciclo del año. Al tocarla, despliega los 12 meses.

## Almacenamiento de datos

**100% local en el dispositivo** — sin servidor externo, sin cuenta de usuario, sin sincronización. Base de datos local tipo SQLite (paquete `sqflite` o `drift`), coherente con el modelo relacional de la Fase 0 (Movimiento, GastoFijo, Categoría tienen relaciones entre sí). Si se desinstala la app o se cambia de móvil, los datos se pierden salvo que exista una copia de seguridad manual (ver Backlog).

## Fuera de alcance para v1

Conexión bancaria · presupuestos/límites de gasto · multi-cuenta · multi-divisa · sincronización en la nube · multi-usuario.

## Diferenciación frente a la competencia

✅ Investigación completada (solo research, sin cambios de código): [Radar Competitivo (Artifact)](https://claude.ai/code/artifact/9fb84db0-d97e-4a43-9bbe-af2a4e167b24) — 15 apps revisadas (Goodbudget, YNAB, Spendee, Money Lover, Wallet, Toshl, Fintonic, EasyBudget, Monefy, Dinerio, Kakebo AI, Money Manager RealByte y otras), tabla comparativa de features y brainstorm de ideas nuevas.

**Conclusión confirmada:** ninguna de las apps revisadas combina las tres piezas que definen Balance Mensual — gasto fijo con importe heredado + gasto anual con prorrateo opcional + ciclo de mes personalizable, todo sin cuenta ni nube. EasyBudget es la más cercana en filosofía (sin banco, ciclo de mes personalizable) pero sin fijos/anuales con herencia de importe. Spendee y Wallet detectan gastos fijos automáticamente por patrón, no por plantilla que el usuario da de alta — es una aproximación distinta, no la misma feature.

**Carencia confirmada y aceptada a propósito:** presupuestos con alerta de límite de gasto y multi-divisa/multi-cuenta son universales en la competencia y ausentes aquí — coherente con "Fuera de alcance para v1" mientras la razón siga siendo simplicidad deliberada y no que "no se nos ha ocurrido".

Las ideas concretas que salieron de ese brainstorm están incorporadas al Backlog de abajo, todas marcadas como pendientes — de este ejercicio no ha salido ningún cambio de código, solo dirección de producto.

Segunda entrega, tras construir donuts/ingresos/comparación de años/Recordatorios/Auto Backup/widget: [Radar Competitivo II (Artifact)](https://claude.ai/code/artifact/e3123052-9ad9-4d41-beb0-a865f6f09897) — qué huecos de la competencia ya hemos cerrado, cuáles se han movido (el ciclo de mes personalizable ya no es exclusivo nuestro; "sin cuenta/nube" ha pasado de carencia a discurso de mercado reconocido), qué funciones de pago tiene la competencia, y 5 candidatas a función de pago que encajan con la filosofía (proyección de fin de mes, exportar CSV/PDF, meta de ahorro tipo hucha, indicador de salud financiera, progreso de categoría frente a la propia media).

## Monetización

**Decisión: suscripción, no pago único** (revierte lo que decía el cierre del Radar Competitivo II, escrito antes de esta conversación — el artifact tiene la frase vieja, esta nota manda).

**Por qué:** el plan es crecer a iPhone si a la app le va bien, y Apple cobra 99$/año de forma recurrente (frente a los 25$ de Google, que son de una sola vez). Un pago único no genera un ingreso que se renueve para cubrir ese coste fijo — cada año haría falta vender la app a gente *nueva* solo para no perder dinero con la cuota de Apple. Una suscripción, aunque sea barata (p. ej. ~1€/mes), cubre ese coste con los usuarios que ya se tienen, sin depender de crecimiento constante. Cálculo de referencia: a 4,99€ de pago único harían falta ~25-30 ventas nuevas cada año solo para cubrir los 99$ de Apple; a 1€/mes de suscripción, bastan ~9-10 suscriptores que se queden.

**Matiz:** este razonamiento depende de publicar en iOS. Si el plan se quedara solo en Android (25$ de Google, sin coste recurrente), el argumento a favor de la suscripción pierde fuerza — pero la decisión ya está tomada pensando en el crecimiento a Apple.

**Qué se decidió NO hacer**: vincular cuentas propias + nube propia para "no perder datos al cambiar de móvil" — se rechazó explícitamente por romper "sin cuenta, sin servidor" (ver Fase 13, Auto Backup, la alternativa que sí se implementó).

**Pendiente de decidir más adelante**: precio exacto de la suscripción y qué queda gratis vs. de pago. **Decisión de proceso**: se construyen las 5 candidatas de abajo enteras y usables primero, sin muro de pago — la comprobación de "¿eres Pro?" es barata de añadir al final sobre una función ya terminada, y de todos modos no se puede probar un cobro real hasta tener la cuenta de Google Play Console. Decidir qué es de pago con la app ya delante y usada de verdad es mejor que adivinarlo ahora.

**Las 5 candidatas del Radar Competitivo II, con el porqué de cada una y en el orden en que tiene más sentido construirlas:**

1. ✅ **Proyección de fin de mes** (fin de año queda para otra pasada) — "si sigues así, terminas el mes con X€", en Inicio junto al balance del mes. Extrapola el ritmo de gasto/ingreso variable de lo que llevas de ciclo al resto de días (los fijos ya están completos en el balance desde el día 1, gracias al motor de cierre). Sin modelo de datos nuevo.
2. ✅ **Exportación a CSV** (solo CSV, sin PDF por ahora) — un mes concreto o el año entero, vía el menú de compartir de Android (`share_plus`), sin muro de pago todavía. Genera un archivo local con lo que ya hay en la base de datos, sin servidor. Refuerza "tus datos son tuyos" como argumento de venta. Beneficio extra: reutilizable como base técnica si más adelante se retoma "Compartir cuentas sin nube" (ver Backlog) — no es solo para monetizar.
3. ✅ **Progreso de categoría frente a tu propia media** — en el desglose por categoría que ya existe (`DesgloseCategoriaScreen`), cada categoría con al menos otro ciclo con el que comparar muestra "un X% por encima/debajo de tu media (Y €)", y si es su máximo del año, "Récord del año". Sin configuración nueva (nada de límites ni alertas manuales), sin tabla nueva — se calcula al vuelo con los movimientos ya guardados.
4. ✅ **Metas de ahorro a largo plazo** (revisado en la implementación — ver más abajo): objetivo + plazo, puramente informativo. Configuración → "Metas de ahorro" (CRUD, varias a la vez) y resumen pasivo en Inicio.
5. ✅ **Indicador de salud financiera** — titular en Inicio tipo "Salud financiera: Saludable — ahorras de media un 15% de lo que ingresas". Se descartó "meses de gastos fijos cubiertos" porque la app no rastrea un saldo bancario real, solo flujos por ciclo — inventar un "total ahorrado" sumando balances históricos habría sido justo el tipo de cifra arbitraria que queríamos evitar. La tasa de ahorro (ahorro medio ÷ ingreso medio de los ciclos ya cerrados, sin contar el actual) sí es 100% dato real de la app, y los umbrales (Excelente ≥20%, Saludable 10-20%, Ajustada 0-10%, Alerta <0%) son la regla del 20% de ahorro ya conocida en asesoría financiera, no algo inventado para la app.

## Publicar la app (investigado, nada hecho todavía)

- **Google Play**: cuenta de desarrollador 25$ **de una sola vez** (no anual). Para cuentas personales nuevas (creadas después del 13 nov 2023), Google exige una prueba cerrada con **mínimo 12 testers activos durante 14 días seguidos** antes de dar acceso a producción. Compilar como `.aab` firmado (no el `.apk` de debug que usamos para el emulador). Hace falta política de privacidad y rellenar el formulario de "seguridad de los datos" — en nuestro caso debería ser un "no recogemos nada" limpio, coherente con la marca.
- **Apple App Store**: cuenta de desarrollador **99$/año** (recurrente). Necesita 2FA en el Apple ID. **Bloqueante actual: hace falta un Mac con Xcode** — no se puede compilar ni probar nada de iOS desde este equipo con Windows. Alternativas si no hay Mac propio: pedir uno prestado (con Apple ID gratis se puede instalar en un iPhone conectado por USB, pero caduca a los 7 días) o un servicio de compilación en la nube tipo Codemagic (tiene nivel gratuito) combinado con la cuenta de pago de Apple para distribuir por TestFlight (sin cable, sin depender de tener el Mac cerca, cada build dura 90 días).
- **Para probarla ya con un par de personas sin pasar por ninguna tienda**: en Android, compilar un `.apk` release firmado y mandarlo directamente (WhatsApp, Drive...) — gratis, inmediato, sin cuenta de desarrollador, pero sin actualizaciones automáticas. En iPhone no hay equivalente — Apple no permite instalar apps sueltas así.

## Backlog — ideas para más adelante (no v1, no olvidar)

Priorizado de menos a más esfuerzo, según el Radar Competitivo. Lo marcado ✅ ya está implementado (ver Fase 10/11/12/13/14 en "Plan de acción" para el detalle); el resto sigue **pendiente**:

- ✅ **Comparativa año contra año** — hecho, y ampliado: no solo "este ciclo vs. el mismo ciclo el año pasado", sino comparar dos años cualesquiera (`ComparativaAniosScreen`, botón "Comparar" en el detalle de año).
- ✅ **Vista "próximos pagos"** — hecha y ampliada como sección "Recordatorios" en Configuración: aviso pasivo (sin notificaciones) de qué toca pagar/cobrar este mes y cuándo, más un calendario de los 12 meses. Cubre también ingresos fijos, no solo gastos no mensuales.
- ✅ **Copia de seguridad** — hecha, pero de forma distinta a la descrita originalmente: no exportar/importar manual, sino Auto Backup de Android (ver Fase 13). Se planteó también vincular cuentas + nube propia y se rechazó explícitamente por romper "sin cuenta, sin servidor". Sigue sin existir un archivo exportable que el usuario pueda mandarse él mismo (Drive, email...) — si algún día hace falta eso en concreto, es trabajo aparte.
- ⏳ **Compartir cuentas sin nube** (nueva, del Radar Competitivo): exportar/importar manualmente el histórico de un ciclo (WhatsApp, email...) para llevar cuentas en pareja sin sincronización automática ni servidor. Cubre el hueco de "multi-usuario" sin romper "sin cuenta, sin nube" — **ya no puede reutilizar el formato de la copia de seguridad** (Auto Backup no genera ningún archivo manejable por la app); necesitaría su propio formato de exportación si se hace.
- ✅ **Resumen al cerrar el ciclo** — hecho, con un enfoque distinto al descrito originalmente: en vez de una pantalla tipo "recibo" que solo aparece al cerrar el mes, son dos donuts de ingresos/gastos por categoría disponibles en el detalle de **cualquier** mes o año (`GraficoDonut`, `DesgloseCategoriaScreen`).
- ⏳ **Aviso discreto y no bloqueante para gastos fijos estancados**: algo tipo "este importe lleva igual 6 meses" — solo tiene sentido evaluarlo una vez haya uso real de la app que lo justifique. No implementar ahora.
- ✅ **Widget de Android** — hecho (ver Fase 14): balance del ciclo actual (coloreado) y los próximos pagos/cobros más cercanos, en la pantalla de inicio del móvil. Primera dependencia externa del proyecto (`home_widget`). El donut de categorías se dejó fuera a propósito (no encaja bien en el sistema de vistas limitado de los widgets de Android).
- ⏳ **Cápsula del año** (nueva, del Radar Competitivo): captura visual exportable (imagen) del histórico de burbujas de un año ya cerrado, para archivar o compartir.
- ⏳ Reconsiderar el manejo del ciclo de mes si en el futuro se necesita algo más fino que "aplica desde el próximo cierre" (por ahora es suficiente).
- ⏳ Categorías adicionales si el uso real lo pide (ropa, regalos, mascotas...) — no bloquea nada añadirlas después.
- ⏳ **Pantalla de información sobre el Auto Backup en Configuración**: un botón/apartado que explique paso a paso cómo funciona la copia de seguridad de Android para esta app — con capturas de pantalla de dónde está el ajuste ("Copia de seguridad" en Ajustes del sistema, no dentro de la app) y qué significa cada opción (Back up my data, Backup account, Automatic restore). Objetivo: que el usuario entienda y confíe en que sus datos sobreviven a un cambio de móvil sin tener que preguntarlo. Surgió al verificar Auto Backup a mano (desinstalar + reinstalar con el transporte local de depuración) durante las pruebas manuales.

## Datos de prueba en el emulador: años 2024 y 2025

Para poder probar la comparación entre años (Fase 11) y Recordatorios sin esperar a que pasara un año de verdad, se sembraron a mano 168 movimientos variables repartidos en los 12 meses de 2024 y de 2025, directamente en la base de datos del emulador (no vía la UI de la app).

**Cómo se hizo:** `adb shell run-as com.avbrisa.balance_mensual sqlite3 app_flutter/balance_mensual.db "INSERT INTO movimiento (...) VALUES (...);"` — inserciones directas en la tabla `movimiento`, sin pasar por `AppDatabase` ni por ningún `GastoFijo`.

**Cómo quitarlos cuando ya no interese tenerlos** (confirmado: los 168 son `origen = 'variable'` y `gastoFijoId` es NULL en todos — no hay ninguna plantilla `GastoFijo` de por medio, así que basta con borrar de `movimiento`, no hace falta tocar `gasto_fijo`):

```
adb shell run-as com.avbrisa.balance_mensual sqlite3 app_flutter/balance_mensual.db "DELETE FROM movimiento WHERE cicloMes LIKE '2024-%' OR cicloMes LIKE '2025-%';"
```

Esto solo afecta a la base de datos del emulador actual — no es parte del código de la app ni se sube a git.

## Modelo de datos (Fase 0 — cerrado)

**Movimiento** — el núcleo: cualquier entrada que cuenta para el balance de un mes, venga de donde venga.
- `tipo`: ingreso / gasto
- `origen`: fijo / variable
- `nombre`, `importe`, `categoría`
- `cicloMes` — a qué mes-ciclo pertenece, según `díaInicioMes`
- enlace opcional a la plantilla que lo generó: `gastoFijoId` (nulo si `origen` = variable)
- editable y borrable individualmente, sin excepción

**GastoFijo** — plantilla recurrente (gasto o ingreso), se configura en el engranaje. Unifica lo que antes eran tres cosas separadas: `GastoFijo` mensual, `GastoAnual`, e ingresos fijos (que no existían) — ver "Gastos/Ingresos fijos (con periodicidad)" arriba.
- `nombre`, `tipo` (gasto/ingreso, por defecto gasto), `categoría` (solo relevante si `tipo` = gasto), `importe` (importe de cada pago completo)
- `periodicidadMeses` — 1 (mensual, por defecto), 3, 4, 6 o 12
- `mesDePago` (nulo si es mensual) — mes del primer/próximo pago del ciclo
- `prorratear` (solo aplica si `periodicidadMeses` > 1) — repartir entre los meses del periodo o golpear completo cada mes de pago
- `activo` — desactivarla detiene la generación futura sin borrar el histórico de `Movimiento` ya generados
- `importeParaMes(mes)` — calcula el importe que corresponde a un mes concreto según la periodicidad; con `periodicidadMeses = 1` siempre devuelve el importe completo, con `periodicidadMeses = 12` reproduce exactamente el comportamiento del antiguo `GastoAnual`

**Categoría** — catálogo con `tipo: recurrente | variable | ingreso` (ver sección Categorías arriba). `GastoFijo`/`Movimiento` de tipo gasto usan `recurrente` (si vienen de una plantilla) o `variable` (si son puntuales); cualquier `tipo: ingreso`, fijo o variable, usa siempre el catálogo `ingreso`. Columna única compuesta `(nombre, tipo)` — el mismo nombre ("otros") puede existir en varios catálogos como filas distintas.

**ConfiguraciónUsuario** — un único registro: `díaInicioMes`.

**MetaAhorro** — objetivo de ahorro a largo plazo, puramente informativo: no crea `Movimiento` ni resta nada del balance, solo compara.
- `nombre`, `importeObjetivo`, `mesesPlazo`, `cicloInicio` (el ciclo en que se creó — no editable)
- Aportación mensual necesaria = `importeObjetivo ÷ mesesPlazo`
- Progreso = suma del balance real (ingresos − gastos, con signo) de cada ciclo desde `cicloInicio` hasta el actual — es lo único que la app sabe que "te ha sobrado" cada mes, no hay ningún apartado de dinero real
- Puede haber varias metas activas a la vez, sin conflicto entre ellas (no compiten por dinero real)
- Configuración → "Metas de ahorro" (CRUD); resumen pasivo en Inicio si hay alguna

**Mecánica clave:**
- Al abrir un mes-ciclo nuevo, el motor genera automáticamente un `Movimiento` por cada `GastoFijo` activo cuyo `importeParaMes(mes)` sea mayor que 0 ese mes.
- Editar un `Movimiento` de un mes concreto **no toca la plantilla**; editar la plantilla **no reescribe meses ya generados**.
- Borrar una plantilla (`GastoFijo`) detiene la generación futura, pero no borra el histórico ya generado — eso se borra `Movimiento` por `Movimiento` si hace falta.
- Las burbujas de mes y de año **no son una tabla aparte**: son una suma de `Movimiento` agrupados por `cicloMes` (y de 12 `cicloMes` para el año). Se calculan, no se guardan.

## Plan de acción (fases)

0. ✅ Modelo de datos — **implementado en código**, no solo diseñado:
   - `lib/models/` — `Categoria`, `ConfiguracionUsuario`, `GastoFijo` (con periodicidad, unifica el antiguo `GastoAnual`), `Movimiento`
   - `lib/utils/ciclo_mes.dart` — cálculo del ciclo-mes según `díaInicioMes`
   - `lib/data/app_database.dart` — esquema SQLite (`sqflite`) local con las 5 tablas y CRUD de cada una
   - `test/` — 13 tests cubriendo modelo, ciclo de mes y base de datos (`flutter test`, todos en verde)
   - Nota técnica: `sqflite` no funciona en Web sin configuración adicional (`sqflite_common_ffi_web`). Confirmado en la práctica: en Chrome, `path_provider`/`sqflite` lanzan `MissingPluginException` y la pantalla se queda cargando para siempre. Persistencia solo funciona en Android (plataforma principal); Web sigue sirviendo solo para prototipar UI sin guardar datos.
1. ✅ Configuración — **verificado en el emulador, funciona**:
   - `lib/screens/configuracion/` — `configuracion_screen.dart` (menú), `ciclo_mes_screen.dart`, `gastos_fijos_screen.dart` + `gasto_fijo_form_screen.dart` (pantalla única para cualquier periodicidad, ya no hay `gastos_anuales_screen.dart`/`gasto_anual_form_screen.dart` — se fusionaron)
   - Todo con alta/edición/borrado (con diálogo de confirmación al borrar) conectado a `AppDatabase.instancia`
   - Categorías separadas por contexto (recurrente/variable) — ver sección Categorías, corregido tras ver la UI real con el usuario
   - Entorno de prueba: emulador Android creado por línea de comandos — AVD `Pixel_6_API_35` (Android 15, system image `google_apis` x86_64, sin Play Store). Comandos: `flutter emulators` para listar, `flutter emulators --launch Pixel_6_API_35` para arrancar, luego `flutter run -d emulator-5554`. Ya existía otro AVD previo (`Medium_Phone`, Android 36 con Play Store) pero le falta su system image en este `C:\Android\Sdk`, no se ha tocado.
   - Nota: hasta la Fase 12, los cambios de esquema durante desarrollo se resolvían con `adb shell pm clear com.avbrisa.balance_mensual` (no había datos reales que perder). Desde que hay datos de prueba que interesa conservar (años sembrados a mano para probar la comparación), `AppDatabase._abrir()` usa `version` + `onUpgrade` con migraciones reales (`ALTER TABLE ADD COLUMN`) — subir la versión y añadir el `ALTER TABLE` correspondiente en vez de recurrir a `pm clear`, salvo que el cambio de esquema sea tan grande que de verdad convenga empezar de cero.
   - Nota de estabilidad: la conexión de `flutter run` al emulador falla de forma intermitente ("Error connecting to the service protocol" / "Lost connection to device"). No es un bug de la app — se resuelve reintentando, a veces tras `adb kill-server` + `adb start-server`. El emulador en sí sigue respondiendo bien (`adb shell echo` funciona) aunque la conexión de depuración falle.
2. ✅ Pantalla principal — **verificado, funciona**: `lib/screens/inicio_screen.dart` — fecha actual, balance del ciclo en curso, historial de burbujas de mes (las de año solo aparecen con 12 ciclos-mes completos), botón + flotante.
3. ✅ Alta de movimiento — **verificado, funciona**: `lib/screens/alta_movimiento_screen.dart` — gasto/ingreso (interruptor, gasto por defecto), nombre, importe, categoría (solo si es gasto).
4. ✅ Motor de cierre — **verificado, funciona**:
   - `AppDatabase.generarMovimientosDelCiclo` — genera automáticamente un `Movimiento` por cada `GastoFijo` activo cuyo `importeParaMes` sea mayor que 0 al entrar a la pantalla principal, idempotente (no duplica si ya existe para ese ciclo).
   - `AppDatabase.sincronizarGastoFijoEnCicloActual` — al editar una plantilla, si el ciclo actual (todavía abierto) ya tenía su movimiento generado, lo actualiza (o lo borra/crea según corresponda si deja de aplicar este mes). Los ciclos ya cerrados nunca se tocan. Bug real encontrado y corregido: al principio editar la plantilla no propagaba el cambio al mes en curso.
   - `lib/screens/detalle_ciclo_screen.dart` — al tocar una burbuja de mes, se ve la lista de sus movimientos (de cualquier origen) con edición y borrado individual. Las burbujas de año todavía no son interactivas (no hay datos suficientes para probarlas: hace falta un año completo).
   - `test/app_database_test.dart` — cobertura del motor de generación y de la sincronización.
5. ✅ Onboarding + modo oscuro — **verificado, funciona**: `lib/screens/onboarding_screen.dart` (elegir día de inicio de mes en el primer arranque), `ConfiguracionUsuario.onboardingCompletado`, interruptor de modo oscuro en Configuración (`temaControlador`, `AppTheme.claro`/`oscuro`).
6. ✅ Rediseño visual (estilo Trade Republic) — **verificado, funciona**: tema oscuro/claro con acento verde, botones píldora (`StadiumBorder`), tarjetas sin bordes pesados, campos de formulario rellenos sin borde duro (`inputDecorationTheme` en `lib/theme/app_theme.dart`), pantallas de Configuración con filas tipo tarjeta (`_FilaAjuste`, `FilaGasto`).
7. ✅ Unificación de gastos fijos y anuales en un solo modelo con periodicidad — **verificado, funciona**: ver "Gastos/Ingresos fijos (con periodicidad)" arriba. `GastoAnual` ya no existe como concepto independiente.
8. ✅ Ingresos fijos (nómina, alquiler cobrado...) — **verificado, funciona**: `GastoFijo.tipo` (gasto/ingreso), interruptor `ToggleTipo` (extraído a `lib/widgets/toggle_tipo.dart`, reutilizado también en `alta_movimiento_screen.dart`) en el formulario, fila de la lista en verde con "+" cuando es ingreso.
9. ✅ Catálogo de categorías de ingreso — **implementado, verificado con tests**: `TipoCategoria.ingreso` (nómina, autónomo/freelance, bizum, alquiler cobrado, ventas, reembolsos/devoluciones, ayudas/pensión, otros), compartido entre ingresos fijos y variables. El campo Categoría ya no se oculta al elegir Ingreso — se muestra con este catálogo. Prerrequisito para la idea de Backlog "Resumen al cerrar el ciclo" (poder agrupar ingresos por categoría).
10. ✅ Donuts de ingresos/gastos por categoría (idea de Backlog "Resumen al cerrar el ciclo", implementada) — **implementado, verificado con tests y en el emulador**:
    - `lib/widgets/grafico_donut.dart` — `GraficoDonut` (dibujado a mano con `CustomPainter`, sin dependencias nuevas), `MiniDonut` (versión pequeña y pulsable) y `agruparEnSegmentos()` (suma movimientos por categoría). Paletas de color en `AppTheme.paletaIngresos`/`paletaGastos` (varios tonos de verde/rojo generados por HSL a partir de un hue base).
    - Decisión de diseño: dos donuts separados (ingresos en verde, gastos en rojo) en vez de uno mixto — no tiene sentido mezclar categorías de flujos opuestos en la misma tarta.
    - `lib/screens/desglose_categoria_screen.dart` — al tocar un mini-donut, pantalla con la versión grande + leyenda (categoría, importe, %).
    - Colocado en `lib/screens/detalle_ciclo_screen.dart` (detalle de cualquier mes, no solo al cerrar el ciclo — se puede consultar cualquier mes pasado) y también en `lib/screens/detalle_anio_screen.dart` (nueva pantalla de detalle de año, con el mismo patrón + lista de los 12 meses).
    - **La burbuja de "Años" ahora es interactiva** (antes no llevaba a ningún sitio) — lleva a `DetalleAnioScreen`, que a su vez permite entrar a cada mes.
    - **Orden de movimientos cambiado**: antes alfabético por nombre, ahora por `id` descendente (más reciente primero) — el modelo no guarda una fecha propia por movimiento (todos comparten `cicloMes`), así que el id de creación es la mejor referencia disponible de "más reciente".
    - **"Historial" (fila de meses de la pantalla principal) filtrado al año en curso** — antes mostraba todos los meses de todos los años (ruido innecesario); los años ya cerrados se consultan desde su burbuja en "Años", que sigue agregando todos los años, no solo el actual (`AppDatabase.listarAniosCompletos`, `inicio_screen.dart` separa `todosMeses` de `meses` para esto).
11. ✅ Comparación entre dos años cualesquiera — **implementado, verificado con tests y con datos reales de prueba (2024 vs 2025)**: botón "Comparar" (icono `compare_arrows`) en la barra superior de `DetalleAnioScreen`, abre un selector (bottom sheet) con los años completos disponibles (`AppDatabase.listarAniosCompletos`, excluye el año actual) y navega a `lib/screens/comparativa_anios_screen.dart` — dos columnas con ingresos/gastos/balance total de cada año, y debajo una tabla de 12 filas (un mes por fila) con el balance de ese mes en cada año, lado a lado.
12. ✅ Recordatorios (idea de Backlog "Vista próximos pagos", implementada y ampliada) — **implementado, verificado con tests**: nueva entrada "Recordatorios" en Configuración, `lib/screens/recordatorios_screen.dart`.
    - **Aviso pasivo, sin notificaciones del sistema** — decisión explícita del usuario: nada se envía desde la app, el usuario tiene que entrar a mirarlo.
    - `GastoFijo` gana `diaDelMes` (int, opcional, 1-31) — campo nuevo en el mismo formulario de siempre, no hay pantalla de alta separada. Sin este dato, el gasto/ingreso sigue apareciendo en su mes correspondiente pero sin cuenta atrás de días.
    - `GastoFijo.aplicaEnMes(mes)` (en `lib/models/gasto_fijo.dart`) — a diferencia de `importeParaMes`, ignora `prorratear` a propósito: el cobro real ocurre un mes y día concretos aunque el usuario reparta el importe en la vista mensual. Cubre también los ingresos fijos (nómina con día de cobro), no solo gastos.
    - `diasHastaProximoCobro()` en `lib/utils/recordatorios.dart` (función pura, testeada aparte de la UI) calcula la cuenta atrás.
    - Pantalla: arriba, lo que toca "Este mes" ordenado por cuánto falta ("Hoy", "Mañana", "En N días"); debajo, un calendario de los 12 meses del año (estilo burbujas, con el neto esperado de cada mes) — tocar un mes abre su lista de gastos/ingresos fijos esperados.
    - Pendiente para más adelante, no pedido todavía: cuando se construya el widget de Android (ver Backlog), mostrar ahí también este resumen además del gráfico de balance.
13. ✅ Copia de seguridad — **implementado con Auto Backup de Android, verificado de extremo a extremo con backup + borrado + restauración real**, no con exportar/importar manual (ver decisión abajo).
    - **Decisión importante, rechazada a propósito:** se planteó pedir email y vincular cuentas para sincronizar en la nube (idea del usuario). Se descartó porque contradice el diferenciador nº1 del proyecto ("100% local, sin cuenta, sin servidor" — ver Radar Competitivo) y significa construir un backend entero, no una feature pequeña.
    - **Solución adoptada:** Auto Backup del propio Android — el sistema operativo hace copia de la base de datos a la cuenta de Google que el usuario ya tiene en el móvil (o la transfiere directamente al configurar un móvil nuevo), sin que la app pida ni guarde ningún dato de cuenta, sin servidor propio, sin pantalla de login. Aviso pasivo del propio sistema, no algo que la app gestione.
    - Cambios: `android/app/src/main/AndroidManifest.xml` gana `android:allowBackup="true"`, `android:fullBackupContent="@xml/backup_rules"` (Android 6-11) y `android:dataExtractionRules="@xml/data_extraction_rules"` (Android 12+), ambos apuntando a XML nuevos en `android/app/src/main/res/xml/`.
    - **Bug real encontrado y corregido durante la verificación:** la primera versión de las reglas incluía toda la carpeta `app_flutter/` (donde sqflite guarda `balance_mensual.db`), pero esa carpeta también contiene el motor de Flutter (`kernel_blob.bin`, ~53 MB) — hacía saltar la cuota de la copia de seguridad. Corregido para incluir solo el archivo `.db` exacto, no la carpeta entera.
    - **Cómo se verificó de verdad** (no solo "compila"): el emulador no tiene Play Store ni cuenta de Google, pero Android trae un transporte de depuración en el propio dispositivo (`com.android.localtransport`) que permite probar el ciclo completo sin nube real:
      ```
      adb shell bmgr enable true
      adb shell bmgr transport com.android.localtransport/.LocalTransport
      adb shell bmgr backupnow com.avbrisa.balance_mensual   # copia de seguridad
      adb shell pm clear com.avbrisa.balance_mensual          # simula perder/cambiar de móvil
      adb shell bmgr list sets                                # para obtener el token
      adb shell bmgr restore <token> com.avbrisa.balance_mensual   # restaura, sin abrir la app
      ```
      Verificado con datos reales: 177 movimientos y 3 gastos fijos antes del borrado, exactamente los mismos después de restaurar — comprobado directamente en la base de datos (`sqlite3`) antes incluso de volver a abrir la app, y luego confirmado visualmente en la pantalla principal (balance, historial y burbujas de 2024/2025 de vuelta).
      Esta secuencia de comandos es la forma de volver a probarlo si se toca esta parte en el futuro — no hace falta una cuenta de Google real ni un dispositivo físico para verificarlo.
14. ✅ Widget de Android — **implementado y verificado en el emulador con datos reales**: balance del ciclo actual (coloreado según sea positivo/negativo) y los próximos pagos/cobros más cercanos de Recordatorios, en la pantalla de inicio del móvil, sin abrir la app.
    - **Primera dependencia externa del proyecto**: paquete `home_widget` (`^0.7.0`). Hasta ahora la app solo usaba `sqflite`/`path`/`path_provider`.
    - `lib/utils/widget_inicio.dart` — `actualizarWidgetInicio()` recalcula el balance del ciclo actual y llama a `proximosPagosDelMes()` (extraída de `recordatorios_screen.dart` a `lib/utils/recordatorios.dart` para compartirla entre la pantalla y el widget, evitando duplicar la lógica de filtrado/orden), y guarda los textos con `HomeWidget.saveWidgetData`.
    - **Refresco explícito, no en segundo plano**: se llama a `actualizarWidgetInicio()` cada vez que `InicioScreen` recarga sus datos (abrir la app, volver de cualquier pantalla) — coherente con la misma filosofía "pasiva" que Recordatorios y Auto Backup. `updatePeriodMillis` está puesto al mínimo que permite Android (30 min) solo como red de seguridad adicional, no es el mecanismo principal de refresco.
    - Nativo: `BalanceWidgetProvider.kt` (pinta un `RemoteViews` con lo último que Flutter guardó — no recalcula nada por su cuenta), `res/layout/balance_widget.xml`, `res/xml/balance_widget_info.xml`, `res/drawable/widget_background.xml`, y el `<receiver>` correspondiente en `AndroidManifest.xml`.
    - **Contenido centrado y tamaño compacto** — decisión tomada tras verlo en el emulador: texto centrado (`android:gravity="center"` + `layout_width="match_parent"` en cada `TextView`, no `wrap_content`) y, para poder encogerlo de verdad con los tiradores de redimensionar, hace falta declarar `minResizeWidth`/`minResizeHeight` aparte de `minWidth`/`minHeight` — estos últimos solo fijan el tamaño inicial al colocarlo, no el límite de cuánto se puede reducir después.
    - **Verificación real hecha**: tras instalar la app y sin haber colocado el widget nunca, aparece listado en el selector de widgets del launcher (`Widgets → balance_mensual → 1 widget`); al añadirlo, los datos coinciden con los de la app. También se confirmó leyendo directamente `shared_prefs/HomeWidgetPreferences.xml` vía `adb shell run-as com.avbrisa.balance_mensual cat shared_prefs/HomeWidgetPreferences.xml` que los valores guardados por Flutter llegan correctos al lado nativo.
    - **Bug real encontrado y corregido durante el build**: `home_widget` aplica el plugin de Gradle de Kotlin (KGP) de forma antigua — Flutter avisa de que dejará de soportarlo en el futuro (advertencia, no error; no bloquea el build hoy). Aparte, la compilación falló dos veces por bloqueos de archivo de Windows en `build/home_widget/kotlin/.../dirty-sources.txt` (mismo patrón que los bloqueos de `sqlite3.dll` ya documentados) — se resolvió con `flutter clean` y recompilando desde cero, no es un problema del código.
