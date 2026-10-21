# RutaColca · Modelo C4 (AG-08)

Modelo C4 de RutaColca escrito como código con Structurizr DSL.
Curso: Construcción de Software (1703243) · EPIS-UNSA · 2026-B · Grupo N.º __

## Integrantes

| Integrante | Rol |
|---|---|
| Rodrigo Estefanero | Modelador |
| Renzo Mamani | Redactor del DSL |
| Christian Yana | Revisor |
| Sergio Estrada | Vocero |

## Contenido

| Archivo | Qué es |
|---|---|
| `inventario.md` | Paso 1: clasificación de los elementos del caso |
| `workspace.dsl` | Modelo y vistas: Contexto, Contenedores, Dinámico, Despliegue y ContenedoresReto |
| `revision-cruzada.md` | Paso 5: hallazgos de la revisión cruzada y lista de revisión |
| `explicacion.md` | Paso 6: explicación del contexto para una persona no técnica |
| `export/` | Paso 9: salidas en C4-PlantUML y Mermaid |
| `img/` | Diagramas en PNG |
| `bitacora-ia.md` | Paso 10: bitácora de uso de IA |
| `informe/` | Informe completo en Word |
| `../adr/ADR-002-trabajo-sin-conexion.md` | Decisión del reto sin conexión |

## Cómo validar y generar los diagramas

```bash
./structurizr.sh validate -w docs/architecture/c4/ruta-colca/workspace.dsl
./structurizr.sh export -w docs/architecture/c4/ruta-colca/workspace.dsl -f plantuml/c4plantuml -o docs/architecture/c4/ruta-colca/export
./structurizr.sh export -w docs/architecture/c4/ruta-colca/workspace.dsl -f mermaid -o docs/architecture/c4/ruta-colca/export
java -jar plantuml.jar -tpng -o ../img docs/architecture/c4/ruta-colca/export/*.puml
```
