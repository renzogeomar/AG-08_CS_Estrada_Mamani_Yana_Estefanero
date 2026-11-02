package ag10.dominio;

import java.util.List;
import java.util.Optional;

public interface RepositorioReservas {
    void guardar(Reserva reserva);
    Optional<Reserva> buscar(String id);
    List<Reserva> todas();
}
