# Revisión cruzada (Paso 5)

Revisor: Christian Yana · Grupo revisor: N.º __

La revisión aplicó la lista de c4model.com/diagrams/checklist y una auditoría previa con IA (prompt P5). Cada hallazgo se verificó contra el modelo antes de aceptarlo.

## Registro de hallazgos

| N.º | Hallazgo | ¿Lo aceptamos? | Motivo |
|---|---|---|---|
| 1 | Las siglas SPA, PWA y AUTOCOLCA no se explican en los diagramas. | Sí | La lista pide que las siglas se entiendan o estén en la leyenda. Las definimos en las descripciones y en el informe. |
| 2 | La relación entre WhatsApp Business y el guía no dejaba claro que el contacto es indirecto. | Sí | Cambiamos la dirección a WhatsApp → Guía con el texto «Entrega mensajes a», para que RutaColca no parezca hablar directo con el guía. |
| 3 | Agregar un contenedor «Docker» en el diagrama de contenedores. | No | Un contenedor C4 es una aplicación o un almacén de datos, no un contenedor Docker. Docker aparece solo como tecnología del nodo en el despliegue. |

## Lista de revisión aplicada

| Aspecto | Pregunta de verificación | Resultado |
|---|---|---|
| General | ¿Tiene título con tipo y alcance? ¿Tiene leyenda? | Cumple. Cada figura tiene título, subtítulo y leyenda. |
| Elementos | ¿Cada elemento tiene nombre, tipo y descripción? ¿Los contenedores indican tecnología? | Cumple. |
| Siglas | ¿Las siglas se entienden o están en la leyenda? | Cumple (hallazgo 1). |
| Relaciones | ¿Cada línea tiene etiqueta con intención y dirección? ¿Entre contenedores indica protocolo? | Cumple. |
| Notación | ¿Se explican formas, colores, bordes y líneas? ¿Funciona en blanco y negro? | Cumple. Persona: rectángulo redondeado; base de datos: cilindro; externos: borde discontinuo. |
| Audiencia | ¿Lo entiende alguien que no estuvo en la reunión? | Cumple en el contexto, comprobado con la explicación para la gerente. |
