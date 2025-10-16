// 📊 Script: Balanza controlada por número aleatorio (API de prueba)
// El número recibido inclina la barra hacia izquierda o derecha.

string API_FUNCIONAL = "https://httpbin.org/uuid"; // API de números pseudoaleatorios
key http_request;
integer ultimo_numero = 0;

// ⚙️ Configuración base
float MAX_ANGULO = 26.0; // Máximo ángulo de inclinación (correspondiente a tus ejemplos)
rotation ROT_HORIZONTAL; // Rotación inicial (horizontal)

// 🔄 Calcula la rotación según número y dirección
rotation calcularRotacion(float inclinacion, integer lado)
{
    float y;

    if (lado == -1) // izquierda
        y = 270.0 + (MAX_ANGULO * (inclinacion / 100.0)); // hacia arriba (izquierda)
    else             // derecha
        y = 270.0 + (MAX_ANGULO * (inclinacion / 100.0)); // mismo ángulo en Y

    vector euler;

    if (lado == 1) // derecha
        euler = <180.0, y, 180.0>; // espejo en X y Z
    else
        euler = <0.0, y, 0.0>;     // normal

    return llEuler2Rot(euler * DEG_TO_RAD);
}

// 🔁 Inicio
default
{
    state_entry()
    {
        llOwnerSay("Iniciando balanza con API alternativa...");
        ROT_HORIZONTAL = llEuler2Rot(<0.0, 270.0, 0.0> * DEG_TO_RAD);
        llSetRot(ROT_HORIZONTAL);
        llSetColor(<0,1,0>, ALL_SIDES);
        llSetText("Esperando datos...", <1,1,1>, 1.0);
        llSetTimerEvent(5.0);
        http_request = llHTTPRequest(API_FUNCIONAL, [], "");
    }

    timer()
    {
        http_request = llHTTPRequest(API_FUNCIONAL, [], "");
    }

    http_response(key request_id, integer status, list metadata, string body)
    {
        if (request_id != http_request) return;

        if (status == 200)
        {
            // Tomar parte del UUID como número 0-99
            string uuid_part = llGetSubString(body, 16, 17);
            ultimo_numero = (integer)("0x" + uuid_part) % 100;

            integer lado = (ultimo_numero % 2 == 0) ? -1 : 1; // pares = izquierda, impares = derecha

            llOwnerSay("Número generado: " + (string)ultimo_numero +
                       " ⇒ inclinación " + ((lado == -1) ? "izquierda" : "derecha"));

            rotation nuevaRot = calcularRotacion((float)ultimo_numero, lado);
            llSetRot(nuevaRot);

            // Colores según lado
            if (lado == -1)
            {
                llSetColor(<0,1,0>, ALL_SIDES); // Verde = izquierda
                llSetText("← Izquierda (" + (string)ultimo_numero + ")", <0,1,0>, 1.0);
            }
            else
            {
                llSetColor(<1,0,0>, ALL_SIDES); // Rojo = derecha
                llSetText("→ Derecha (" + (string)ultimo_numero + ")", <1,0,0>, 1.0);
            }
        }
        else
        {
            llOwnerSay("Error API: " + (string)status);
            llSetColor(<1,1,0>, ALL_SIDES);
            llSetText("Error API: " + (string)status, <1,1,0>, 1.0);
        }
    }

    touch_start(integer total_number)
    {
        http_request = llHTTPRequest(API_FUNCIONAL, [], "");
    }
}
