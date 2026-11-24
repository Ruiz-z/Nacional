#ifndef BANCO_LOGICA_H
#define BANCO_LOGICA_H

#include <stdint.h>
#include <stdio.h>

class BancoArnes {
    static constexpr uint16_t UMBRAL_ADC = 512;
    static constexpr uint32_t ANTIRREBOTE_MS = 50;
    static constexpr uint32_t LATIDO_MS = 1000;

    struct Nodo {
        bool estado;
        bool candidato;
        uint32_t desde;

        bool actualizar(uint16_t lectura, uint32_t ahora) {
            const bool alto = lectura >= UMBRAL_ADC;
            if (alto != candidato) {
                candidato = alto;
                desde = ahora;
            }
            if (estado == candidato || ahora - desde < ANTIRREBOTE_MS) {
                return false;
            }
            estado = candidato;
            return true;
        }
    };

    Nodo nodos[2];
    uint32_t secuencia = 0;
    uint32_t ultimoLatido;

public:
    static constexpr const char *LATIDO = "{\"v\":1,\"ctrl\":\"hb\"}\n";

    void iniciar(uint16_t p, uint16_t q, uint32_t ahora) {
        nodos[0] = {p >= UMBRAL_ADC, p >= UMBRAL_ADC, ahora};
        nodos[1] = {q >= UMBRAL_ADC, q >= UMBRAL_ADC, ahora};
        ultimoLatido = ahora;
    }

    template <typename Emitir>
    void emitirNodo(uint8_t indice, uint32_t ahora, Emitir emitir) {
        char linea[80];
        snprintf(linea, sizeof linea,
                 "{\"v\":1,\"ctrl\":\"nodo_%c\",\"valor\":%d,\"n\":%lu,\"t\":%lu}\n",
                 indice == 0 ? 'p' : 'q', nodos[indice].estado ? 1 : 0,
                 static_cast<unsigned long>(secuencia++), static_cast<unsigned long>(ahora));
        emitir(linea);
    }

    template <typename Emitir>
    void actualizar(uint16_t p, uint16_t q, uint32_t ahora, Emitir emitir) {
        const bool latido = ahora - ultimoLatido >= LATIDO_MS;
        if (latido) {
            ultimoLatido = ahora;
            emitir(LATIDO);
        }
        const uint16_t lecturas[] = {p, q};
        for (uint8_t indice = 0; indice < 2; ++indice) {
            if (nodos[indice].actualizar(lecturas[indice], ahora) || latido) {
                emitirNodo(indice, ahora, emitir);
            }
        }
    }
};

#endif
