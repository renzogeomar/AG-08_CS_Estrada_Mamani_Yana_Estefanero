workspace "RutaColca" "Modelo C4 de RutaColca - Grupo N.º" {

    !identifiers hierarchical

    model {
        // PASO 2 - Personas: un rol humano por elemento
        turista = person "Turista" "TODO: describa al usuario en una oración."
        // TODO: operador de agencia, guia de turismo, administrador

        // PASO 2 - El sistema en estudio (una sola caja en el contexto)
        ruta = softwareSystem "RutaColca" "TODO: qué ofrece al negocio." {
            // PASO 3 - Contenedores: aplicaciones y almacenes de datos
            // nombre = container "Nombre" "Responsabilidad" "Tecnologia"
            // TODO: web del turista, portal de agencias, API, base de datos
        }

        // PASO 2 - Sistemas externos (etiqueta "Externo")
        // TODO: pasarela de pagos, WhatsApp Business, sistema de AUTOCOLCA

        // Relaciones: origen -> destino "Verbo + preposición" "Protocolo"
        // TODO: complete las relaciones de los pasos 2 y 3
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

        // PASO 4 - dynamic ruta "Dinamico" "Reservar y pagar un tour" { ... }

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
