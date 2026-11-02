# AG-10 · Evaluación cruzada al estilo ATAM

## A. Evaluación de nuestra decisión (ADR-010) frente a los cinco escenarios

Aplicamos el prompt P4 (evaluador ATAM) a nuestra propia decisión, mirando los cinco escenarios y no solo E2. Es lo que esperamos que encuentre el grupo evaluador. Lo que no podemos afirmar con la información disponible lo marcamos con «?».

**Tabla 10a. Evaluación al estilo ATAM de nuestra decisión (ADR-010).**

| Tipo | Hallazgo | Escenario afectado |
| --- | --- | --- |
| Riesgo | R1. Si la pasarela real no soporta clave de idempotencia ni consulta de estado, un cobro «ambiguo» (cobrado pero sin respuesta) se duplicaría al reintentar. ? | E2 |
| Riesgo | R2. El procesador podría reintentar cobros sobre reservas con boleto aún no validado por AUTOCOLCA, cobrando un boleto inválido. | E5, E2 |
| Riesgo | R3. API y procesador comparten VM: un pico de la API podría dejar sin CPU o memoria al procesador (o al revés). ? | E1, E2 |
| Riesgo | R4. PostgreSQL es punto único para la outbox: si la base cae, no se guarda la reserva pendiente. Queda fuera del alcance del escenario, pero conviene decirlo. | E2 |
| Riesgo | R5. Si la tarea o los registros incluyeran datos de pago, se ampliaría el alcance de seguridad. La decisión lo evita guardando solo id y monto. | E3 |
| Punto de sensibilidad | S1. Tope de espera (5 min) y período de sondeo (60 s): fijan el peor caso de confirmación (≈ 6 min contra los 30 permitidos). | E2 |
| Punto de sensibilidad | S2. Timeout de 5 s: más bajo produce falsos «pendientes» en picos; más alto ocupa hilos de la API y empeora el catálogo. | E1, E2 |
| Punto de sensibilidad | S3. TTL de 2 h de las reservas pendientes: más corto libera cupo pero pierde ventas; más largo retiene cupos. | E2 |
| Punto de sensibilidad | S4. Índice y tamaño del lote de la tabla de tareas: de ello depende la carga sobre PostgreSQL con 10 veces las reservas. ? | E1 |
| Trade-off | T1. Disponibilidad frente a consistencia: se acepta la reserva sin pago confirmado. Mejora E2 pero deja al turista y a la agencia con un estado intermedio y retiene cupos. | E2 frente a la experiencia de compra |
| Trade-off | T2. Sondeo en lugar de broker: evita infraestructura nueva (simple y barato), pero impone una latencia mínima de 1 min y una consulta constante a la base. | E2 frente a E1 |
| Trade-off | T3. El circuit breaker protege los hilos y el catálogo, pero puede cortar cobros que habrían funcionado cuando la pasarela está intermitente. | E1 frente a E2 |
| Trade-off | T4. Exigir idempotencia en el puerto añade un requisito a cada adaptador futuro (p. ej., PayPal), pero deja la integración lista para ≤ 3 días-persona. | E4 |

En balance, la decisión **ayuda** a E1 (libera hilos), E4 (puerto estable) y E5 (la outbox se reutiliza); **no afecta** a E3 si se respeta la regla de no guardar datos de pago; y su principal tensión es con E5, porque cobrar y validar el boleto ahora dependen de un orden que hay que garantizar (R2).

## B. Evaluación del ADR del grupo con el escenario siguiente (E3)

La evaluación cruzada se hace en clase con el ADR real del grupo vecino (el que tiene el escenario siguiente, E3 · Seguridad). Como no podemos inventar lo que ese grupo decidió, dejamos la tabla preparada con las preguntas que conviene hacerle a un ADR de seguridad; los hallazgos se anotan en la columna de la derecha durante el intercambio.

**Tabla 10b. Evaluación del ADR del grupo con E3 (completar en clase).**

| Tipo | Qué revisar en un ADR de E3 | Hallazgo en el diseño del otro grupo |
| --- | --- | --- |
| Riesgo | ¿La verificación «este tour es de tu agencia» se hace en el servicio, para cada operación (modificar, borrar, leer), y no solo en el controlador o en la pantalla? ¿Hay otros caminos de escritura que la salten, como la sincronización del portal? | Si la comprobación de pertenencia del tour a la agencia se realiza solo en el controlador o en la interfaz, una operación que use otro camino —por ejemplo, la sincronización del portal— podría omitirla y permitir lecturas o cambios no autorizados. El ADR debería indicar que la autorización se aplica en el servicio de dominio o de aplicación en cada operación y que todos los caminos de escritura pasan por esa verificación. Si no lo especifica, queda como riesgo pendiente de validar mediante pruebas de autorización. |
| Punto de sensibilidad | ¿De dónde sale la agencia del operador (claim del token)? ¿Qué pasa si el token trae una agencia desactualizada o el operador cambia de agencia? | La decisión depende de cómo se obtiene y mantiene actualizada la agencia asociada al operador. Si se toma de un claim del token, debe aclararse quién lo emite y cómo se invalida o renueva cuando el operador cambia de agencia. Un token vigente con datos desactualizados podría autorizar operaciones con la agencia anterior. El ADR no permite confirmar este comportamiento; conviene documentar la fuente de verdad y la estrategia de actualización o revocación. |
| Trade-off | ¿Cuánto cuesta cada petición por la consulta extra de propiedad (E1)? ¿Qué se guarda en la auditoría y cuánto crece (E2/almacenamiento, datos personales)? | Verificar la propiedad del tour en cada petición añade una consulta o comprobación de acceso a datos, lo que puede aumentar la latencia y la carga; el impacto depende de los índices y del patrón de acceso, por lo que debería medirse. La auditoría mejora la trazabilidad, pero aumenta el almacenamiento y puede registrar datos personales. Se recomienda guardar solo los datos necesarios para investigar cambios —por ejemplo, operador, acción, recurso y fecha— y definir retención y acceso. Si el ADR no cuantifica estos efectos, quedan como aspectos por medir. |
