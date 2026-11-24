#include "../panel/logica.h"

#include <cassert>
#include <cstring>
#include <iostream>

int main() {
    const char *controles[] = {"bloqueo", "etiquetado", "torque", "confirmar", "cancelar"};
    char linea[96];
    for (uint32_t i = 0; i < 5; ++i) {
        formatearEvento(linea, sizeof linea, controles[i], i == 2 ? 42 : 1, i, i * 60);
        std::cout << linea << '\n';
    }
    std::cout << LATIDO << '\n';

    Antirrebote boton;
    boton.iniciar(false, 0);
    assert(!boton.actualizar(true, 1));
    assert(!boton.actualizar(false, 20));
    assert(!boton.actualizar(true, 30));
    assert(!boton.actualizar(true, 79));
    assert(boton.actualizar(true, 80) && boton.estado);
    assert(!boton.actualizar(true, 130));
    assert(!boton.actualizar(false, UINT32_MAX - 20));
    assert(!boton.actualizar(false, 28));
    assert(boton.actualizar(false, 29) && !boton.estado);

    PromedioTorque torque;
    assert(torque.actualizar(0, 1023) == 0);
    for (int i = 1; i < 8; ++i) {
        assert(torque.actualizar(0, 1023) == 0);
    }
    for (int i = 1; i <= 8; ++i) {
        assert(torque.actualizar(1023, 1023) == (100 * i + 4) / 8);
    }
    PromedioTorque esp32;
    assert(esp32.actualizar(4095, 4095) == 100);

    OrdenLed orden;
    for (int i = 0; i < 3; ++i) {
        assert(std::cin.getline(linea, sizeof linea));
        assert(parsearLed(linea, orden) && orden.indice == i && orden.encender);
        assert(std::strstr(linea, "\"valor\":1"));
    }
    assert(parsearLed(" { \"valor\" : 0, \"led\":\"falla\", \"v\":1 }\r", orden));
    assert(orden.indice == 2 && !orden.encender);
    const char *invalidas[] = {
        "", "{\"v\":2,\"led\":\"falla\",\"valor\":1}",
        "{\"v\":1,\"led\":\"otro\",\"valor\":1}",
        "{\"v\":1,\"led\":\"falla\",\"valor\":true}",
        "{\"v\":1,\"led\":\"falla\",\"valor\":2}",
        "{\"v\":1,\"led\":\"falla\",\"valor\":01}",
        "{\"v\":1,\"led\":\"falla\"}",
        "{\"v\":1,\"led\":\"falla\",\"valor\":1,}",
        "{\"v\":1,\"led\":\"falla\",\"valor\":1,\"valor\":0}",
        "{\"v\":1,\"led\":\"falla\",\"valor\":1} resto",
    };
    for (const char *invalida : invalidas) {
        assert(!parsearLed(invalida, orden));
        assert(orden.indice == 2 && !orden.encender);
    }
}
