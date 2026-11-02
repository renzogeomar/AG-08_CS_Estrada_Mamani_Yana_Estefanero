package ag10.dominio;

import java.time.Instant;

/** Tarea pendiente de la outbox: reintentar el cobro de una reserva. */
public class TareaPago {
    private final String reservaId;
    private int intentos = 0;
    private Instant proximoIntento;
    private boolean completada = false;

    public TareaPago(String reservaId, Instant proximoIntento) {
        this.reservaId = reservaId;
        this.proximoIntento = proximoIntento;
    }

    public String reservaId() { return reservaId; }
    public int intentos() { return intentos; }
    public Instant proximoIntento() { return proximoIntento; }
    public boolean completada() { return completada; }

    public void reprogramar(Instant cuando) { intentos++; proximoIntento = cuando; }
    public void completar() { completada = true; }
}
