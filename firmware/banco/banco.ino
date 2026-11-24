#include <Arduino.h>
#include "logica.h"

constexpr uint8_t PIN_NODO_P = A1;
constexpr uint8_t PIN_NODO_Q = A2;

BancoArnes banco;

void emitir(const char *linea) {
    Serial.print(linea);
}

void setup() {
    Serial.begin(115200);
    const uint32_t ahora = millis();
    banco.iniciar(analogRead(PIN_NODO_P), analogRead(PIN_NODO_Q), ahora);
    banco.emitirNodo(0, ahora, emitir);
    banco.emitirNodo(1, ahora, emitir);
}

void loop() {
    const uint32_t ahora = millis();
    banco.actualizar(analogRead(PIN_NODO_P), analogRead(PIN_NODO_Q), ahora, emitir);
}
