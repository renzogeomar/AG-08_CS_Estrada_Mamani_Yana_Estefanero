# ADR-002: Trabajo sin conexión en las agencias de Chivay

- **Estado:** Aceptado por el grupo
- **Fecha:** 18 de octubre de 2026
- **Historia relacionada:** HU-05

## Contexto

La historia HU-05 pide que las agencias de Chivay registren reservas presenciales aunque no haya internet. La conexión en Chivay es intermitente. El ADR-001 ya define el portal de agencias como una PWA en React, y el equipo es de 4 desarrolladores con un mes para el MVP, por lo que conviene no sumar tecnologías nuevas.

## Decisión

El portal de agencias guarda las reservas presenciales en un almacén local (IndexedDB) de la tablet cuando no hay internet, con un Service Worker propio de la PWA. Al volver la conexión, las envía a la API en lote.

Reglas:

1. Cada agencia de Chivay tiene un cupo reservado por salida para ventas sin conexión.
2. La API decide el cupo por orden de llegada y rechaza las reservas sin cupo; el portal avisa al operador.
3. Cada reserva lleva un identificador único generado en la tablet para evitar duplicados.
4. El boleto turístico se valida al sincronizar; mientras tanto la reserva queda PENDIENTE.

No se usan apps nativas ni colas de mensajes, porque no forman parte del ADR-001.

## Consecuencias

- A favor: las agencias de Chivay pueden vender sin internet y no se agrega infraestructura nueva.
- En contra: el cupo reservado para ventas presenciales no se puede vender en línea; la sincronización añade lógica y pruebas; hay datos personales en la tablet, por lo que se guardan solo los mínimos (nombre, boleto y salida) y se borran al sincronizar.
- Cambios en el modelo: nuevo contenedor «Almacén local de reservas», dos relaciones nuevas del portal y una instancia nueva en el nodo «Tablet de la agencia».
