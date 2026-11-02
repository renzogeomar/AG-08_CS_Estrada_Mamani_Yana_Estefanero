package ag10.dominio;

import java.math.BigDecimal;

/**
 * Puerto de salida hacia la pasarela de pagos (Yape, tarjeta, PayPal...).
 * La clave de idempotencia garantiza que reintentar no cobre dos veces.
 */
public interface PasarelaPago {
    ResultadoCobro cobrar(String claveIdempotencia, BigDecimal monto) throws PasarelaNoDisponibleException;
}
