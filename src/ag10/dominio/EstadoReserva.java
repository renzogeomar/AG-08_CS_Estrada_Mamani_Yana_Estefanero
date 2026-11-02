package ag10.dominio;

/** Estados de una reserva en el flujo de pago (escenario E2). */
public enum EstadoReserva {
    PENDIENTE_PAGO,   // la pasarela no respondió: la reserva quedó guardada y espera el reintento
    CONFIRMADA,       // el cobro fue aprobado
    RECHAZADA,        // la pasarela respondió y rechazó el cobro (no se reintenta)
    EXPIRADA          // pasó el tiempo máximo de espera sin lograr cobrar
}
