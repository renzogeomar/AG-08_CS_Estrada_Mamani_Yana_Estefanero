workspace "RutaColca" "Modelo C4 de RutaColca - Grupo N.º __" {

    !identifiers hierarchical

    model {
        // PASO 1 y 2 · Personas
        turista = person "Turista" "Visitante que busca tours al valle del Colca, reserva una salida y paga en línea."
        operador = person "Operador de agencia" "Persona de una agencia de Arequipa o Chivay que publica tours y registra reservas."
        guia = person "Guía de turismo" "Acompaña a los grupos. Recibe el itinerario y la lista del grupo por WhatsApp."
        admin = person "Administrador" "Aprueba a las agencias que se registran y revisa las ventas."

        // PASO 2 · Sistemas externos (etiqueta "Externo")
        pasarela = softwareSystem "Pasarela de pagos" "Cobra con tarjeta o billetera móvil. RutaColca no guarda datos de tarjetas." "Externo"
        autocolca = softwareSystem "Sistema de AUTOCOLCA" "Emite y valida el boleto turístico del Colca (supuesto didáctico, API HTTPS)." "Externo"
        whatsapp = softwareSystem "WhatsApp Business" "Mensajería para enviar avisos a los guías." "Externo"

        // PASO 2 y 3 · El sistema en estudio y sus contenedores (ADR-001)
        ruta = softwareSystem "RutaColca" "Permite publicar tours del valle del Colca, reservarlos y pagarlos en línea." {
            web = container "Web del turista" "Búsqueda de tours, reserva y pago en línea." "React (SPA)"
            portal = container "Portal de agencias" "Publicación de tours, registro de reservas y administración." "React (PWA)"
            api = container "API" "Reglas de negocio de tours, reservas, pagos y avisos." "Java 21, Spring Boot"
            bd = container "Base de datos" "Agencias, tours, salidas y reservas." "PostgreSQL 16" "Database"
            // PASO 8 · Reto sin conexión (ADR-002)
            almacen = container "Almacén local de reservas" "Guarda las reservas hechas sin internet hasta sincronizarlas." "IndexedDB" "Database,Nuevo"
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

        // PASO 8 · Relaciones nuevas del reto
        ruta.portal -> ruta.almacen "Guarda reservas sin conexión en" "IndexedDB API"
        ruta.portal -> ruta.api "Sincroniza reservas pendientes con" "JSON/HTTPS" "Sincronizacion"

        // PASO 7 · Despliegue en producción
        produccion = deploymentEnvironment "Produccion" {
            celular = deploymentNode "Celular del turista" "Dispositivo del turista" "Android / iOS" {
                navegador = deploymentNode "Navegador web" "Navegador del celular" "Chrome / Safari" {
                    web = containerInstance ruta.web
                }
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
