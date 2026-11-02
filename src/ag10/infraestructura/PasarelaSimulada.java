package ag10.infraestructura;

import ag10.dominio.*;
import java.math.BigDecimal;
import java.util.*;

/** Adaptador en memoria que simula la pasarela: normal, caída, lenta o "cobra pero no responde". */
public class PasarelaSimulada implements PasarelaPago {
    public enum Modo { NORMAL, CAIDA, LENTA, COBRA_Y_NO_RESPONDE, RECHAZA }

    private volatile Modo modo = Modo.NORMAL;
    private volatile long demoraMs = 0;
    private final Set<String> clavesCobradas = new HashSet<>();
    private int capturas = 0;          // cobros realmente efectuados
    private int llamadasFallidas = 0;  // veces que la pasarela no respondió

    public void modo(Modo nuevo) { this.modo = nuevo; }
    public void demoraMs(long ms) { this.demoraMs = ms; }
    public synchronized int capturas() { return capturas; }
    public synchronized int llamadasFallidas() { return llamadasFallidas; }

    @Override
    public ResultadoCobro cobrar(String clave, BigDecimal monto) throws PasarelaNoDisponibleException {
        switch (modo) {
            case CAIDA -> { registrarFallo(); throw new PasarelaNoDisponibleException("Pasarela caída"); }
            case LENTA -> {
                try { Thread.sleep(demoraMs); }
                catch (InterruptedException e) { Thread.currentThread().interrupt(); }
            }
            case COBRA_Y_NO_RESPONDE -> {
                capturar(clave);
                registrarFallo();
                throw new PasarelaNoDisponibleException("Cobro realizado pero la respuesta se perdió");
            }
            case RECHAZA -> { return ResultadoCobro.RECHAZADO; }
            default -> { }
        }
        capturar(clave);
        return ResultadoCobro.APROBADO;
    }

    /** Idempotencia: la misma clave nunca se cobra dos veces. */
    private synchronized void capturar(String clave) {
        if (clavesCobradas.add(clave)) capturas++;
    }

    private synchronized void registrarFallo() { llamadasFallidas++; }
}
