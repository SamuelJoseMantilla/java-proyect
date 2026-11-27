package com.zonaacme.infrastructure.database;

import java.sql.Connection;
import java.sql.SQLException;

/**
 * Contrato para obtener una conexion a la base de datos.
 *
 * Los repositorios dependen de ESTA interfaz y no de MySQL directamente
 * (Principio de Inversion de Dependencias - la D de SOLID).
 * Si se cambia de motor, solo se crea otra implementacion.
 */
@FunctionalInterface
public interface ConexionBD {

    Connection obtenerConexion() throws SQLException;
}
