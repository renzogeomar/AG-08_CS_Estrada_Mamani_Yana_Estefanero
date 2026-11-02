package ag10.aplicacion;

import ag10.dominio.*;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.Duration;

/**
 * Caso de uso: reservar y cobrar. Si la pasarela no responde, NO se pierde la reserva:
 * queda en PENDIENTE_PAGO junto con una tarea en la outbox (tácticas: timeout + degradación + transacción).
 */
public class ReservarTour {
    static final Duration PRIMER_REINTENTO = Duration.ofMinutes(1);

    private final RepositorioReservas reservas;
    private final OutboxReservas outbox;
    private final PasarelaPago pasarela;
    private final Notificador notificador;
    private final Clock reloj;

    public ReservarTour(RepositorioReservas reservas, OutboxReservas outbox,
                        PasarelaPago pasarela, Notificador notificador, Clock reloj) {
        this.reservas = reservas;
        this.outbox = outbox;
        this.pasarela = pasarela;
        this.notificador = notificador;
        this.reloj = reloj;
    }

    public Reserva ejecutar(String reservaId, BigDecimal monto) {
        Reserva reserva = new Reserva(reservaId, monto, reloj.instant());
        try {
            ResultadoCobro resultado = pasarela.cobrar(reservaId, monto);
            if (resultado == ResultadoCobro.APROBADO) {
                reserva.confirmar();
                notificador.confirmar(reservaId);
            } else {
                reserva.rechazar();
            }
            reservas.guardar(reserva);
        } catch (PasarelaNoDisponibleException e) {
            // Degradación: se acepta la reserva y se difiere el cobro.
            outbox.guardarAtomico(reserva, new TareaPago(reservaId, reloj.instant().plus(PRIMER_REINTENTO)));
        }
        return reserva;
    }
}
