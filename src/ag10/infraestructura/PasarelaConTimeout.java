package ag10.infraestructura;

import ag10.dominio.*;
import java.math.BigDecimal;
import java.time.Duration;
import java.util.concurrent.*;

/** Decorador: corta la espera a la pasarela tras un tiempo máximo (táctica: tiempo de espera). */
public class PasarelaConTimeout implements PasarelaPago {
    private final PasarelaPago real;
    private final Duration limite;
    private final ExecutorService ejecutor = Executors.newVirtualThreadPerTaskExecutor();

    public PasarelaConTimeout(PasarelaPago real, Duration limite) {
        this.real = real;
        this.limite = limite;
    }

    @Override
    public ResultadoCobro cobrar(String clave, BigDecimal monto) throws PasarelaNoDisponibleException {
        Future<ResultadoCobro> llamada = ejecutor.submit(() -> real.cobrar(clave, monto));
        try {
            return llamada.get(limite.toMillis(), TimeUnit.MILLISECONDS);
        } catch (TimeoutException e) {
            llamada.cancel(true);
            throw new PasarelaNoDisponibleException("Timeout de " + limite.toMillis() + " ms", e);
        } catch (ExecutionException e) {
            if (e.getCause() instanceof PasarelaNoDisponibleException p) throw p;
            throw new PasarelaNoDisponibleException("Error en la pasarela", e.getCause());
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new PasarelaNoDisponibleException("Interrumpido", e);
        }
    }
}
