package ag10.prueba;

import ag10.aplicacion.*;
import ag10.dominio.*;
import ag10.infraestructura.*;
import java.math.BigDecimal;
import java.time.*;
import java.util.*;

/**
 * Pruebas del escenario E2 con adaptadores en memoria (sin framework: se ejecuta con java a secas).
 * Cada prueba es un método; el runner del final las ejecuta y falla el proceso si alguna falla.
 */
public class PruebaPagoConPasarelaCaida {
    static final Instant INICIO = Instant.parse("2026-07-15T14:00:00Z");
    static final BigDecimal MONTO = new BigDecimal("120.00");

    // ---------------------------------------------------------------- pruebas

    static void caida15MinutosNoPierdeReservasYConfirmaEn30Min() {
        PasarelaSimulada pasarela = new PasarelaSimulada();
        Montaje m = new Montaje(pasarela, Duration.ofHours(2));
        pasarela.modo(PasarelaSimulada.Modo.CAIDA);

        for (int i = 1; i <= 5; i++) {
            Reserva r = m.reservar.ejecutar("R-" + i, MONTO);
            afirmar(r.estado() == EstadoReserva.PENDIENTE_PAGO, "la reserva R-" + i + " debe quedar pendiente");
        }
        afirmar(m.reservas.todas().size() == 5, "las 5 reservas deben estar guardadas (0 perdidas)");
        afirmar(m.outbox.pendientes() == 5, "debe haber 5 tareas en la outbox");

        Instant recuperacion = null;
        for (int minuto = 1; minuto <= 45; minuto++) {
            m.reloj.avanzar(Duration.ofMinutes(1));
            if (minuto == 15) { pasarela.modo(PasarelaSimulada.Modo.NORMAL); recuperacion = m.reloj.instant(); }
            m.procesador.procesar();
        }

        for (Reserva r : m.reservas.todas())
            afirmar(r.estado() == EstadoReserva.CONFIRMADA, r.id() + " debe quedar CONFIRMADA");
        afirmar(m.notificador.enviados().size() == 5, "deben enviarse 5 confirmaciones");
        for (Map.Entry<String, Instant> e : m.notificador.enviados().entrySet()) {
            long minutos = Duration.between(recuperacion, e.getValue()).toMinutes();
            afirmar(minutos <= 30, e.getKey() + " se confirmó " + minutos + " min tras la recuperación (máx. 30)");
        }
        afirmar(pasarela.capturas() == 5, "cada reserva se cobra exactamente una vez");
        // El tope de espera evita bombardear la pasarela: 5 reservas x 5 intentos = 25 llamadas como máximo.
        afirmar(pasarela.llamadasFallidas() <= 5 * 5 + 5, "los reintentos deben espaciarse (backoff); llamadas fallidas: "
            + pasarela.llamadasFallidas());
    }

    static void cobroAmbiguoNoDuplicaElCobro() {
        PasarelaSimulada pasarela = new PasarelaSimulada();
        Montaje m = new Montaje(pasarela, Duration.ofHours(2));
        pasarela.modo(PasarelaSimulada.Modo.COBRA_Y_NO_RESPONDE);   // cobra, pero la respuesta se pierde

        Reserva r = m.reservar.ejecutar("R-AMBIGUA", MONTO);
        afirmar(r.estado() == EstadoReserva.PENDIENTE_PAGO, "sin respuesta, la reserva queda pendiente");
        afirmar(pasarela.capturas() == 1, "el cobro sí se efectuó una vez");

        pasarela.modo(PasarelaSimulada.Modo.NORMAL);
        for (int minuto = 1; minuto <= 5; minuto++) { m.reloj.avanzar(Duration.ofMinutes(1)); m.procesador.procesar(); }

        afirmar(m.reservas.buscar("R-AMBIGUA").orElseThrow().estado() == EstadoReserva.CONFIRMADA, "se confirma al reintentar");
        afirmar(pasarela.capturas() == 1, "la clave de idempotencia evita el doble cobro");
    }

    static void timeoutCortaLaEsperaYDejaLaReservaPendiente() {
        PasarelaSimulada pasarela = new PasarelaSimulada();
        pasarela.modo(PasarelaSimulada.Modo.LENTA);
        pasarela.demoraMs(3000);                                   // la pasarela tarda 3 s
        Montaje m = new Montaje(new PasarelaConTimeout(pasarela, Duration.ofMillis(300)), pasarela, Duration.ofHours(2));

        long t0 = System.nanoTime();
        Reserva r = m.reservar.ejecutar("R-LENTA", MONTO);
        long ms = (System.nanoTime() - t0) / 1_000_000;

        afirmar(r.estado() == EstadoReserva.PENDIENTE_PAGO, "tras el timeout la reserva queda pendiente");
        afirmar(ms < 1500, "la API no espera a la pasarela lenta (tardó " + ms + " ms, el timeout era 300 ms)");
    }

    static void reservaExpiraSiNuncaSeLograCobrar() {
        PasarelaSimulada pasarela = new PasarelaSimulada();
        Montaje m = new Montaje(pasarela, Duration.ofHours(2));
        pasarela.modo(PasarelaSimulada.Modo.CAIDA);
        m.reservar.ejecutar("R-EXPIRA", MONTO);

        for (int minuto = 1; minuto <= 140; minuto++) { m.reloj.avanzar(Duration.ofMinutes(1)); m.procesador.procesar(); }

        afirmar(m.reservas.buscar("R-EXPIRA").orElseThrow().estado() == EstadoReserva.EXPIRADA,
            "pasadas 2 h sin cobrar, la reserva expira y libera el cupo");
        afirmar(pasarela.capturas() == 0, "no se cobró nada");
    }

    static void rechazoDeLaPasarelaNoSeReintenta() {
        PasarelaSimulada pasarela = new PasarelaSimulada();
        Montaje m = new Montaje(pasarela, Duration.ofHours(2));
        pasarela.modo(PasarelaSimulada.Modo.RECHAZA);

        Reserva r = m.reservar.ejecutar("R-RECHAZADA", MONTO);

        afirmar(r.estado() == EstadoReserva.RECHAZADA, "un rechazo explícito es definitivo");
        afirmar(m.outbox.pendientes() == 0, "no se crea tarea de reintento");
    }

    // ---------------------------------------------------------------- montaje y runner

    /** Cablea los casos de uso con adaptadores en memoria. */
    static class Montaje {
        final RelojManual reloj = new RelojManual(INICIO);
        final RepositorioReservasEnMemoria reservas = new RepositorioReservasEnMemoria();
        final OutboxEnMemoria outbox = new OutboxEnMemoria(reservas);
        final NotificadorEnMemoria notificador = new NotificadorEnMemoria(reloj);
        final ReservarTour reservar;
        final ProcesadorTareas procesador;

        Montaje(PasarelaSimulada pasarela, Duration tiempoMaximo) { this(pasarela, pasarela, tiempoMaximo); }

        Montaje(PasarelaPago paraApi, PasarelaSimulada paraProcesador, Duration tiempoMaximo) {
            reservar = new ReservarTour(reservas, outbox, paraApi, notificador, reloj);
            procesador = new ProcesadorTareas(outbox, reservas, paraProcesador, notificador, reloj,
                tiempoMaximo, Duration.ofMinutes(5));
        }
    }

    static void afirmar(boolean condicion, String mensaje) {
        if (!condicion) throw new AssertionError(mensaje);
    }

    public static void main(String[] args) {
        Map<String, Runnable> pruebas = new LinkedHashMap<>();
        pruebas.put("caida de 15 min: 0 reservas perdidas y confirmación <= 30 min", PruebaPagoConPasarelaCaida::caida15MinutosNoPierdeReservasYConfirmaEn30Min);
        pruebas.put("cobro ambiguo (cobra pero no responde): sin doble cobro", PruebaPagoConPasarelaCaida::cobroAmbiguoNoDuplicaElCobro);
        pruebas.put("timeout corta la espera y deja la reserva pendiente", PruebaPagoConPasarelaCaida::timeoutCortaLaEsperaYDejaLaReservaPendiente);
        pruebas.put("reserva expira tras 2 h sin cobro", PruebaPagoConPasarelaCaida::reservaExpiraSiNuncaSeLograCobrar);
        pruebas.put("rechazo explícito no se reintenta", PruebaPagoConPasarelaCaida::rechazoDeLaPasarelaNoSeReintenta);

        int fallidas = 0;
        for (var p : pruebas.entrySet()) {
            try { p.getValue().run(); System.out.println("OK      " + p.getKey()); }
            catch (Throwable e) { fallidas++; System.out.println("FALLÓ   " + p.getKey() + " -> " + e.getMessage()); }
        }
        System.out.println(fallidas == 0 ? "Todas las pruebas pasaron." : fallidas + " prueba(s) fallaron.");
        System.exit(fallidas == 0 ? 0 : 1);
    }
}
