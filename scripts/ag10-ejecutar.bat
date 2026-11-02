@echo off
rem Compila y ejecuta la prueba de concepto de AG-10 (escenario E2). Requiere JDK 21. Ejecutar desde la raiz del repo.
cd /d "%~dp0.."
if exist out\ag10 rmdir /s /q out\ag10
mkdir out\ag10
dir /s /b src\ag10\*.java > out\ag10\fuentes.txt
javac -encoding UTF-8 -d out\ag10 @out\ag10\fuentes.txt || exit /b 1

echo === 1/3 Demostracion del escenario E2 ===
java -Dstdout.encoding=UTF-8 -cp out\ag10 ag10.infraestructura.Main || exit /b 1
echo.
echo === 2/3 Pruebas con adaptadores en memoria ===
java -Dstdout.encoding=UTF-8 -cp out\ag10 ag10.prueba.PruebaPagoConPasarelaCaida || exit /b 1
echo.
echo === 3/3 Funcion de aptitud: regla de dependencias ===
java -Dstdout.encoding=UTF-8 -cp out\ag10 ag10.arquitectura.ReglaDependencias || exit /b 1
