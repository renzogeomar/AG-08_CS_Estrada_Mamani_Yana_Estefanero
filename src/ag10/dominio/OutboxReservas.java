package ag10.dominio;

import java.time.Instant;
import java.util.List;

/**
 * Puerto de la outbox transaccional. En producción (JPA + PostgreSQL) la reserva y la tarea
 * se guardan en UNA sola transacción; por eso el método es atómico.
 */
public interface OutboxReservas {
    void guardarAtomico(Reserva reserva, TareaPago tarea);
    List<TareaPago> tareasVencidas(Instant ahora);
}
