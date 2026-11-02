package ag10.infraestructura;

import ag10.dominio.*;
import java.time.Instant;
import java.util.*;

/** Outbox en memoria: guarda reserva y tarea juntas, como lo haría una transacción JPA. */
public class OutboxEnMemoria implements OutboxReservas {
    private final RepositorioReservas reservas;
    private final List<TareaPago> tareas = new ArrayList<>();

    public OutboxEnMemoria(RepositorioReservas reservas) { this.reservas = reservas; }

    @Override
    public synchronized void guardarAtomico(Reserva reserva, TareaPago tarea) {
        reservas.guardar(reserva);
        tareas.add(tarea);
    }

    @Override
    public synchronized List<TareaPago> tareasVencidas(Instant ahora) {
        return tareas.stream()
            .filter(t -> !t.completada() && !t.proximoIntento().isAfter(ahora))
            .toList();
    }

    public synchronized long pendientes() { return tareas.stream().filter(t -> !t.completada()).count(); }
}
