package com.zonaacme.config;

import java.io.IOException;
import java.io.InputStream;
import java.util.Optional;
import java.util.Properties;

/**
 * Patron SINGLETON: lee config.properties UNA sola vez y comparte
 * esos valores con toda la aplicacion.
 *
 * Se implementa con un enum porque:
 *  - Java garantiza que solo existe UNA instancia (INSTANCIA).
 *  - Es seguro con varios hilos (thread-safe) sin usar synchronized.
 *  - No se puede crear otra instancia ni por reflexion ni por serializacion.
 *
 * Uso:  ConfiguracionSingleton.INSTANCIA.obtener("db.url")
 */
public enum ConfiguracionSingleton {

    INSTANCIA;

    private static final String ARCHIVO = "/config.properties";

    private final Properties propiedades = new Properties();

    // El constructor de un enum se ejecuta una sola vez, al primer uso
    ConfiguracionSingleton() {
        try (InputStream entrada = ConfiguracionSingleton.class.getResourceAsStream(ARCHIVO)) {
            if (entrada == null) {
                throw new IllegalStateException(
                        "No se encontro " + ARCHIVO + ". Copie config.properties.example como config.properties");
            }
            propiedades.load(entrada);
        } catch (IOException e) {
            throw new IllegalStateException("Error leyendo " + ARCHIVO, e);
        }
    }

    /** Devuelve un valor obligatorio. Si no existe, falla con un mensaje claro. */
    public String obtener(String clave) {
        return Optional.ofNullable(propiedades.getProperty(clave))
                .map(String::trim)
                .orElseThrow(() -> new IllegalStateException("Falta la propiedad '" + clave + "' en " + ARCHIVO));
    }

    /** Devuelve un numero entero, o el valor por defecto si la clave no existe. */
    public int obtenerEntero(String clave, int porDefecto) {
        return Optional.ofNullable(propiedades.getProperty(clave))
                .map(String::trim)
                .map(Integer::parseInt)
                .orElse(porDefecto);
    }
}
