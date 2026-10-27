# AG-09: Verificación crítica de la propuesta de IA

**Responsable:** Sergio Estrada
**Fecha:** 27/10/2026
**IA consultada:** Claude (Anthropic), modelo Sonnet 5.5
**Material contrastado:** `identificacion-y-paternite.md`, `strategy-precios.puml`, `observador-reservas.puml`, ADR-002 y `workspace.dsl` (API en Java 21 + Spring Boot, 2 VM, PostgreSQL 16).

## 1. Prompt usado

Se siguió la plantilla del Tema 09 (contexto real, un solo patrón por escenario, alternativa sin patrón y regla de decir "ningún patrón" cuando no se justifique).

```text
Actúa como diseñador de software experto en patrones GoF.

Contexto: RutaColca es una plataforma de reservas de tours. La API es Java 21 con
Spring Boot, la base de datos es PostgreSQL 16 y la API corre en 2 VM detrás de un
balanceador. El equipo son 4 desarrolladores con un mes para el MVP.

Escenarios:
1. Acepta tarjeta, Yape y PayPal.
2. El precio varía por temporada, grupo o estudiante.
3. Al confirmar una reserva se avisa al turista, al guía y a la agencia.
4. La API de AUTOCOLCA no coincide con la interfaz esperada.
5. La disponibilidad de cupos se consulta cientos de veces.

Tareas, para cada escenario:
1. Identifica el problema de diseño.
2. Propón UN solo patrón GoF y justifícalo con un principio de diseño.
3. Propón también una alternativa SIN patrón y di cuál elegirías.
4. Dibuja el diagrama de clases en PlantUML solo para los escenarios 2 y 3.
5. Explica qué pasa si no se usa el patrón.

Reglas: Java 21, sin dependencias nuevas. Si un escenario no justifica un patrón,
dilo y explica por qué.
```

## 2. Resumen de la respuesta de la IA

| Esc. | Problema que identificó | Patrón propuesto | Alternativa sin patrón |
| :-- | :-- | :-- | :-- |
| 1 | Cada pasarela tiene un SDK distinto y el servicio de reservas no debe conocerlos | **Adapter** (una clase por pasarela que implementa `PasarelaPago`). Para elegir la pasarela, sugirió un `Map<MetodoPago, PasarelaPago>` inyectado por Spring en vez de una Factory con `switch` | Un `switch` dentro del servicio. Vale solo si fueran 2 medios que nunca cambian |
| 2 | Las reglas de precio cambian según temporada, grupo o estudiante | **Strategy** (`PoliticaPrecio` con una clase por regla) | Un método con `if/else`. Sirve si las reglas son pocas y estables |
| 3 | La confirmación conoce todos los canales de aviso | **Observer** (`ObservadorReserva` y un publicador de eventos) | Llamar a los 3 avisos desde `confirmarReserva`. Se vuelve frágil al agregar un canal |
| 4 | La API de AUTOCOLCA tiene otra firma y no se puede modificar | **Adapter** (`AutocolcaAdapter`) | Llamar al cliente HTTP directo. Filtra el formato externo al dominio |
| 5 | Muchas lecturas repetidas de cupos | **Proxy de caché** como patrón de libro, pero recomendó **no usarlo en el MVP** y empezar con índice en PostgreSQL y, si hace falta, `@Cacheable` con TTL corto | Índice compuesto (`tour_id`, `fecha_salida`) y medir antes de optimizar |

Para los escenarios 2 y 3 la IA entregó diagramas PlantUML con interfaz, clases concretas y cliente.

## 3. Contraste con el diseño del grupo

| Esc. | Decisión del grupo | Decisión de la IA | Resultado | Por qué |
| :-- | :-- | :-- | :-- | :-- |
| 1 | Factory apoyada en Adapter | Adapter + mapa inyectado por Spring | **Aceptado en parte** | Coincidimos en que el patrón central es Adapter. La Factory con `switch` seguiría obligando a editar una clase al agregar un medio. Queda como mejora: usar el mapa inyectado y evitar clase Factory propia |
| 2 | Strategy (`PoliticaPrecio`) | Strategy | **Aceptado** | Hay variantes reales y se agregan reglas con frecuencia (principio abierto/cerrado) |
| 3 | Observer | Observer | **Aceptado** | Tres destinatarios hoy y más canales probables. Se mantiene el diagrama del grupo |
| 4 | Adapter | Adapter | **Aceptado** | El servicio externo no se puede modificar, justificado por programar para interfaces |
| 5 | Ningún patrón (se descarta Proxy manual) | Proxy de caché como patrón de libro, pero primero medir | **Aceptado el resultado, rechazado el Proxy** | El grupo ya tenía el argumento de las 2 VM: una caché en memoria por instancia muestra cupos distintos y puede causar sobreventa. La IA llegó a la misma conclusión |

## 4. Qué rechazamos o corregimos de la IA

1. **Proxy de caché como primera opción para el escenario 5.** Se rechaza. Con 2 VM, un `Map` local por instancia no es compartido, y el ADR-002 dice que la API decide el cupo por orden de llegada. Por eso la reserva siempre debe verificar el cupo en PostgreSQL. Una caché solo podría usarse para mostrar la disponibilidad, nunca para confirmar.
2. **Reemplazar la Factory del grupo.** Se acepta como mejora, no como cambio obligatorio: en la entrega se deja la matriz como está y se anota la alternativa del mapa inyectado.
3. **Estrategias de precio combinadas.** La IA advirtió que Strategy elige una sola regla. Un estudiante en temporada alta necesitaría combinar dos. Es una pregunta abierta para el grupo: si el negocio exige combinar, habría que componer las reglas (Decorator) o definir una prioridad. Hoy el caso no lo pide, así que se mantiene Strategy simple.
4. **Observer síncrono.** La IA señaló que si el aviso de WhatsApp falla, no debería fallar la confirmación. Se acepta como nota de diseño: notificar después de guardar la reserva y capturar errores por observador. No cambia el diagrama.

## 5. Verificaciones propias antes de aceptar

- Los dos `.puml` del grupo compilan con PlantUML y muestran interfaz, clases concretas y cliente (roles visibles).
- La afirmación de las 2 VM y del stack (Java 21, Spring Boot, PostgreSQL 16) se comprobó en `workspace.dsl`.
- Los porcentajes y reglas de la nota del diagrama de Strategy (15 % para grupos de 5 o más) son un supuesto del grupo. El caso del curso no da esos valores, por lo que deben presentarse como ejemplo y no como regla del negocio.
- La IA no ejecutó código. Sus afirmaciones sobre Spring (`@Cacheable`, inyección de `Map`) son conocimiento general y deben comprobarse en el proyecto real antes de afirmarlas como hechos.

## 6. Filas para la bitácora de IA

| N.º | Fecha | Prompt | Qué se aceptó | Qué se rechazó o corrigió | Responsable |
|-----|-------|--------|---------------|---------------------------|-------------|
| 9 | 27/10/2026 | P9 · Patrones por escenario con alternativa sin patrón | Strategy (esc. 2), Observer (esc. 3) y Adapter (esc. 4); la advertencia de notificar sin romper la confirmación | Rechazamos el Proxy de caché para el escenario 5 por las 2 VM y el riesgo de sobreventa. La Factory del esc. 1 queda anotada como mejorable con un mapa inyectado | Sergio Estrada |

## 7. Qué decir al socializar (3 minutos)

- Patrones elegidos: Adapter (1 y 4), Strategy (2), Observer (3). Escenario 5: ninguno.
- Propuesta de IA rechazada: Proxy de caché para la disponibilidad, porque la caché local en 2 VM puede mostrar cupos viejos y vender de más.
- Si preguntan por `@Cacheable`: Spring también lo implementa con un proxy, pero lo declara el framework y no lo escribimos ni mantenemos nosotros. Lo que descartamos es la clase Proxy manual.
