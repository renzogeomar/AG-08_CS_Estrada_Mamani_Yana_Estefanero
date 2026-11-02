#!/usr/bin/env python3
"""Genera los diagramas de AG-10 (Graphviz). Uso: python3 generar.py  (requiere 'dot' instalado)."""
import subprocess, textwrap, html, pathlib

OUT = pathlib.Path(__file__).resolve().parent.parent
PERSONA, SISTEMA, CONT, COMP, EXT = "#0B3D62", "#1B5E8B", "#0E7D73", "#758F3A", "#8C8C8C"
NARANJA = "#E8892B"

def wrap(t, n=30):
    return "<BR/>".join(html.escape(l) for l in textwrap.wrap(t, n))

def nodo(i, nombre, tipo, desc, color, nuevo=False, forma="box", ancho=30):
    borde = f'color="{NARANJA}", penwidth=4' if nuevo else f'color="{color}", penwidth=1.2'
    cuerpo = f'<BR/><FONT POINT-SIZE="10">{wrap(desc, ancho)}</FONT>' if desc else ''
    label = (f'<<B>{html.escape(nombre)}</B><BR/><FONT POINT-SIZE="9">[{html.escape(tipo)}]</FONT>' + cuerpo + '>')
    return (f'{i} [label={label}, shape={forma}, style="rounded,filled" , fillcolor="{color}", '
            f'fontcolor=white, {borde}, margin="0.18,0.12"];')

def render(nombre, dot):
    f = OUT / "fuentes" / f"{nombre}.dot"
    f.write_text(dot, encoding="utf-8")
    subprocess.run(["dot", "-Tpng", "-Gdpi=170", str(f), "-o", str(OUT / f"{nombre}.png")], check=True)

CAB = 'bgcolor=white; fontname="Arial"; pad=0.2; nodesep=0.45; ranksep=0.7; splines=true;'
ND = 'node [fontname="Arial", fontsize=12]; edge [fontname="Arial", fontsize=10, color="#555555", fontcolor="#333333", style=dashed, arrowsize=0.8];'
LEYENDA = ('leyenda [shape=plaintext, label=<<TABLE BORDER="0" CELLBORDER="1" CELLSPACING="0" CELLPADDING="4">'
           f'<TR><TD BGCOLOR="white" COLOR="{NARANJA}" BORDER="3"><FONT POINT-SIZE="10">Borde naranja: nuevo o modificado en AG-10</FONT></TD></TR></TABLE>>];')

# ---------------------------------------------------------------- 1. árbol de utilidad
def utilidad():
    hojas = [
        ("r", "Rendimiento", "e1", "E1  (A, M)\n2000 consultas simultáneas → p95 ≤ 1,5 s", False),
        ("d", "Disponibilidad", "e2", "E2  (A, A)\nPasarela caída 15 min → 0 reservas pagadas perdidas", True),
        ("s", "Seguridad", "e3", "E3  (A, B)\nTour de otra agencia → 100 % bloqueado y auditado", False),
        ("m", "Modificabilidad", "e4", "E4  (M, B)\nAceptar PayPal → ≤ 3 días-persona, 0 cambios en el dominio", False),
        ("i", "Interoperabilidad", "e5", "E5  (A, M)\nAUTOCOLCA caído → validar ≤ 2 h, 0 cobros inválidos", False),
    ]
    d = f'digraph G {{ rankdir=LR; {CAB} nodesep=0.25; ranksep=0.5; {ND} edge [arrowhead=none, style=solid, color="#7F7F7F", penwidth=1.2];\n'
    d += 'u [label=<<B>Utilidad de<BR/>RutaColca</B>>, shape=box, style="rounded,filled", fillcolor="#800000", color="#800000", fontcolor=white, fontsize=14];\n'
    for a, nom, e, txt, crit in hojas:
        d += f'{a} [label="{nom}", shape=box, style="rounded,filled", fillcolor="#E3EDF5", color="{SISTEMA}"];\n'
        fill, col = ("#FBEFD9", "#BA750D") if crit else ("#FFFFFF", "#BFBFBF")
        pw = 2.5 if crit else 1.2
        d += f'{e} [label="{txt}", shape=box, style="rounded,filled", fillcolor="{fill}", color="{col}", penwidth={pw}, fontsize=11];\n'
        d += f'u -> {a} -> {e};\n'
    d += '}'
    render("utilidad", d)

# ---------------------------------------------------------------- 2. escenario E2 (6 partes)
def escenario():
    def caja(i, titulo, cuerpo, color):
        return (f'{i} [label=<<B>{titulo}</B><BR/><FONT POINT-SIZE="10">{wrap(cuerpo, 19)}</FONT>>, shape=box, '
                f'style="rounded,filled", fillcolor="{color}", color="#7F7F7F", fontcolor="#1a1a1a", margin="0.15,0.1"];\n')
    d = f'digraph G {{ rankdir=LR; {CAB} nodesep=0.3; ranksep=0.45; {ND} edge [style=solid, color="#800000", penwidth=1.6];\n'
    d += caja("f", "Fuente", "Turista que paga una reserva en la web", "#E3EDF5")
    d += caja("e", "Estímulo", "La pasarela de pagos no responde durante 15 minutos", "#FBEFD9")
    d += caja("a", "Artefacto", "Módulo de pagos de la API, procesador de tareas y base de datos", "#E3EDF5")
    d += caja("n", "Entorno", "Temporada alta: ≈ 10 veces las reservas normales", "#F2F2F2")
    d += caja("r", "Respuesta", "Guarda la reserva como pendiente y reintenta el cobro hasta confirmarla", "#E3F1EA")
    d += caja("m", "Medida", "0 reservas perdidas; confirmación ≤ 30 min tras la recuperación", "#E3F1EA")
    d += 'f -> e -> a -> r -> m;\n n -> a [style=dashed, color="#7F7F7F", arrowhead=none, constraint=false];\n{rank=same; a; n}\n}'
    render("escenario", d)

# ---------------------------------------------------------------- 3. arquitectura propuesta (contenedores)
def contenedores():
    d = f'digraph G {{ rankdir=TB; {CAB} {ND}\n'
    d += nodo("tur", "Turista", "Persona", "Visitante que reserva tours al valle del Colca.", PERSONA, ancho=26) + "\n"
    d += nodo("age", "Operador de agencia", "Persona", "Publica tours y gestiona reservas.", PERSONA, ancho=26) + "\n"
    d += nodo("adm", "Administrador de RutaColca", "Persona", "Aprueba agencias y revisa reportes.", PERSONA, ancho=26) + "\n"
    d += 'subgraph cluster_r { label="RutaColca"; fontname="Arial"; fontsize=13; color="#1B5E8B"; style=rounded; margin=18;\n'
    d += nodo("web", "Web del turista", "React (SPA)", "Catálogo de tours, reserva y pago.", CONT) + "\n"
    d += nodo("por", "Portal de agencias", "React (PWA)", "Publica tours y registra reservas; funciona sin conexión.", CONT) + "\n"
    d += nodo("api", "API", "Java 21, Spring Boot", "Monolito modular hexagonal. Cobra con timeout y, si falla, deja la reserva pendiente.", CONT, nuevo=True, ancho=34) + "\n"
    d += nodo("wor", "Procesador de tareas", "Java 21, Spring Boot (perfil worker)", "Reintenta cobros pendientes cada minuto y envía confirmaciones.", CONT, nuevo=True, ancho=34) + "\n"
    d += nodo("bd", "Base de datos", "PostgreSQL 16", "Tours, reservas, pagos y tareas pendientes (outbox).", CONT, nuevo=True, forma="cylinder", ancho=28) + "\n"
    d += '{rank=same; web; por}\n{rank=same; api; wor}\n}\n'
    d += nodo("pas", "Pasarela de pagos", "Sistema externo", "Procesa pagos con tarjeta y billetera móvil.", EXT) + "\n"
    d += nodo("wha", "WhatsApp Business", "Sistema externo", "Envía itinerarios y confirmaciones.", EXT) + "\n"
    d += nodo("aut", "Sistema de AUTOCOLCA", "Sistema externo", "Emite y valida el boleto turístico.", EXT) + "\n"
    d += LEYENDA + "\n"
    d += 'tur -> web [label="Busca tours, reserva y paga\\n[HTTPS]"];\n age -> por [label="Publica tours y\\nregistra reservas [HTTPS]"];\n adm -> por [label="Aprueba agencias [HTTPS]"];\n'
    d += 'web -> api [label="Reservas y pagos\\n[JSON/HTTPS]"];\n por -> api [label="Sincroniza\\n[JSON/HTTPS]"];\n'
    d += 'api -> bd [label="Guarda reserva y tarea en\\nuna transacción [JDBC]", color="#BA750D", fontcolor="#BA750D", penwidth=1.8];\n'
    d += 'wor -> bd [label="Lee tareas y actualiza\\nreservas [JDBC]", color="#BA750D", fontcolor="#BA750D", penwidth=1.8];\n'
    d += 'api -> pas [label="Cobra (timeout 5 s)\\n[HTTPS]", color="#BA750D", fontcolor="#BA750D", penwidth=1.8];\n'
    d += 'wor -> pas [label="Reintenta el cobro\\n[HTTPS]", color="#BA750D", fontcolor="#BA750D", penwidth=1.8];\n'
    d += 'wor -> wha [label="Envía confirmaciones\\ndiferidas [HTTPS]", color="#BA750D", fontcolor="#BA750D", penwidth=1.8];\n'
    d += 'api -> wha [label="Envía itinerarios\\n[HTTPS]"];\n api -> aut [label="Valida el boleto\\n[HTTPS]"];\n'
    d += 'leyenda -> aut [style=invis];\n}'
    render("c4-contenedores", d)

# ---------------------------------------------------------------- 4. componentes de la API
def componentes():
    d = f'digraph G {{ rankdir=TB; {CAB} {ND}\n'
    d += nodo("web", "Web del turista", "React (SPA)", "Catálogo de tours, reserva y pago.", CONT) + "\n"
    d += nodo("por", "Portal de agencias", "React (PWA)", "Publica tours y registra reservas.", CONT) + "\n"
    d += 'subgraph cluster_api { label="API · Java 21, Spring Boot"; fontname="Arial"; fontsize=13; color="#0E7D73"; style=rounded; margin=18;\n'
    d += nodo("con", "ReservasController", "Spring MVC", "Recibe POST /reservas y responde 201 (confirmada) o 202 (pago en proceso).", COMP, nuevo=True, ancho=32) + "\n"
    d += nodo("res", "ReservarTour", "Java (núcleo hexagonal)", "Caso de uso: crea la reserva, cobra y, si la pasarela falla, la deja pendiente.", COMP, nuevo=True, ancho=32) + "\n"
    d += nodo("ada", "AdaptadorPasarela", "Resilience4j", "Implementa el puerto PasarelaPago: timeout 5 s, circuit breaker y clave de idempotencia.", COMP, nuevo=True, ancho=32) + "\n"
    d += nodo("out", "RepositorioOutbox", "Spring Data JPA", "Guarda la reserva y la tarea de cobro en una sola transacción.", COMP, nuevo=True, ancho=32) + "\n"
    d += '}\n'
    d += nodo("bd", "Base de datos", "PostgreSQL 16", "Reservas, pagos y tareas pendientes.", CONT, forma="cylinder", ancho=28) + "\n"
    d += nodo("pas", "Pasarela de pagos", "Sistema externo", "Procesa pagos con tarjeta y billetera móvil.", EXT) + "\n"
    d += 'web -> con [label="[JSON/HTTPS]"];\n por -> con [label="[JSON/HTTPS]"];\n con -> res [label="Invoca"];\n'
    d += 'res -> ada [label="Cobra con"];\n res -> out [label="Guarda la reserva\\npendiente con"];\n'
    d += 'ada -> pas [label="Intenta el cobro en\\n[HTTPS]"];\n out -> bd [label="Lee y escribe en\\n[JDBC]"];\n}'
    render("c4-componentes", d)

# ---------------------------------------------------------------- 5. vista dinámica del escenario
def dinamica():
    d = f'digraph G {{ rankdir=LR; {CAB} nodesep=0.5; ranksep=1.0; {ND} edge [style=solid, color="#444444", fontsize=10, arrowsize=0.9];\n'
    d += nodo("tur", "Turista", "Persona", "Reserva y paga un tour.", PERSONA, ancho=22) + "\n"
    d += nodo("web", "Web del turista", "React (SPA)", "", CONT, ancho=22) + "\n"
    d += nodo("api", "API", "Spring Boot", "", CONT, ancho=22) + "\n"
    d += nodo("bd", "Base de datos", "PostgreSQL 16", "", CONT, forma="cylinder", ancho=22) + "\n"
    d += nodo("wor", "Procesador de tareas", "Spring Boot (worker)", "", CONT, ancho=22) + "\n"
    d += nodo("pas", "Pasarela de pagos", "Externo", "", EXT, ancho=22) + "\n"
    d += nodo("wha", "WhatsApp Business", "Externo", "", EXT, ancho=22) + "\n"
    pasos = [
        ("tur", "web", "1. Reserva y paga"),
        ("web", "api", "2. POST /reservas"),
        ("api", "pas", "3. Intenta cobrar (timeout 5 s): no responde"),
        ("api", "bd", "4. Guarda la reserva PENDIENTE_PAGO\\ny la tarea en la outbox (1 transacción)"),
        ("wor", "bd", "5. Lee la tarea pendiente (cada minuto,\\ncon espera exponencial)"),
        ("wor", "pas", "6. Reintenta el cobro con la misma clave\\n(la pasarela ya responde: aprobado)"),
        ("wor", "bd", "7. Marca la reserva CONFIRMADA\\ny cierra la tarea"),
        ("wor", "wha", "8. Envía la confirmación al turista"),
    ]
    for a, b, t in pasos:
        d += f'{a} -> {b} [label="{t}"];\n'
    d += '{rank=same; tur; web}\n}'
    render("c4-dinamica", d)

# ---------------------------------------------------------------- 6. despliegue
def despliegue():
    d = f'digraph G {{ rankdir=LR; {CAB} {ND} compound=true; ranksep=0.9;\n'
    d += 'subgraph cluster_cloud { label="Proveedor cloud · región sa-east-1"; fontname="Arial"; fontsize=13; color="#7F7F7F"; style=rounded; margin=20;\n'
    d += 'lb [label=<<B>Balanceador de carga</B><BR/><FONT POINT-SIZE="9">[Load balancer gestionado]</FONT><BR/><FONT POINT-SIZE="10">Termina TLS y reparte<BR/>el tráfico HTTPS.</FONT>>, shape=box, style="rounded,filled", fillcolor="white", color="#7F7F7F", margin="0.18,0.12"];\n'
    for n in (1, 2):
        d += f'subgraph cluster_vm{n} {{ label="VM Ubuntu 24.04 · Docker  (instancia {n} de 2)"; fontname="Arial"; fontsize=11; color="#0E7D73"; style=rounded; margin=14;\n'
        d += nodo(f"api{n}", "API", "contenedor Docker", "Perfil web.", CONT, ancho=20) + "\n"
        d += nodo(f"wor{n}", "Procesador de tareas", "contenedor Docker", "Perfil worker (misma imagen).", CONT, nuevo=True, ancho=20) + "\n"
        d += '}\n'
    d += 'subgraph cluster_bd { label="BD gestionada · PostgreSQL 16"; fontname="Arial"; fontsize=11; color="#0E7D73"; style=rounded; margin=14;\n'
    d += nodo("pri", "Base de datos (primaria)", "PostgreSQL 16", "Reservas y outbox.", CONT, forma="cylinder", ancho=20) + "\n"
    d += nodo("rep", "Réplica", "PostgreSQL 16", "Lecturas.", CONT, forma="cylinder", ancho=20) + "\n"
    d += '}\n}\n'
    d += LEYENDA + "\n"
    d += 'lb -> api1 [label="HTTPS"]; lb -> api2 [label="HTTPS"];\n'
    d += 'api1 -> pri [label="JDBC"]; api2 -> pri [label="JDBC"]; wor1 -> pri [label="JDBC", color="#BA750D"]; wor2 -> pri [label="JDBC\\nSKIP LOCKED", color="#BA750D", fontcolor="#BA750D"];\n'
    d += 'pri -> rep [label="replicación", arrowhead=none];\n'
    d += '}'
    render("c4-despliegue", d)

# ---------------------------------------------------------------- 7. estados de la reserva
def estados():
    d = f'digraph G {{ rankdir=LR; {CAB} nodesep=0.5; ranksep=0.9; {ND} edge [style=solid, color="#444444", fontsize=10];\n'
    d += 'ini [shape=circle, label="", width=0.2, style=filled, fillcolor="#333333"];\n'
    for n, c in (("PENDIENTE_PAGO", "#FBEFD9"), ("CONFIRMADA", "#E3F1EA"), ("RECHAZADA", "#F5DEDE"), ("EXPIRADA", "#EDEDED")):
        d += f'{n} [shape=box, style="rounded,filled", fillcolor="{c}", color="#7F7F7F", fontsize=12];\n'
    d += 'ini -> PENDIENTE_PAGO [label="pasarela no\\nresponde"];\n'
    d += 'ini -> CONFIRMADA [label="cobro aprobado\\nal primer intento"];\n'
    d += 'ini -> RECHAZADA [label="cobro rechazado"];\n'
    d += 'PENDIENTE_PAGO -> PENDIENTE_PAGO [label="reintento fallido\\n(espera 1, 2, 4, 5 min…)"];\n'
    d += 'PENDIENTE_PAGO -> CONFIRMADA [label="reintento aprobado"];\n'
    d += 'PENDIENTE_PAGO -> RECHAZADA [label="reintento rechazado"];\n'
    d += 'PENDIENTE_PAGO -> EXPIRADA [label="pasan 2 h sin cobrar"];\n}'
    render("estados-reserva", d)

# ---------------------------------------------------------------- 8. alternativas
def alternativas():
    c = lambda i, t, col="#E3EDF5", bord="#7F7F7F", pw=1.2: f'{i} [label=<{t}>, shape=box, style="rounded,filled", fillcolor="{col}", color="{bord}", penwidth={pw}, margin="0.15,0.1"];\n'
    # A
    d = f'digraph G {{ rankdir=LR; {CAB} nodesep=0.35; ranksep=0.5; {ND} edge [style=solid, color="#444444"];\n'
    d += c("api", "<B>API</B><BR/><FONT POINT-SIZE=\"10\">ReservarTour + timeout 5 s<BR/>+ circuit breaker</FONT>")
    d += c("pas", "<B>Pasarela</B><BR/><FONT POINT-SIZE=\"10\">externa</FONT>", "#EDEDED")
    d += c("bd", "<B>PostgreSQL</B><BR/><FONT POINT-SIZE=\"10\">reserva PENDIENTE_PAGO<BR/>+ tarea (outbox)<BR/>misma transacción</FONT>", "#E3F1EA")
    d += c("wor", "<B>Procesador de tareas</B><BR/><FONT POINT-SIZE=\"10\">@Scheduled cada 60 s<BR/>espera exponencial, tope 5 min</FONT>", "#FBEFD9", "#BA750D", 2.5)
    d += c("wha", "<B>WhatsApp</B>", "#EDEDED")
    d += 'api -> pas [label="1. cobra"]; api -> bd [label="2. si falla: guarda"]; wor -> bd [label="3. lee tareas"]; wor -> pas [label="4. reintenta\\n(misma clave)"]; wor -> wha [label="5. confirma"];\n{rank=same; pas; bd}\n}'
    render("alternativa-a", d)
    # B
    d = f'digraph G {{ rankdir=TB; {CAB} nodesep=0.5; ranksep=0.6; {ND} edge [style=solid, color="#444444"];\n'
    d += c("api", "<B>API</B><BR/><FONT POINT-SIZE=\"10\">ReservarTour + timeout 5 s</FONT>")
    d += c("pas", "<B>Pasarela</B><BR/><FONT POINT-SIZE=\"10\">externa</FONT>", "#EDEDED")
    d += c("bd", "<B>PostgreSQL</B><BR/><FONT POINT-SIZE=\"10\">reserva PENDIENTE_PAGO</FONT>", "#E3F1EA")
    d += c("mq", "<B>Broker de mensajes</B><BR/><FONT POINT-SIZE=\"10\">RabbitMQ/SQS gestionado<BR/>cola + cola de errores (DLQ)</FONT>", "#FBEFD9", "#BA750D", 2.5)
    d += c("con", "<B>Consumidor de pagos</B><BR/><FONT POINT-SIZE=\"10\">reintenta con la cola</FONT>", "#FBEFD9", "#BA750D", 2.5)
    d += 'api -> pas [label="1. cobra"]; api -> bd [label="2a. guarda"]; api -> mq [label="2b. publica PagoPendiente\\n(segunda escritura)", color="#B22222", fontcolor="#B22222"]; mq -> con [label="3. entrega"]; con -> pas [label="4. reintenta"]; con -> bd [label="5. confirma"];\n}'
    render("alternativa-b", d)

if __name__ == "__main__":
    for f in (utilidad, escenario, contenedores, componentes, dinamica, despliegue, estados, alternativas):
        f()
    print("Diagramas generados en", OUT)
