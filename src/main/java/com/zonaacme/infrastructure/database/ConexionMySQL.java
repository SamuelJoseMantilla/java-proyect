package com.zonaacme.infrastructure.database;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 * Implementacion de ConexionBD para MySQL usando JDBC (DriverManager).
 *
 * Recibe los datos de conexion por el constructor en lugar de leerlos
 * ella misma: asi no depende de como se guarda la configuracion
 * (Responsabilidad Unica - la S de SOLID) y es facil de probar.
 *
 * Cada llamada abre una conexion NUEVA: quien la pide debe cerrarla,
 * idealmente con try-with-resources.
 */
public class ConexionMySQL implements ConexionBD {

    private final String url;
    private final String usuario;
    private final String clave;

    public ConexionMySQL(String url, String usuario, String clave) {
        this.url = url;
        this.usuario = usuario;
        this.clave = clave;
    }

    @Override
    public Connection obtenerConexion() throws SQLException {
        return DriverManager.getConnection(url, usuario, clave);
    }
}
