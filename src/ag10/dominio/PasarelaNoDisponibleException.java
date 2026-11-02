package ag10.dominio;

/** La pasarela no respondió a tiempo o devolvió un error de infraestructura. */
public class PasarelaNoDisponibleException extends Exception {
    public PasarelaNoDisponibleException(String mensaje) { super(mensaje); }
    public PasarelaNoDisponibleException(String mensaje, Throwable causa) { super(mensaje, causa); }
}
