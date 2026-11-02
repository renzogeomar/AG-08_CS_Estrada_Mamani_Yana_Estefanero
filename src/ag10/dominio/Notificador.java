package ag10.dominio;

/** Puerto de salida hacia WhatsApp Business. */
public interface Notificador {
    void confirmar(String reservaId);
}
