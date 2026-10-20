# Inventario C4 de RutaColca

## Clasificación de elementos

| Elemento del caso | Tipo C4 | Justificación |
|---|---|---|
| Turista | Persona | Busca tours, reserva una salida y paga para asegurar su lugar. |
| Operador de agencia | Persona | Publica tours y administra las reservas de su agencia. |
| Guía de turismo | Persona | Se incluye en el contexto porque recibe por WhatsApp el itinerario y la lista del grupo, aunque no use directamente la plataforma. |
| Administrador | Persona | Aprueba agencias y consulta los reportes de ventas. |
| RutaColca | Sistema de software propio | Plataforma del consorcio que centraliza la publicación de tours, reservas, pagos y coordinación. |
| Pasarela de pagos | Sistema externo | Procesa los pagos en línea y no entrega a RutaColca los datos de la tarjeta. |
| WhatsApp Business | Sistema externo | Entrega a los guías los itinerarios y las listas de los grupos. |
| Sistema de AUTOCOLCA | Sistema externo | Valida los boletos turísticos mediante la integración asumida en el caso. |
| Web del turista | Contenedor | Aplicación React (SPA) para buscar tours, reservar y pagar. |
| Portal de agencias | Contenedor | Aplicación React (PWA) para publicar tours y gestionar reservas. |
| API | Contenedor | Servicio Java 21 con Spring Boot que implementa las reglas y coordina las integraciones. |
| Base de datos | Contenedor | Almacén PostgreSQL 16 para tours, salidas, cupos y reservas; no almacena datos de tarjetas. |

## Borrador de contexto

RutaColca es una sola caja en esta vista. Las cuatro personas se conectan al sistema; los servicios externos son la pasarela de pagos, WhatsApp Business y el sistema de AUTOCOLCA.

| Origen | Destino | Relación propuesta |
|---|---|---|
| Turista | RutaColca | Busca tours, reserva salidas y paga en |
| Operador de agencia | RutaColca | Publica tours y administra reservas en |
| Guía de turismo | RutaColca | Recibe itinerarios y listas de grupos coordinados por |
| Administrador | RutaColca | Aprueba agencias y consulta reportes en |
| RutaColca | Pasarela de pagos | Procesa los cobros de las reservas mediante |
| RutaColca | WhatsApp Business | Envía itinerarios y listas de grupos mediante |
| RutaColca | Sistema de AUTOCOLCA | Valida boletos turísticos con |

## Borrador de contenedores y relaciones

| Origen | Destino | Responsabilidad / relación | Tecnología o protocolo |
|---|---|---|---|
| Turista | Web del turista | Busca tours, selecciona salidas y paga | HTTPS |
| Web del turista | API | Consulta disponibilidad y solicita reservas | JSON/HTTPS |
| Operador de agencia | Portal de agencias | Publica tours y gestiona reservas | HTTPS |
| Administrador | Portal de agencias | Aprueba agencias y consulta reportes | HTTPS |
| Portal de agencias | API | Gestiona tours, cupos y reservas | JSON/HTTPS |
| API | Base de datos | Lee y registra tours, salidas y reservas | JDBC |
| API | Pasarela de pagos | Cobra reservas confirmadas | HTTPS |
| API | Sistema de AUTOCOLCA | Valida el boleto turístico presentado | HTTPS |
| API | WhatsApp Business | Solicita el envío de itinerarios y listas | HTTPS |
| WhatsApp Business | Guía de turismo | Entrega el itinerario y la lista del grupo | Canal de WhatsApp |

## Flujo dinámico: reservar y pagar un tour

1. El turista elige una salida e ingresa el número de su boleto en la Web del turista.
2. La Web del turista solicita a la API validar el boleto y reservar la salida.
3. La API consulta al sistema de AUTOCOLCA y recibe el resultado de la validación.
4. Si el boleto es válido y hay cupo, la API solicita el cobro a la pasarela de pagos.
5. La API registra la reserva confirmada en la base de datos.
6. La API devuelve la confirmación a la Web del turista.
7. La API solicita a WhatsApp Business el envío del itinerario y la lista al guía, de acuerdo con la coordinación de la salida.

**Decisión de orden:** validar el boleto antes de cobrar, para no cobrar una reserva que no pueda confirmarse por un boleto inválido; solo se cobra si también hay cupo disponible.
