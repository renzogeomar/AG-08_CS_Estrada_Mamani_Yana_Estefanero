package ag10.infraestructura;

import ag10.dominio.*;
import java.util.*;

public class RepositorioReservasEnMemoria implements RepositorioReservas {
    private final Map<String, Reserva> datos = new LinkedHashMap<>();
    @Override public synchronized void guardar(Reserva r) { datos.put(r.id(), r); }
    @Override public synchronized Optional<Reserva> buscar(String id) { return Optional.ofNullable(datos.get(id)); }
    @Override public synchronized List<Reserva> todas() { return new ArrayList<>(datos.values()); }
}
