#!/usr/bin/env bash
# Compila y ejecuta la prueba de concepto de AG-10 (escenario E2). Requiere JDK 21. Ejecutar desde la raíz del repo.
set -euo pipefail
cd "$(dirname "$0")/.."

rm -rf out/ag10 && mkdir -p out/ag10
javac -encoding UTF-8 -d out/ag10 $(find src/ag10 -name "*.java")

echo "=== 1/3 Demostración del escenario E2 ==="
java -Dstdout.encoding=UTF-8 -cp out/ag10 ag10.infraestructura.Main

echo; echo "=== 2/3 Pruebas con adaptadores en memoria ==="
java -Dstdout.encoding=UTF-8 -cp out/ag10 ag10.prueba.PruebaPagoConPasarelaCaida

echo; echo "=== 3/3 Función de aptitud: regla de dependencias ==="
java -Dstdout.encoding=UTF-8 -cp out/ag10 ag10.arquitectura.ReglaDependencias
