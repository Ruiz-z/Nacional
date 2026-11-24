#include <Arduino.h>
#include "logica.h"

// Pines de referencia. Los ESP32 de otras familias pueden requerir reasignación.
#if defined(ARDUINO_ARCH_ESP32)
constexpr uint8_t PIN_BLOQUEO = 18;
constexpr uint8_t PIN_ETIQUETADO = 19;
constexpr uint8_t PIN_CONFIRMAR = 21;
constexpr uint8_t PIN_CANCELAR = 22;
constexpr uint8_t PIN_TORQUE = 34;
constexpr uint8_t PIN_LED_ENERGIZADO = 25;
constexpr uint8_t PIN_LED_BLOQUEADO = 26;
constexpr uint8_t PIN_LED_FALLA = 27;
constexpr uint16_t MAXIMO_ADC = 4095;
#else
constexpr uint8_t PIN_BLOQUEO = 2;
constexpr uint8_t PIN_ETIQUETADO = 3;
constexpr uint8_t PIN_CONFIRMAR = 4;
constexpr uint8_t PIN_CANCELAR = 5;
constexpr uint8_t PIN_TORQUE = A0;
constexpr uint8_t PIN_LED_ENERGIZADO = 6;
constexpr uint8_t PIN_LED_BLOQUEADO = 7;
constexpr uint8_t PIN_LED_FALLA = 8;
constexpr uint16_t MAXIMO_ADC = 1023;
#endif

struct EntradaDigital {
    uint8_t pin;
    const char *control;
    bool interruptor;
    Antirrebote rebote;
};

EntradaDigital entradas[] = {
    {PIN_BLOQUEO, "bloqueo", true, {}},
    {PIN_ETIQUETADO, "etiquetado", true, {}},
    {PIN_CONFIRMAR, "confirmar", false, {}},
    {PIN_CANCELAR, "cancelar", false, {}},
};
constexpr uint8_t PINES_LED[] = {PIN_LED_ENERGIZADO, PIN_LED_BLOQUEADO, PIN_LED_FALLA};

PromedioTorque torque;
uint32_t secuencia = 0;
uint32_t ultimoLatido;
uint32_t ultimaMuestra;
uint32_t ultimoEventoTorque;
int ultimoTorque;

void emitir(const char *control, int valor, uint32_t ahora) {
    char linea[96];
    formatearEvento(linea, sizeof linea, control, valor, secuencia++, ahora);
    Serial.print(linea);
    Serial.write('\n');
}

void recibirLeds() {
    static char linea[96];
    static size_t longitud = 0;
    static bool descartar = false;

    // Limita el trabajo serial por ciclo para seguir leyendo los controles.
    for (uint8_t i = 0; i < 64 && Serial.available() > 0; ++i) {
        const int byteLeido = Serial.read();
        if (byteLeido == '\n') {
            linea[longitud] = '\0';
            OrdenLed orden;
            if (!descartar && parsearLed(linea, orden)) {
                digitalWrite(PINES_LED[orden.indice], orden.encender ? HIGH : LOW);
            }
            longitud = 0;
            descartar = false;
        } else if (longitud == sizeof linea - 1 || byteLeido == 0) {
            descartar = true;
        } else if (!descartar && byteLeido >= 0) {
            linea[longitud++] = static_cast<char>(byteLeido);
        }
    }
}

void setup() {
    Serial.begin(115200);
#if defined(ARDUINO_ARCH_ESP32)
    analogReadResolution(12);
#endif
    for (uint8_t pin : PINES_LED) {
        pinMode(pin, OUTPUT);
        digitalWrite(pin, LOW);
    }
    const uint32_t ahora = millis();
    for (EntradaDigital &entrada : entradas) {
        pinMode(entrada.pin, INPUT_PULLUP);
        entrada.rebote.iniciar(digitalRead(entrada.pin) == LOW, ahora);
        if (entrada.interruptor) {
            emitir(entrada.control, entrada.rebote.estado, ahora);
        }
    }
    ultimoTorque = torque.actualizar(analogRead(PIN_TORQUE), MAXIMO_ADC);
    emitir("torque", ultimoTorque, ahora);
    ultimoEventoTorque = ultimaMuestra = ultimoLatido = ahora;
}

void loop() {
    const uint32_t ahora = millis();
    for (EntradaDigital &entrada : entradas) {
        if (entrada.rebote.actualizar(digitalRead(entrada.pin) == LOW, ahora) &&
            (entrada.interruptor || entrada.rebote.estado)) {
            emitir(entrada.control, entrada.rebote.estado, ahora);
        }
    }

    if (ahora - ultimaMuestra >= 10) {
        ultimaMuestra = ahora;
        const int valor = torque.actualizar(analogRead(PIN_TORQUE), MAXIMO_ADC);
        if (valor != ultimoTorque && ahora - ultimoEventoTorque >= ANTIRREBOTE_MS) {
            emitir("torque", valor, ahora);
            ultimoTorque = valor;
            ultimoEventoTorque = ahora;
        }
    }
    if (ahora - ultimoLatido >= 1000) {
        ultimoLatido = ahora;
        Serial.print(LATIDO);
        Serial.write('\n');
    }
    recibirLeds();
}
