workspace "RutaColca" "Modelo C4 de RutaColca - Parte A" {

    !identifiers hierarchical

    model {
        // ==========================================
        // PASO 2: Personas (Roles humanos)
        // ==========================================
        turista = person "Turista" "Visitante que busca tours al Colca, reserva salidas y paga en línea."
        operador = person "Operador de agencia" "Personal de agencia en Arequipa o Chivay que publica tours y gestiona reservas."
        admin = person "Administrador" "Encargado del consorcio que aprueba agencias registradas y revisa reportes de ventas."
        guia = person "Guía de turismo" "Guía oficial que recibe por WhatsApp el itinerario y la lista del grupo asignado."

        // ==========================================
        // PASO 2 y 3: Sistema en estudio y Contenedores (ADR-001)
        // ==========================================
        ruta = softwareSystem "RutaColca" "Plataforma para publicar, reservar y pagar tours al valle del Colca con validación de boletos." {
            web = container "Web del turista" "Permite buscar tours, registrar el boleto turístico, reservar salidas y pagar en línea." "React (SPA)"
            portal = container "Portal de agencias" "Permite publicar tours con fechas y cupos, gestionar reservas, aprobar agencias y ver reportes." "React (PWA)"
            api = container "API" "Expone la lógica de negocio de tours, reservas, validación de boletos, pagos y notificaciones." "Java 21, Spring Boot"
            bd = container "Base de datos" "Almacena datos de agencias, tours, fechas de salida, cupos, reservas y registros de ventas." "PostgreSQL 16"
        }

        // ==========================================
        // PASO 2: Sistemas externos
        // ==========================================
        pasarela = softwareSystem "Pasarela de pagos" "Procesa cobros en línea con tarjeta de crédito/débito y billetera móvil." "Externo"
        whatsapp = softwareSystem "WhatsApp Business" "Servicio de mensajería para enviar el itinerario y lista de pasajeros a los guías." "Externo"
        autocolca = softwareSystem "Sistema de AUTOCOLCA" "Emite el boleto turístico del Colca y expone un servicio para validar su vigencia." "Externo"

        // ==========================================
        // PASO 2 y 3: Relaciones (Unidireccionales y con protocolo)
        // ==========================================
        // Personas -> Contenedores de RutaColca (Structurizr infiere el nivel de Contexto automáticamente)
        turista -> ruta.web "Busca tours, registra boleto y paga reservas en" "HTTPS"
        operador -> ruta.portal "Publica tours con cupos y registra reservas en" "HTTPS"
        admin -> ruta.portal "Aprueba agencias y consulta reportes de ventas en" "HTTPS"

        // Comunicación interna entre contenedores
        ruta.web -> ruta.api "Solicita catálogo, registro de reservas y pagos a" "JSON/HTTPS"
        ruta.portal -> ruta.api "Gestiona tours, cupos, agencias y reportes mediante" "JSON/HTTPS"
        ruta.api -> ruta.bd "Lee y escribe registros de tours, reservas y ventas en" "JDBC"

        // Contenedor API -> Sistemas externos
        ruta.api -> autocolca "Valida el número de boleto turístico en" "HTTPS"
        ruta.api -> pasarela "Procesa el cobro de la reserva en" "HTTPS"
        ruta.api -> whatsapp "Envía el itinerario y la lista del grupo por" "HTTPS"

        // Notificación final hacia el guía
        whatsapp -> guia "Entrega mensajes con el itinerario y lista de pasajeros a" "HTTPS"
    }

    views {
        // Vista 1: Diagrama de Contexto
        systemContext ruta "Contexto" "Diagrama de contexto de RutaColca" {
            include *
            autolayout lr
        }

        // Vista 2: Diagrama de Contenedores
        container ruta "Contenedores" "Diagrama de contenedores de RutaColca" {
            include *
            autolayout tb
        }

        // PASO 4 - Vista 3: Diagrama Dinámico (HU-02 y HU-03)
        // Decisión de diseño: Se valida el boleto con AUTOCOLCA ANTES de cobrar para evitar cargos y reembolsos si el boleto es inválido.
        dynamic ruta "Dinamico" "Reservar y pagar un tour (HU-02 y HU-03)" {
            turista -> ruta.web "1. Selecciona fecha de salida, ingresa número de boleto turístico y confirma el pago"
            ruta.web -> ruta.api "2. Envía solicitud de reserva y pago (POST /reservas)"
            ruta.api -> autocolca "3. Valida el número de boleto turístico antes de procesar el cobro"
            ruta.api -> pasarela "4. Procesa el cobro del tour con tarjeta o billetera móvil"
            ruta.api -> ruta.bd "5. Registra la reserva confirmada y descuenta el cupo disponible"
            ruta.api -> whatsapp "6. Programa el envío del itinerario y lista actualizada del grupo"
            autolayout tb
        }

        styles {
            element "Person" {
                shape Person
                background #0B3D62
                color #ffffff
            }
            element "Software System" {
                background #185E8B
                color #ffffff
            }
            element "Container" {
                background #0E7D73
                color #ffffff
            }
            element "Externo" {
                background #8C8C8C
                color #ffffff
            }
            element "Database" {
                shape Cylinder
            }
        }
    }
}
