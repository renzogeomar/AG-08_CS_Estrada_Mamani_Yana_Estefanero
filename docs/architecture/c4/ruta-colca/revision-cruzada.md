| N.º | Hallazgo | ¿Lo aceptamos? | Motivo |
| :--- | :--- | :--- | :--- |
| 1 | Faltaba el guía como persona del contexto. | Sí | Recibe información del sistema por WhatsApp; es actor del contexto. |
| 2 | En el contexto se dibujó la base de datos dentro de RutaColca. | No | En contexto el sistema es una sola caja; la BD es un contenedor. |
| 3 | La relación portal → API decía “usa”. | Sí, se corrigió | Se cambió a “Publica tours y sincroniza reservas” y se agregó JSON/HTTPS. |
| 4 | Se propuso agregar Kafka y Redis. | No | No están en el ADR-001; no se inventan tecnologías. |
| 5 | La relación con la pasarela estaba en dos direcciones. | Sí, se corrigió | Se dejó una sola dirección: la API cobra en la pasarela. |
| 6 | Faltaba el protocolo en API → base de datos. | Sí, se corrigió | Se agregó el protocolo JDBC. |