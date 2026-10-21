# Inventario C4 de RutaColca (Paso 1)

Clasificación de cada elemento del caso según las abstracciones de C4. Un contenedor C4 es una aplicación o un almacén de datos que debe estar en ejecución para que el sistema funcione; no es un contenedor Docker.

| Elemento del caso | Tipo C4 | Justificación (una línea) |
|---|---|---|
| Turista | Persona | Es un humano que busca, reserva y paga tours en la plataforma. |
| Operador de agencia | Persona | Es un rol humano que publica tours y registra reservas. |
| Guía de turismo | Persona | Es un humano que forma parte del flujo: recibe el itinerario, aunque sea por WhatsApp y no entre a la plataforma. |
| Administrador | Persona | Es un rol humano que aprueba agencias y revisa ventas. |
| RutaColca | Sistema de software (propio) | Es el sistema que construye el equipo y entrega valor al consorcio. |
| Pasarela de pagos | Sistema externo | Cobra con tarjeta o billetera móvil; lo opera un tercero. |
| WhatsApp Business | Sistema externo | Mensajería de un tercero que usamos para avisar a los guías. |
| Sistema de AUTOCOLCA | Sistema externo | Emite y valida el boleto turístico; lo opera otra entidad. |
| Web del turista | Contenedor | Aplicación (React SPA) que debe estar en ejecución para que el turista reserve. |
| Portal de agencias | Contenedor | Aplicación (React PWA) para operadores y administrador. |
| API | Contenedor | Aplicación (Java 21, Spring Boot) con las reglas de negocio. |
| Base de datos | Contenedor | Almacén de datos (PostgreSQL 16) con tours, salidas y reservas. |

## Decisión sobre el guía

Discutimos si el guía debía aparecer en el contexto, ya que no usa la plataforma. Decidimos incluirlo como persona porque el sistema existe en parte para darle información: sin el guía el flujo de la reserva queda incompleto. Como solo habla con WhatsApp, la flecha sale de WhatsApp Business hacia el guía y no desde RutaColca, para mostrar que el contacto es indirecto.
