package ag10.infraestructura;

import ag10.dominio.Notificador;
import java.time.Clock;
import java.time.Instant;
import java.util.*;

public class NotificadorEnMemoria implements Notificador {
    private final Clock reloj;
    private final Map<String, Instant> enviados = new LinkedHashMap<>();

    public NotificadorEnMemoria(Clock reloj) { this.reloj = reloj; }

    @Override public synchronized void confirmar(String reservaId) { enviados.put(reservaId, reloj.instant()); }
    public synchronized Map<String, Instant> enviados() { return new LinkedHashMap<>(enviados); }
}
