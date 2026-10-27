workspace "RutaColca" "Modelo C4 de RutaColca - Grupo N.º __" {

    !identifiers hierarchical

    model {
        // PASO 1 y 2 · Personas
        turista = person "Turista" "Visitante que busca tours al valle del Colca, reserva una salida y paga en línea."
        operador = person "Operador de agencia" "Persona de una agencia de Arequipa o Chivay que publica tours y registra reservas."
        guia = person "Guía de turismo" "Acompaña a los grupos. Recibe el itinerario y la lista del grupo por WhatsApp."
        admin = person "Administrador" "Aprueba a las agencias que se registran y revisa las ventas."

        // ==========================================
        // PASO 2 y 3: Sistema en estudio y Contenedores (ADR-001)
        // ==========================================
        ruta = softwareSystem "RutaColca" "Plataforma para publicar, reservar y pagar tours al valle del Colca con validación de boletos." {
            web = container "Web del turista" "Permite buscar tours, registrar el boleto turístico, reservar salidas y pagar en línea." "React (SPA)"
            portal = container "Portal de agencias" "Permite publicar tours con fechas y cupos, gestionar reservas, aprobar agencias y ver reportes." "React (PWA)"
            api = container "API" "Expone la lógica de negocio de tours, reservas, validación de boletos, pagos y notificaciones." "Java 21, Spring Boot"
            bd = container "Base de datos" "Almacena datos de agencias, tours, fechas de salida, cupos, reservas y registros de ventas." "PostgreSQL 16"
        // AGREGADO POR CHRISTIAN: Reto sin conexión
        almacenLocal = container "Almacenamiento Local" "Guarda temporalmente las reservas presenciales de la agencia cuando se pierde la conexión." "IndexedDB / Navegador"
        }

        // PASO 2 · Relaciones del contexto (sin protocolo)
        turista -> ruta "Busca tours, reserva y paga en"
        operador -> ruta "Publica tours y registra reservas en"
        admin -> ruta "Aprueba agencias y revisa ventas en"
        ruta -> pasarela "Cobra las reservas en"
        ruta -> autocolca "Valida el boleto turístico en"
        ruta -> whatsapp "Envía itinerarios por"
        whatsapp -> guia "Entrega mensajes a"

        // PASO 3 · Relaciones entre contenedores (con protocolo)
        turista -> ruta.web "Busca tours y paga reservas en" "HTTPS"
        operador -> ruta.portal "Publica tours y registra reservas en" "HTTPS"
        admin -> ruta.portal "Aprueba agencias y consulta ventas en" "HTTPS"
        ruta.web -> ruta.api "Envía búsquedas y reservas a" "JSON/HTTPS"
        ruta.portal -> ruta.api "Envía tours y reservas a" "JSON/HTTPS"
        ruta.api -> ruta.bd "Lee y escribe tours y reservas en" "JDBC"
        ruta.api -> pasarela "Cobra las reservas en" "HTTPS"
        ruta.api -> autocolca "Valida el boleto turístico en" "HTTPS"
        ruta.api -> whatsapp "Envía itinerarios por" "HTTPS"

        ruta.web -> ruta.api "Solicita catálogo, registro de reservas y pagos a" "JSON/HTTPS"
        
        // Relación del Reto sin conexión (Christian)
        ruta.portal -> ruta.almacenLocal "Lee y escribe reservas offline en caché mediante" "JavaScript API"
        
        // RELACIÓN MODIFICADA PARA LA SINCRONIZACIÓN
        ruta.portal -> ruta.api "Gestiona tours, cupos, agencias y sincroniza reservas pendientes mediante" "JSON/HTTPS"
        
        ruta.api -> ruta.bd "Lee y escribe registros de tours, reservas y ventas en" "JDBC"

        ruta.api -> autocolca "Valida el número de boleto turístico en" "HTTPS"
        ruta.api -> pasarela "Procesa el cobro de la reserva en" "HTTPS"
        ruta.api -> whatsapp "Envía el itinerario y la lista del grupo por" "HTTPS"

        whatsapp -> guia "Entrega mensajes con el itinerario y lista de pasajeros a" "HTTPS"
        
        // ==========================================
        // PASO 7: Entorno de Despliegue (Aporte de Rodrigo adaptado)
        // ==========================================
        deploymentEnvironment "Produccion" {
            deploymentNode "Dispositivo móvil del turista" "Dispositivo desde el que el turista consulta y reserva." "Android / iOS" {
                containerInstance ruta.web
            }
            tablet = deploymentNode "Tablet de la agencia" "Dispositivo de la agencia" "Android / iOS" {
                navegador = deploymentNode "Navegador web" "Navegador de la tablet" "Chrome" {
                    portal = containerInstance ruta.portal
                    almacen = containerInstance ruta.almacen
                }
            }
            nube = deploymentNode "Proveedor cloud" "Infraestructura en la nube" "Región sa-east-1" {
                balanceador = infrastructureNode "Balanceador de carga" "Termina TLS y reparte el tráfico HTTPS." "Balanceador gestionado"
                vm = deploymentNode "VM Ubuntu 24.04" "Máquina virtual que ejecuta la API con Docker" "Ubuntu 24.04, Docker" "" 2 {
                    api = containerInstance ruta.api
                }
                bdgestionada = deploymentNode "BD gestionada" "Servicio de base de datos administrado" "PostgreSQL 16" {
                    bd = containerInstance ruta.bd
                }
            }
            externos = deploymentNode "Servicios externos" "Proveedores de terceros" "Internet" {
                pasarelaInst = softwareSystemInstance pasarela
                autocolcaInst = softwareSystemInstance autocolca
                whatsappInst = softwareSystemInstance whatsapp
            }
        }

        // Relaciones entre nodos: van fuera del bloque del entorno
        produccion.celular.navegador.web -> produccion.nube.balanceador "Envía las peticiones a" "HTTPS"
        produccion.tablet.navegador.portal -> produccion.nube.balanceador "Envía las peticiones a" "HTTPS"
        produccion.nube.balanceador -> produccion.nube.vm.api "Reenvía las peticiones a" "HTTP"
    }

    views {
        systemContext ruta "Contexto" "Diagrama de contexto de RutaColca" {
            title "Diagrama de contexto de RutaColca"
            include *
            include guia
            autolayout lr
        }

        container ruta "Contenedores" "Diagrama de contenedores de RutaColca" {
            title "Diagrama de contenedores de RutaColca"
            include *
            include guia
            exclude ruta.almacen
            exclude "relationship.tag==Sincronizacion"
            autolayout tb
        }

        // PASO 4 · Dinámico. Se valida el boleto ANTES de cobrar.
        dynamic ruta "Dinamico" "Reservar y pagar un tour" {
            title "Diagrama dinámico: Reservar y pagar un tour (HU-02 y HU-03)"
            turista -> ruta.web "Elige la salida, ingresa su boleto y confirma el pago"
            ruta.web -> ruta.api "Envía la reserva y el número de boleto"
            ruta.api -> autocolca "Valida el boleto turístico"
            ruta.api -> pasarela "Cobra el monto de la reserva"
            ruta.api -> ruta.bd "Guarda la reserva como CONFIRMADA"
            ruta.api -> whatsapp "Envía el itinerario y la lista del grupo"
            autolayout tb
        }

        // PASO 7 · Despliegue
        deployment ruta "Produccion" "DespliegueProduccion" "Despliegue de RutaColca en producción" {
            title "Despliegue de RutaColca en producción"
            include *
            autolayout lr
        }

        // PASO 8 · Segunda vista de contenedores (reto sin conexión)
        container ruta "ContenedoresReto" "Contenedores de RutaColca con trabajo sin conexión" {
            title "Diagrama de contenedores de RutaColca con trabajo sin conexión"
            include *
            include guia
            autolayout tb
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
            element "Externo" {
                background #8C8C8C
                color #ffffff
            }
            element "Database" {
                shape Cylinder
            }
            element "Nuevo" {
                stroke #C65D00
                strokeWidth 6
            }
            relationship "Sincronizacion" {
                color #C65D00
                thickness 4
            }
        }
    }
}
