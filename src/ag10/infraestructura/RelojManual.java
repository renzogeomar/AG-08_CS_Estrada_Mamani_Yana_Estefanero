package ag10.infraestructura;

import java.time.*;

/** Reloj controlable para simular 15 minutos de caída sin esperar 15 minutos. */
public class RelojManual extends Clock {
    private Instant ahora;

    public RelojManual(Instant inicio) { this.ahora = inicio; }

    public void avanzar(Duration d) { ahora = ahora.plus(d); }

    @Override public ZoneId getZone() { return ZoneOffset.UTC; }
    @Override public Clock withZone(ZoneId zone) { return this; }
    @Override public Instant instant() { return ahora; }
}
