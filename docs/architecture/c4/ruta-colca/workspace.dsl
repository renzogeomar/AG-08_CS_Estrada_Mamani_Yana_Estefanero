workspace "RutaColca" "Modelo C4 de RutaColca tras la iteración de ADD de AG-10 (escenario E2: pasarela de pagos caída). Construcción de Software, EPIS-UNSA 2026-B." {

    !identifiers hierarchical

    model {
        turista = person "Turista" "Visitante nacional o extranjero que reserva tours al valle del Colca."
        agencia = person "Operador de agencia" "Personal de una agencia de Arequipa o Chivay que publica tours y gestiona reservas."
        admin = person "Administrador de RutaColca" "Aprueba agencias y revisa reportes de ventas."

        ruta = softwareSystem "RutaColca" "Publicación de tours, reservas y pagos en línea para el valle del Colca." {
            web = container "Web del turista" "Catálogo de tours, reserva y pago." "React (SPA)" "Web"
            portal = container "Portal de agencias" "Publica tours, registra reservas presenciales y asigna guías; funciona sin conexión." "React (PWA) + Service Worker" "Web"

            // AG-10: ahora cobra con timeout y deja la reserva pendiente si la pasarela falla
            api = container "API" "Reglas de negocio de tours, reservas, pagos y sincronización. Monolito modular con arquitectura hexagonal (ADR-001)." "Java 21, Spring Boot" "AG-10" {
                controller = component "ReservasController" "Recibe POST /reservas y responde 201 (confirmada) o 202 (pago en proceso)." "Spring MVC" "AG-10"
                reservar = component "ReservarTour" "Caso de uso: crea la reserva, cobra y, si la pasarela falla, la deja en PENDIENTE_PAGO." "Java (núcleo hexagonal)" "AG-10"
                adaptador = component "AdaptadorPasarela" "Implementa el puerto PasarelaPago con timeout de 5 s, circuit breaker y clave de idempotencia." "Resilience4j" "AG-10"
                outbox = component "RepositorioOutbox" "Guarda la reserva y la tarea de cobro pendiente en una sola transacción." "Spring Data JPA" "AG-10"
            }

            // AG-10: contenedor nuevo
            worker = container "Procesador de tareas" "Reintenta los cobros pendientes con espera exponencial y envía las confirmaciones diferidas." "Java 21, Spring Boot (perfil worker, @Scheduled)" "AG-10"
            // AG-10: se agrega la tabla outbox
            bd = container "Base de datos" "Agencias, tours, salidas, reservas, pagos y tareas pendientes (outbox)." "PostgreSQL 16" "Database,AG-10"
        }

        pasarela = softwareSystem "Pasarela de pagos" "Procesa pagos con tarjeta y billetera móvil." "Externo"
        whatsapp = softwareSystem "WhatsApp Business" "Mensajería para enviar itinerarios y confirmaciones." "Externo"
        autocolca = softwareSystem "Sistema de AUTOCOLCA" "Emite y valida el boleto turístico del Colca (integración supuesta en el caso)." "Externo"

        // ---- Relaciones de AG-08 (sin cambios)
        turista -> ruta.web "Busca tours, reserva y paga en" "HTTPS"
        agencia -> ruta.portal "Publica tours y registra reservas en" "HTTPS"
        admin -> ruta.portal "Aprueba agencias y revisa reportes en" "HTTPS"
        ruta.web -> ruta.api.controller "Envía reservas y pagos a" "JSON/HTTPS"
        ruta.portal -> ruta.api.controller "Sincroniza tours y reservas con" "JSON/HTTPS"
        ruta.api -> whatsapp "Envía itinerarios por" "HTTPS"
        ruta.api -> autocolca "Valida el boleto turístico en" "HTTPS"

        // ---- Relaciones nuevas de AG-10
        ruta.api.controller -> ruta.api.reservar "Invoca"
        ruta.api.reservar -> ruta.api.adaptador "Cobra con"
        ruta.api.reservar -> ruta.api.outbox "Guarda la reserva pendiente y su tarea con"
        ruta.api.adaptador -> pasarela "Intenta el cobro en" "HTTPS"
        ruta.api.outbox -> ruta.bd "Lee y escribe en" "JDBC"
        ruta.worker -> ruta.bd "Lee tareas pendientes y actualiza reservas en" "JDBC"
        ruta.worker -> pasarela "Reintenta cobros en" "HTTPS"
        ruta.worker -> whatsapp "Envía confirmaciones diferidas por" "HTTPS"

        produccion = deploymentEnvironment "Produccion" {
            cloud = deploymentNode "Proveedor cloud" "" "Región sa-east-1" {
                lb = infrastructureNode "Balanceador de carga" "Termina TLS y reparte el tráfico HTTPS." "Load balancer gestionado"
                vm = deploymentNode "VM Ubuntu 24.04" "" "Docker" "" 2 {
                    apiProd = containerInstance ruta.api
                    // AG-10: el procesador comparte las VM de la API (sin VM nueva)
                    workerProd = containerInstance ruta.worker
                }
                deploymentNode "BD gestionada" "" "PostgreSQL 16 (primaria + réplica)" {
                    containerInstance ruta.bd
                }
            }
        }
        produccion.cloud.lb -> produccion.cloud.vm.apiProd "Reenvía las peticiones a" "HTTPS"
    }

    views {
        container ruta "Contenedores" "Contenedores de RutaColca tras la iteración de ADD de AG-10." {
            include *
            autolayout tb
        }

        component ruta.api "Componentes" "Componentes de la API (hexagonal) que participan en el cobro de una reserva." {
            include *
            autolayout tb
        }

        dynamic ruta "PagoConPasarelaCaida" "Escenario E2: la pasarela no responde al pagar y la reserva se confirma después." {
            turista -> ruta.web "Reserva y paga"
            ruta.web -> ruta.api "Envía POST /reservas"
            ruta.api -> pasarela "Intenta cobrar (timeout de 5 s): no responde"
            ruta.api -> ruta.bd "Guarda la reserva PENDIENTE_PAGO y la tarea en la outbox (una transacción)"
            ruta.worker -> ruta.bd "Lee la tarea pendiente (cada minuto, con espera exponencial)"
            ruta.worker -> pasarela "Reintenta el cobro con la misma clave de idempotencia (aprobado)"
            ruta.worker -> ruta.bd "Marca la reserva CONFIRMADA y cierra la tarea"
            ruta.worker -> whatsapp "Envía la confirmación al turista"
            autolayout tb
        }

        deployment ruta produccion "Despliegue" "Despliegue de RutaColca en temporada alta: el procesador de tareas comparte las VM de la API." {
            include *
            autolayout lr
        }

        styles {
            element "Person" {
                shape Person
                background #0B3D62
                color #ffffff
            }
            element "Software System" {
                background #1B5E8B
                color #ffffff
            }
            element "Container" {
                background #0E7D73
                color #ffffff
            }
            element "Component" {
                background #758F3A
                color #ffffff
            }
            element "Database" {
                shape Cylinder
            }
            element "Web" {
                shape WebBrowser
            }
            element "Infrastructure Node" {
                background #ffffff
                color #262626
            }
            element "Externo" {
                background #8C8C8C
                color #ffffff
            }
            element "AG-10" {
                stroke #E8892B
                strokeWidth 6
            }
        }
    }
}
