workspace "RutaColca" "Modelo C4 de RutaColca - Grupo AG-08" {

    !identifiers hierarchical

    model {
        turista = person "Turista" "Busca tours, reserva una salida y paga en línea."
        operador = person "Operador de agencia" "Publica tours y administra las reservas de su agencia."
        guia = person "Guía de turismo" "Recibe por WhatsApp el itinerario y la lista del grupo."
        administrador = person "Administrador" "Aprueba agencias y consulta reportes de ventas."

        // PASO 2 - El sistema en estudio (una sola caja en el contexto)
        ruta = softwareSystem "RutaColca" "Plataforma del consorcio para publicar tours, gestionar reservas y coordinar su operación." {
            webTurista = container "Web del turista" "Permite buscar tours, seleccionar salidas, reservar y pagar." "React (SPA)"
            portalAgencias = container "Portal de agencias" "Permite publicar tours y gestionar salidas, cupos y reservas." "React (PWA)"
            api = container "API" "Aplica las reglas del negocio y coordina reservas e integraciones externas." "Java 21 / Spring Boot"
            baseDatos = container "Base de datos" "Almacena tours, salidas, cupos y reservas; no guarda datos de tarjetas." "PostgreSQL 16"
        }

        pasarela = softwareSystem "Pasarela de pagos" "Procesa pagos en línea sin compartir los datos de las tarjetas con RutaColca." {
            tags "Externo"
        }
        whatsapp = softwareSystem "WhatsApp Business" "Canal externo para entregar itinerarios y listas a los guías." {
            tags "Externo"
        }
        autocolca = softwareSystem "Sistema de AUTOCOLCA" "Sistema externo que valida boletos turísticos." {
            tags "Externo"
        }

        turista -> ruta "Busca tours, reserva salidas y paga en"
        operador -> ruta "Publica tours y administra reservas en"
        guia -> ruta "Recibe itinerarios y listas coordinados por"
        administrador -> ruta "Aprueba agencias y consulta reportes en"
        ruta -> pasarela "Procesa los cobros de las reservas mediante"
        ruta -> whatsapp "Envía itinerarios y listas de grupos mediante"
        ruta -> autocolca "Valida boletos turísticos con"

        turista -> ruta.webTurista "Busca tours y reserva salidas" "HTTPS"
        ruta.webTurista -> ruta.api "Consulta disponibilidad y solicita reservas" "JSON/HTTPS"
        operador -> ruta.portalAgencias "Publica tours y gestiona reservas" "HTTPS"
        administrador -> ruta.portalAgencias "Aprueba agencias y consulta reportes" "HTTPS"
        ruta.portalAgencias -> ruta.api "Gestiona tours, cupos y reservas" "JSON/HTTPS"
        ruta.api -> ruta.baseDatos "Lee y registra tours, salidas y reservas" "JDBC"
        ruta.api -> pasarela "Cobra reservas confirmadas" "HTTPS"
        ruta.api -> autocolca "Valida el boleto turístico" "HTTPS"
        ruta.api -> whatsapp "Solicita el envío de itinerarios y listas" "HTTPS"
        whatsapp -> guia "Entrega itinerarios y listas de grupos" "Canal de WhatsApp"
        ruta.api -> ruta.webTurista "Devuelve el resultado de la reserva" "JSON/HTTPS"

        deploymentEnvironment "Produccion" {
            deploymentNode "Dispositivo móvil del turista" "Dispositivo desde el que el turista consulta y reserva." "Android / iOS" {
                containerInstance ruta.webTurista
            }

            deploymentNode "Tablet o PC de la agencia" "Dispositivo de operación de la agencia." "Navegador web" {
                containerInstance ruta.portalAgencias
            }

            deploymentNode "Proveedor cloud" "Aloja los servicios centrales de RutaColca." "Proveedor cloud" {
                loadBalancer = infrastructureNode "Balanceador de carga" "Distribuye las solicitudes hacia las instancias de la API." "Balanceo HTTPS"

                apiVmOne = deploymentNode "VM Ubuntu 1" "Primera instancia para atender solicitudes de la API." "Ubuntu + Docker" {
                    containerInstance ruta.api
                }

                apiVmTwo = deploymentNode "VM Ubuntu 2" "Segunda instancia para atender picos de demanda en temporada alta." "Ubuntu + Docker" {
                    containerInstance ruta.api
                }

                deploymentNode "PostgreSQL 16 gestionado" "Servicio de base de datos administrado por el proveedor cloud." "PostgreSQL 16" {
                    containerInstance ruta.baseDatos
                }
            }
        }

        loadBalancer -> apiVmOne "Distribuye solicitudes HTTPS hacia"
        loadBalancer -> apiVmTwo "Distribuye solicitudes HTTPS hacia"
    }

    views {
        systemContext ruta "Contexto" "Diagrama de contexto de RutaColca" {
            include *
            autolayout lr
        }

        container ruta "Contenedores" "Diagrama de contenedores de RutaColca" {
            include *
            autolayout tb
        }

        dynamic ruta "Dinamico" "Reservar y pagar un tour" {
            turista -> ruta.webTurista "Selecciona una salida e ingresa su boleto"
            ruta.webTurista -> ruta.api "Solicita validar el boleto y reservar la salida"
            ruta.api -> autocolca "Valida el boleto turístico"
            ruta.api -> pasarela "Cobra la reserva si el boleto es válido y hay cupo"
            ruta.api -> ruta.baseDatos "Registra la reserva confirmada"
            ruta.api -> ruta.webTurista "Devuelve la confirmación de la reserva"
            ruta.api -> whatsapp "Solicita el envío del itinerario y la lista al guía"
            autolayout lr
        }

        deployment ruta "Produccion" "Despliegue de RutaColca en producción" {
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
        }
    }
}
