# Revisión Cruzada - Grupo AG-08

**Rol:** Revisor (Christian Yana)
**Herramienta de apoyo:** Prompt P5 (Auditor C4 con IA)

| Hallazgo N.º | Elemento evaluado | ¿Lo aceptamos? | Motivo y Acción Correctiva |
| :--- | :--- | :--- | :--- |
| 1 | Contenedores (Uso de Docker) | Sí | La IA detectó que en el borrador original había un contenedor llamado "Docker". Según las reglas C4, Docker no es un contenedor lógico de software, sino infraestructura. Se corrigió moviendo Docker exclusivamente a la vista de despliegue. |
| 2 | Relaciones (Verbo "usa") | Sí | El diagrama de contexto de otro grupo usaba la etiqueta genérica "usa" para conectar al turista. Se recomendó cambiarla por verbos específicos como "Busca tours y reserva salidas". |
| 3 | Tecnologías omitidas | Sí | Faltaba el protocolo en la flecha de la pasarela de pagos. Se añadió "HTTPS" a todas las conexiones externas. |
