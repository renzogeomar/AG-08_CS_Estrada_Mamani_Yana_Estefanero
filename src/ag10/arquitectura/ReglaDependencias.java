package ag10.arquitectura;

import java.io.IOException;
import java.nio.file.*;
import java.util.List;
import java.util.stream.Stream;

/**
 * Función de aptitud (fitness function): el build falla si el dominio importa la aplicación o la
 * infraestructura, o si la aplicación importa la infraestructura. Protege E4 ("0 cambios en el dominio").
 * Ejecutar desde la raíz del repositorio.
 */
public class ReglaDependencias {
    record Regla(String carpeta, List<String> prohibidos) { }

    static final List<Regla> REGLAS = List.of(
        new Regla("src/ag10/dominio", List.of("import ag10.aplicacion", "import ag10.infraestructura")),
        new Regla("src/ag10/aplicacion", List.of("import ag10.infraestructura"))
    );

    public static void main(String[] args) throws IOException {
        int violaciones = 0;
        for (Regla regla : REGLAS) {
            try (Stream<Path> fuentes = Files.walk(Path.of(regla.carpeta()))) {
                for (Path p : fuentes.filter(f -> f.toString().endsWith(".java")).toList()) {
                    for (String linea : Files.readAllLines(p)) {
                        if (regla.prohibidos().stream().anyMatch(linea.trim()::startsWith)) {
                            System.out.println("VIOLACIÓN: " + p.getFileName() + " -> " + linea.trim());
                            violaciones++;
                        }
                    }
                }
            }
        }
        if (violaciones > 0) System.exit(1);
        System.out.println("OK: dominio y aplicación no dependen de capas externas");
    }
}
