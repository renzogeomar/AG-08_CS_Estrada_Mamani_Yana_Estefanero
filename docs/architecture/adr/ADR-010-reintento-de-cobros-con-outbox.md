# ADR-010: Reintentar los cobros pendientes con outbox transaccional y procesador de tareas

Estado: Aceptado · Fecha: 31/10/2026 · Escenario: E2

## Contexto

En temporada alta las reservas se multiplican por diez y la pasarela de pagos falla a ratos. Hoy `ReservarTour` llama a la pasarela de forma síncrona, sin límite de espera ni dónde guardar el trabajo: si la pasarela no responde, la petición se cuelga, el turista ve un error y la reserva se pierde; además los hilos bloqueados degradan el catálogo (E1).

El escenario E2 exige que, con la pasarela caída 15 minutos, se pierdan **0 reservas pagadas**, se confirmen **≤ 30 minutos** después de la recuperación, no haya **cobros duplicados** y la API responda en **≤ 6 s**. Restricciones: 4 desarrolladores, 3 semanas, mantener el monolito modular (ADR-001) y las tecnologías aprobadas; toda infraestructura nueva debe justificar su costo de operación.

## Alternativas consideradas

- **A:** tiempo de espera, reintento con espera exponencial, degradación y transacción, con el patrón outbox transaccional, circuit breaker e idempotencia. Procesador de tareas del mismo código sobre PostgreSQL.
- **B:** tiempo de espera, reintento por reentrega y redundancia, con una cola de mensajes gestionada (RabbitMQ o SQS), DLQ y un consumidor de pagos.

## Decisión

Elegimos la **alternativa A**. Concretamente:

1. `AdaptadorPasarela` implementa el puerto `PasarelaPago` con timeout de 5 s y circuit breaker (Resilience4j; valores iniciales: abrir con ≥ 50 % de fallas en 20 llamadas). Cada cobro lleva como clave de idempotencia el id de la reserva.
2. Si la pasarela no responde, `ReservarTour` guarda la reserva en `PENDIENTE_PAGO` y una fila en `tarea_pago` en **una sola transacción**, y la API responde 202 («pago en proceso»).
3. Un contenedor nuevo, el **Procesador de tareas** (mismo código, perfil `worker`), corre cada 60 s, toma las tareas vencidas con `FOR UPDATE SKIP LOCKED` y reintenta con esperas de 1, 2, 4 y 5 min (tope de 5 min).
4. Al aprobarse el cobro, la reserva pasa a `CONFIRMADA` y se envía la confirmación por WhatsApp. Si pasan 2 h sin cobrar, la reserva pasa a `EXPIRADA`, se libera el cupo y se avisa al turista.
5. Despliegue: un contenedor adicional en cada una de las 2 VM existentes; no se agregan VM ni servicios.

Cumple la medida porque: (a) la reserva y la tarea se guardan atómicamente, de modo que no hay reservas perdidas; (b) el peor caso de confirmación es el tope de espera (5 min) más el sondeo (1 min), unos **6 min** frente al límite de 30; (c) la clave de idempotencia evita cobrar dos veces cuando la pasarela cobra pero la respuesta se pierde; y (d) el timeout de 5 s acota la respuesta de la API. La prueba `PruebaPagoConPasarelaCaida` (en `src/ag10/prueba`) verifica (b), (c) y (d), y que ninguna reserva se pierde, usando adaptadores en memoria; la atomicidad real de (a) la garantiza la transacción de PostgreSQL.

## Consecuencias

+ **Cumple E2** con margen: ≈ 6 min de peor caso frente a 30 min, y sin infraestructura nueva (costo adicional ≈ US$ 0).

+ **Protege E1:** el timeout y el circuit breaker liberan los hilos de la API cuando la pasarela falla, así que el catálogo sigue respondiendo.

+ **Ayuda a E4 y E5:** el puerto con clave de idempotencia facilita agregar PayPal como un adaptador más, y la misma outbox sirve de base para reintentar validaciones con AUTOCOLCA.

- **Consistencia eventual:** el turista ve «pago en proceso» hasta unos 6 min. Se mitiga con un mensaje claro en la web y la confirmación por WhatsApp.

- **Cupo retenido hasta 2 h** mientras el pago está pendiente, lo que puede bloquear salidas casi llenas. Se mitiga con el TTL configurable y una métrica de reservas pendientes.

- **Más carga en PostgreSQL:** una consulta por minuto por instancia y una escritura extra por reserva pendiente. Se mitiga con un índice parcial sobre `(estado, proximo_intento)` y monitoreo.

- **Riesgo con E5:** un reintento de cobro no debe ejecutarse sobre una reserva cuyo boleto aún no fue validado. Se mitiga exigiendo el estado «boleto validado» antes de cobrar.

- **Datos de pago:** la tarea guarda solo el id de la reserva y el monto, nunca datos de tarjeta; así no se amplía el alcance de seguridad (E3).

- **Memoria:** el procesador consume ≈ 0,5 GB más por VM; hay que confirmar que las VM actuales lo soportan junto al pico de la API.

La alternativa B queda descartada por ahora: exige además una outbox para evitar la doble escritura, agrega infraestructura nueva y es el plan más largo para un equipo de 4 en 3 semanas. Se reevaluará si aparecen varios consumidores de eventos.
