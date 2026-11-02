package ag10.aplicacion;

import ag10.dominio.*;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;

/**
 * Procesador de tareas (contenedor "Procesador de tareas" del C4): reintenta cobros pendientes
 * con espera exponencial y tope (táctica: reintento). Se invoca cada minuto (@Scheduled en producción).
 */
public class ProcesadorTareas {
    private final OutboxReservas outbox;
    private final RepositorioReservas reservas;
    private final PasarelaPago pasarela;
    private final Notificador notificador;
    private final Clock reloj;
    private final Duration tiempoMaximoPendiente;
    private final Duration topeEspera;

    public ProcesadorTareas(OutboxReservas outbox, RepositorioReservas reservas, PasarelaPago pasarela,
                            Notificador notificador, Clock reloj,
                            Duration tiempoMaximoPendiente, Duration topeEspera) {
        this.outbox = outbox;
        this.reservas = reservas;
        this.pasarela = pasarela;
        this.notificador = notificador;
        this.reloj = reloj;
        this.tiempoMaximoPendiente = tiempoMaximoPendiente;
        this.topeEspera = topeEspera;
    }

    /** Procesa las tareas vencidas y devuelve cuántas quedaron resueltas en esta pasada. */
    public int procesar() {
        Instant ahora = reloj.instant();
        int resueltas = 0;
        for (TareaPago tarea : outbox.tareasVencidas(ahora)) {
            Reserva reserva = reservas.buscar(tarea.reservaId()).orElseThrow();
            if (reserva.estado() != EstadoReserva.PENDIENTE_PAGO) { tarea.completar(); continue; }
            try {
                ResultadoCobro resultado = pasarela.cobrar(reserva.id(), reserva.monto());
                if (resultado == ResultadoCobro.APROBADO) {
                    reserva.confirmar();
                    notificador.confirmar(reserva.id());
                } else {
                    reserva.rechazar();
                }
                reservas.guardar(reserva);
                tarea.completar();
                resueltas++;
            } catch (PasarelaNoDisponibleException e) {
                if (Duration.between(reserva.creadaEn(), ahora).compareTo(tiempoMaximoPendiente) > 0) {
                    reserva.expirar();
                    reservas.guardar(reserva);
                    tarea.completar();
                    resueltas++;
                } else {
                    tarea.reprogramar(ahora.plus(esperaTras(tarea.intentos() + 1)));
                }
            }
        }
        return resueltas;
    }

    /** 1 min, 2 min, 4 min, ... hasta el tope. */
    Duration esperaTras(int intentos) {
        Duration espera = Duration.ofMinutes(1L << Math.min(intentos - 1, 20));
        return espera.compareTo(topeEspera) > 0 ? topeEspera : espera;
    }
}
