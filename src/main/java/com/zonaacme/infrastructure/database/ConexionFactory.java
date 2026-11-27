package com.zonaacme.infrastructure.database;

import com.zonaacme.config.ConfiguracionSingleton;

import java.util.Map;
import java.util.function.Function;

/**
 * Patron FACTORY: decide QUE implementacion de ConexionBD crear segun
 * la propiedad "db.motor" de config.properties. Quien pide la conexion
 * no sabe (ni le importa) si es MySQL u otro motor.
 *
 * Cada motor se registra en un mapa con una expresion lambda.
 * Para soportar otro motor se agrega UNA linea al mapa, sin tocar
 * el resto del codigo (Abierto/Cerrado - la O de SOLID).
 */
public final class ConexionFactory {

    private static final Map<String, Function<ConfiguracionSingleton, ConexionBD>> MOTORES = Map.of(
            "mysql", config -> new ConexionMySQL(
                    config.obtener("db.url"),
                    config.obtener("db.user"),
                    config.obtener("db.password"))
    );

    private ConexionFactory() {
        // Clase de utilidad: no se instancia
    }

    public static ConexionBD crear() {
        ConfiguracionSingleton config = ConfiguracionSingleton.INSTANCIA;
        String motor = config.obtener("db.motor").toLowerCase();

        Function<ConfiguracionSingleton, ConexionBD> constructor = MOTORES.get(motor);
        if (constructor == null) {
            throw new IllegalStateException("Motor de base de datos no soportado: " + motor
                    + ". Opciones: " + MOTORES.keySet());
        }
        return constructor.apply(config);
    }
}
