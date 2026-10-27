# AG-09: Identificación de Patrones y Análisis de Paternite en RutaColca

**Responsable:** Rodrigo Estefanero

## 1. Matriz de Identificación de los 5 Escenarios

| N.º | Escenario en RutaColca | Problema de Diseño | Patrón Candidato (Familia) | Principio de Diseño que lo Justifica |
| :--- | :--- | :--- | :--- | :--- |
| **1** | Acepta tarjeta, Yape y PayPal | Múltiples condicionales (`if/else` o `switch`) y operadores `new` repartidos en el servicio de reservas para instanciar cada método de pago. | **Fábrica / Factory** (Creacional) apoyado en **Adaptador**. | **Programar para interfaces** y **Abierto/cerrado**: el servicio depende solo de la interfaz de pago y agregar un medio nuevo no rompe el código cliente. |
| **2** | El precio varía por temporada, grupo o estudiante | El algoritmo de cálculo de precio cambia según la modalidad de la reserva; usar condicionales acopla todas las reglas tarifarias en una sola clase. | **Strategy** (Comportamental). | **Encapsular lo que varía** y **Composición sobre herencia**: se separa el cálculo cambiante de la reserva estable y se intercambia en ejecución. |
| **3** | Al confirmar una reserva se avisa al turista, al guía y a la agencia | El servicio de reservas queda fuertemente acoplado a múltiples canales de notificación concretos (WhatsApp, correo, portal); agregar un aviso nuevo obliga a editar la confirmación. | **Observador / Observer** (Comportamental). | **Bajo acoplamiento** y **Abierto/cerrado**: el sujeto notifica el evento a una lista de suscriptores sin conocer sus clases concretas. |
| **4** | La API de AUTOCOLCA no coincide con la interfaz esperada | El servicio externo de AUTOCOLCA tiene firmas y tipos de datos incompatibles con el dominio interno de RutaColca y no se puede modificar. | **Adaptador / Adapter** (Estructural). | **Programar para interfaces**: una clase intermediaria implementa la interfaz interna esperada y traduce las llamadas hacia la API externa. |
| **5** | La disponibilidad se consulta cientos de veces | Cada consulta de cupos golpea repetidamente la base de datos PostgreSQL generando latencia en horas punta. | **NINGUNO (Se descarta Proxy manual por *Paternite*)** / Alternativa teórica: *Proxy de caché*. | **Simple primero (Evitar la *Paternite*)**: no forzar un patrón GoF manual cuando la infraestructura o una solución simple del framework lo resuelve mejor. |