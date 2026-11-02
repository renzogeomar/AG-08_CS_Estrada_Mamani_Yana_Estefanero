# AG-10 · Bitácora de uso de IA (prompts P1 a P5)

**Herramienta:** Claude (Anthropic), en claude.ai, 31/10/2026. **Datos personales o credenciales pegados en los prompts:** ninguno. Los prompts P1 a P5 son los sugeridos en la guía del caso; el contexto que se pegó fue el enunciado y los resultados de cada paso.

**Tabla 17. Bitácora de uso de IA.**

| Prompt | Qué aceptamos | Qué rechazamos o corregimos | Quién verificó |
| --- | --- | --- | --- |
| P1 · Cuestionar la priorización | Las preguntas sobre el p95 actual (E1), la idempotencia de la pasarela (E2), el claim de agencia en el token (E3) y el boleto invalidado después del cobro (E5). Las llevamos a la sección de supuestos. | No cambiamos ninguna calificación; el prompt pedía solo preguntas, y mantuvimos E2 como único (A, A). | Rodrigo |
| P2 · Iteración de ADD asistida | Las dos alternativas (A: outbox + procesador; B: cola de mensajes) y su comparación en tácticas, costo y riesgos. | Corregimos que el procesador no necesita una VM nueva: lo desplegamos en las VM existentes para respetar la regla del costo de operación. Descartamos microservicios y caché (errores frecuentes del caso). Ajustamos los costos, que son estimaciones y no cotizaciones. | Christian |
| P3 · Revisar el ADR | Hacer medibles las frases vagas: «6 min de peor caso», «≤ 6 s», «0 duplicados». Incluir consecuencias negativas con su mitigación. | Quitamos afirmaciones que no podíamos sostener, como un costo exacto del broker, y las dejamos como estimación. | Sergio |
| P4 · Evaluador ATAM | Los riesgos R1 a R5, los puntos de sensibilidad S1 a S4 y los trade-offs T1 a T4, incluyendo el riesgo cruzado con E5. | Marcamos con «?» lo que no se puede afirmar sin datos (idempotencia real de la pasarela, memoria de las VM). La evaluación del ADR del otro grupo se hace en clase con su documento real. | Renzo |
| P5 · Cambios en el modelo | Contenedor y componentes nuevos, relaciones y vista dinámica de 8 pasos; etiqueta AG-10 para resaltar los cambios. | No tocamos elementos que el ADR no menciona. Los comentarios en línea del archivo se movieron a líneas propias por prudencia con el parser. **Pendiente:** correr `structurizr validate`; la IA no pudo ejecutarlo. | Sergio |

> La bitácora debe mantenerse fiel a lo realizado; cada prompt registra quién revisó su resultado.

## Asistencia posterior de edición

Se usó Copilot SDK en VS Code para incorporar al repositorio original los entregables asignados a Persona 1 desde el paquete del equipo, reemplazar el número de grupo y los nombres según los datos proporcionados, y comprobar que las imágenes copiadas coincidieran con las fuentes. No se generaron nuevas decisiones de arquitectura. El equipo debe revisar los archivos antes de entregarlos.
