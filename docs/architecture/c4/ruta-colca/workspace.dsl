workspace "RutaColca" "Modelo C4 de RutaColca - Grupo AG-08" {

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
            almacenLocal = container "Almacén local de reservas" "Guarda reservas pendientes de sincronizar en Chivay." "IndexedDB"
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
        turista -> ruta.web "Busca tours, registra boleto y paga reservas en" "HTTPS"
        operador -> ruta.portal "Publica tours con cupos y registra reservas en" "HTTPS"
        admin -> ruta.portal "Aprueba agencias y consulta reportes de ventas en" "HTTPS"

        ruta.web -> ruta.api "Solicita catálogo, registro de reservas y pagos a" "JSON/HTTPS"
        
        // NUEVA RELACIÓN PARA EL RETO SIN CONEXIÓN
        ruta.portal -> ruta.almacenLocal "Guarda reservas pendientes en" "IndexedDB"
        
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

            deploymentNode "Tablet o PC de la agencia" "Dispositivo de operación de la agencia." "Navegador web" {
                containerInstance ruta.portal
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
                    containerInstance ruta.bd
                }
            }
        }

        loadBalancer -> apiVmOne "Distribuye solicitudes HTTPS hacia" "HTTPS"
        loadBalancer -> apiVmTwo "Distribuye solicitudes HTTPS hacia" "HTTPS"
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

        // PASO 4: Vista Dinámica
        dynamic ruta "Dinamico" "Reservar y pagar un tour (HU-02 y HU-03)" {
            turista -> ruta.web "1. Selecciona fecha de salida, ingresa número de boleto turístico y confirma el pago"
            ruta.web -> ruta.api "2. Envía solicitud de reserva y pago (POST /reservas)"
            ruta.api -> autocolca "3. Valida el número de boleto turístico antes de procesar el cobro"
            ruta.api -> pasarela "4. Procesa el cobro del tour con tarjeta o billetera móvil"
            ruta.api -> ruta.bd "5. Registra la reserva confirmada y descuenta el cupo disponible"
            ruta.api -> whatsapp "6. Programa el envío del itinerario y lista actualizada del grupo"
            autolayout tb
        }

        // PASO 7: Vista de Despliegue
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
            element "Database" {
                shape Cylinder
            }
        }
    }
}