#ifndef PANEL_LOGICA_H
#define PANEL_LOGICA_H

#include <stdint.h>
#include <stdio.h>
#include <string.h>

constexpr uint32_t ANTIRREBOTE_MS = 50;
constexpr char LATIDO[] = "{\"v\":1,\"ctrl\":\"hb\"}";

inline void formatearEvento(char *linea, size_t capacidad, const char *control,
                            int valor, uint32_t secuencia, uint32_t tiempo) {
    snprintf(linea, capacidad,
             "{\"v\":1,\"ctrl\":\"%s\",\"valor\":%d,\"n\":%lu,\"t\":%lu}",
             control, valor, static_cast<unsigned long>(secuencia),
             static_cast<unsigned long>(tiempo));
}

struct Antirrebote {
    bool estado;
    bool candidato;
    uint32_t desde;

    void iniciar(bool lectura, uint32_t ahora) {
        estado = candidato = lectura;
        desde = ahora;
    }

    bool actualizar(bool lectura, uint32_t ahora) {
        if (lectura != candidato) {
            candidato = lectura;
            desde = ahora;
        }
        if (estado == candidato || ahora - desde < ANTIRREBOTE_MS) {
            return false;
        }
        estado = candidato;
        return true;
    }
};

class PromedioTorque {
    static constexpr uint8_t MUESTRAS = 8;
    uint16_t lecturas[MUESTRAS] = {};
    uint8_t siguiente = 0;
    uint8_t cantidad = 0;
    uint32_t suma = 0;

public:
    int actualizar(uint16_t lectura, uint16_t maximoAdc) {
        if (lectura > maximoAdc) {
            lectura = maximoAdc;
        }
        suma -= lecturas[siguiente];
        suma += lectura;
        lecturas[siguiente] = lectura;
        siguiente = (siguiente + 1) % MUESTRAS;
        if (cantidad < MUESTRAS) {
            ++cantidad;
        }
        const uint32_t escala = static_cast<uint32_t>(maximoAdc) * cantidad;
        return (suma * 100 + escala / 2) / escala;
    }
};

struct OrdenLed {
    uint8_t indice;
    bool encender;
};

inline void saltarEspacios(const char *&cursor) {
    while (*cursor == ' ' || *cursor == '\t' || *cursor == '\r' || *cursor == '\n') {
        ++cursor;
    }
}

inline bool consumir(const char *&cursor, const char *literal) {
    saltarEspacios(cursor);
    const size_t longitud = strlen(literal);
    if (strncmp(cursor, literal, longitud) != 0) {
        return false;
    }
    cursor += longitud;
    return true;
}

// El mensaje v1 tiene tres campos obligatorios, en cualquier orden.
inline bool parsearLed(const char *cursor, OrdenLed &orden) {
    const char *claves[] = {"\"v\"", "\"led\"", "\"valor\""};
    const char *leds[] = {"\"energizado\"", "\"bloqueado\"", "\"falla\""};
    bool vistos[3] = {};
    OrdenLed leida = {};
    if (!consumir(cursor, "{")) {
        return false;
    }
    for (uint8_t campo = 0; campo < 3; ++campo) {
        if (campo > 0 && !consumir(cursor, ",")) {
            return false;
        }
        uint8_t clave = 0;
        while (clave < 3 && !consumir(cursor, claves[clave])) {
            ++clave;
        }
        if (clave == 3 || vistos[clave] || !consumir(cursor, ":")) {
            return false;
        }
        vistos[clave] = true;
        if (clave == 0) {
            if (!consumir(cursor, "1")) {
                return false;
            }
        } else if (clave == 1) {
            while (leida.indice < 3 && !consumir(cursor, leds[leida.indice])) {
                ++leida.indice;
            }
            if (leida.indice == 3) {
                return false;
            }
        } else {
            leida.encender = consumir(cursor, "1");
            if (!leida.encender && !consumir(cursor, "0")) {
                return false;
            }
        }
    }
    if (!consumir(cursor, "}")) {
        return false;
    }
    saltarEspacios(cursor);
    if (*cursor != '\0') {
        return false;
    }
    orden = leida;
    return true;
}

#endif
