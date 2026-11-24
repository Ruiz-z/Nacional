#include "../banco/logica.h"
#include <assert.h>
#include <string>

int main() {
    BancoArnes banco;
    auto imprimir = [](const char *linea) { fputs(linea, stdout); };
    banco.iniciar(512, 511, 0);
    banco.emitirNodo(0, 0, imprimir);
    banco.emitirNodo(1, 40, imprimir);
    fputs(BancoArnes::LATIDO, stdout);

    BancoArnes practica;
    std::string mensajes;
    auto capturar = [&mensajes](const char *linea) { mensajes += linea; };
    practica.iniciar(512, 511, 0);
    practica.actualizar(511, 511, 1, capturar);
    practica.actualizar(512, 511, 49, capturar);
    practica.actualizar(511, 511, 60, capturar);
    practica.actualizar(511, 511, 109, capturar);
    assert(mensajes.empty());
    practica.actualizar(511, 511, 110, capturar);
    assert(mensajes == "{\"v\":1,\"ctrl\":\"nodo_p\",\"valor\":0,\"n\":0,\"t\":110}\n");
    practica.actualizar(511, 512, 950, capturar);
    practica.actualizar(511, 512, 999, capturar);
    assert(mensajes == "{\"v\":1,\"ctrl\":\"nodo_p\",\"valor\":0,\"n\":0,\"t\":110}\n");
    mensajes.clear();
    practica.actualizar(511, 512, 1000, capturar);
    assert(mensajes ==
           "{\"v\":1,\"ctrl\":\"hb\"}\n"
           "{\"v\":1,\"ctrl\":\"nodo_p\",\"valor\":0,\"n\":1,\"t\":1000}\n"
           "{\"v\":1,\"ctrl\":\"nodo_q\",\"valor\":1,\"n\":2,\"t\":1000}\n");
    mensajes.clear();
    practica.actualizar(511, 512, 2000, capturar);
    assert(mensajes ==
           "{\"v\":1,\"ctrl\":\"hb\"}\n"
           "{\"v\":1,\"ctrl\":\"nodo_p\",\"valor\":0,\"n\":3,\"t\":2000}\n"
           "{\"v\":1,\"ctrl\":\"nodo_q\",\"valor\":1,\"n\":4,\"t\":2000}\n");
}
