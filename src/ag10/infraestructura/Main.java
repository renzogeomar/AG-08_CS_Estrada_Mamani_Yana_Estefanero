package ag10.infraestructura;

import ag10.aplicacion.*;
import ag10.dominio.*;
import java.math.BigDecimal;
import java.time.*;

/** Demostración del escenario E2: la pasarela cae 15 minutos y ninguna reserva se pierde. */
public class Main {
    public static void main(String[] args) {
        RelojManual reloj = new RelojManual(Instant.parse("2026-07-15T14:00:00Z"));
        PasarelaSimulada pasarela = new PasarelaSimulada();
        RepositorioReservasEnMemoria reservas = new RepositorioReservasEnMemoria();
        OutboxEnMemoria outbox = new OutboxEnMemoria(reservas);
        NotificadorEnMemoria notificador = new NotificadorEnMemoria(reloj);
        ReservarTour reservar = new ReservarTour(reservas, outbox, pasarela, notificador, reloj);
        ProcesadorTareas procesador = new ProcesadorTareas(outbox, reservas, pasarela, notificador, reloj,
            Duration.ofHours(2), Duration.ofMinutes(5));

        System.out.println("t=00  La pasarela cae. Llegan 3 reservas.");
        pasarela.modo(PasarelaSimulada.Modo.CAIDA);
        for (int i = 1; i <= 3; i++) {
            Reserva r = reservar.ejecutar("R-00" + i, new BigDecimal("120.00"));
            System.out.println("      " + r.id() + " -> " + r.estado());
        }
        for (int minuto = 1; minuto <= 25; minuto++) {
            reloj.avanzar(Duration.ofMinutes(1));
            if (minuto == 15) {
                pasarela.modo(PasarelaSimulada.Modo.NORMAL);
                System.out.println("t=15  La pasarela se recupera.");
            }
            int resueltas = procesador.procesar();
            if (resueltas > 0) System.out.printf("t=%02d  El procesador confirma %d reservas.%n", minuto, resueltas);
        }
        reservas.todas().forEach(r -> System.out.println("      " + r.id() + " -> " + r.estado()));
        System.out.println("Cobros efectuados: " + pasarela.capturas() + " (uno por reserva, sin duplicados)");
    }
}
