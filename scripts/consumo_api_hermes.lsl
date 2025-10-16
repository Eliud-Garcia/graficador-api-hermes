// ------------------- CONFIGURACIÓN -------------------
string SENSOR_ID = "f1225f50-18ad-4d03-9e6b-6c0a3823c5ee";
float INTERVALO_CONSULTA = 5.0;
float UMBRAL_VALOR = 100.0;

// --- Colores ---
vector COLOR_ROJO = <1.0, 0.0, 0.0>;
vector COLOR_AZUL = <0.0, 0.0, 1.0>;
vector COLOR_DESCONECTADO = <0.5, 0.5, 0.5>;
vector COLOR_ERROR = <1.0, 1.0, 0.0>;

//inclinacion
float MAX_ANGULO = 26.0; // Máximo ángulo de inclinación (correspondiente a tus ejemplos)
rotation ROT_HORIZONTAL; // Rotación inicial (horizontal)

// --- Variables de control ---
integer conectado = FALSE;
key usuario;
integer canalDialogo = -12345;
integer handleEscuchaDialogo;
key g_http_request_id;

// ------------------- FUNCIÓN PARA HACER LA PETICIÓN A LA API (NUEVO) -------------------
// Creamos esta función para no repetir código y poder llamarla desde varios sitios.
hacerPeticionAPI()
{
    if (conectado)
    {
        string url = "https://hermes-api-jt8k.onrender.com/api/sensor/data/" + SENSOR_ID + "?limit=1";
        llOwnerSay("Consultando API...");
        g_http_request_id = llHTTPRequest(url, [HTTP_METHOD, "GET"], "");
    }
}

// ------------------- FUNCIÓN EXTRAER VALUE (de tu código) -------------------
string extraerValue(string json)
{
    integer posValue = llSubStringIndex(json, "\"value\":");
    if (posValue == -1) return "-1";
    posValue += llStringLength("\"value\":");
    string resto = llGetSubString(json, posValue, -1);
    integer finComa = llSubStringIndex(resto, ",");
    integer finLlave = llSubStringIndex(resto, "}");
    integer fin;
    if (finComa != -1 && (finLlave == -1 || finComa < finLlave))
        fin = finComa - 1;
    else
        fin = finLlave - 1;
    string valor = llStringTrim(llGetSubString(resto, 0, fin), STRING_TRIM);
    return valor;
}

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


// ------------------- ESTADO PRINCIPAL DEL SCRIPT -------------------
default
{
    state_entry()
    {
        llOwnerSay("Script de color por API iniciado. Toca el objeto para conectar/desconectar.");
        llSetColor(COLOR_DESCONECTADO, ALL_SIDES);
        ROT_HORIZONTAL = llEuler2Rot(<0.0, 270.0, 0.0> * DEG_TO_RAD);
        llSetRot(ROT_HORIZONTAL);
        
    }

    touch_start(integer total_number)
    {
        usuario = llDetectedKey(0);
        if (handleEscuchaDialogo) llListenRemove(handleEscuchaDialogo);
        handleEscuchaDialogo = llListen(canalDialogo, "", usuario, "");

        if (conectado)
        {
            llDialog(usuario, "El sistema está CONECTADO a la API.\n¿Quieres desconectarte?", ["Desconectar"], canalDialogo);
        }
        else
        {
            llDialog(usuario, "El sistema está DESCONECTADO.\n¿Quieres conectarte a la API?", ["Conectar"], canalDialogo);
        }
    }

    listen(integer channel, string name, key id, string message)
    {
        if (channel == canalDialogo)
        {
            if (message == "Conectar")
            {
                conectado = TRUE;
                llOwnerSay("Conectado a la API. Iniciando consultas cada " + (string)INTERVALO_CONSULTA + " segundos.");
                llSetTimerEvent(INTERVALO_CONSULTA);
                
                // --- CORRECCIÓN AQUÍ ---
                // En lugar de llamar a timer(), llamamos a nuestra nueva función.
                hacerPeticionAPI();
            }
            else if (message == "Desconectar")
            {
                conectado = FALSE;
                llOwnerSay("Desconectado de la API. Consultas detenidas.");
                llSetTimerEvent(0.0);
                llSetColor(COLOR_DESCONECTADO, ALL_SIDES);
            }
            
            if (handleEscuchaDialogo) llListenRemove(handleEscuchaDialogo);
        }
    }

    timer()
    {
        // --- CORRECCIÓN AQUÍ ---
        // El evento timer() ahora simplemente llama a nuestra función.
        hacerPeticionAPI();
    }

    http_response(key request_id, integer status, list metadata, string body)
    {
        if (conectado && request_id == g_http_request_id)
        {
            if (status == 200)
            {
                string valor_str = extraerValue(body);
                if (valor_str != "-1")
                {
                    float valor_float = (float)valor_str;
                    llOwnerSay("Valor obtenido: " + valor_str);

                    if (valor_float > UMBRAL_VALOR)
                    {
                        llSetColor(COLOR_ROJO, ALL_SIDES);
                    }
                    else
                    {
                        llSetColor(COLOR_AZUL, ALL_SIDES);
                    }
                    integer lado = 0;
                    string lado_txt = "EQUILIBRIO";
                    if(valor_float == 0){
                        lado = 0;
                    }else if(valor_float < 0){
                        //derecha
                        lado = 1;
                        lado_txt = "DERECHA";
                    }else{
                        //izquierda
                        lado_txt = "IZQUIERDA";
                        lado = -1;
                    }
                    //ultimo_numero =  llFabs(ultimo_numero);
                
                    llOwnerSay("Número obtenido: " + (string)valor_float +
                                " ⇒ inclinación " + lado_txt);
                
                    rotation nuevaRot = calcularRotacion((float)valor_float, lado);
                    llSetRot(nuevaRot);
                
                   
                }
                else
                {
                    llOwnerSay("Error: No se pudo encontrar el 'value' en la respuesta JSON.");
                    llSetColor(COLOR_ERROR, ALL_SIDES);
                }
            }
            else
            {
                llOwnerSay("Error al consultar API. Código de estado: " + (string)status);
                llSetColor(COLOR_ERROR, ALL_SIDES);
            }
        }
    }
}