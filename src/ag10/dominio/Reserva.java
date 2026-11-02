package ag10.dominio;

import java.math.BigDecimal;
import java.time.Instant;

/** Reserva de un tour. El id sirve también como clave de idempotencia del cobro. */
public class Reserva {
    private final String id;
    private final BigDecimal monto;
    private final Instant creadaEn;
    private EstadoReserva estado = EstadoReserva.PENDIENTE_PAGO;

    public Reserva(String id, BigDecimal monto, Instant creadaEn) {
        this.id = id;
        this.monto = monto;
        this.creadaEn = creadaEn;
    }

    public String id() { return id; }
    public BigDecimal monto() { return monto; }
    public Instant creadaEn() { return creadaEn; }
    public EstadoReserva estado() { return estado; }

    public void confirmar() { cambiarA(EstadoReserva.CONFIRMADA); }
    public void rechazar()  { cambiarA(EstadoReserva.RECHAZADA); }
    public void expirar()   { cambiarA(EstadoReserva.EXPIRADA); }

    private void cambiarA(EstadoReserva nuevo) {
        if (estado != EstadoReserva.PENDIENTE_PAGO)
            throw new IllegalStateException("La reserva " + id + " ya está " + estado);
        estado = nuevo;
    }
}
