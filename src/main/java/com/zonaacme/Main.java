package com.zonaacme;

import com.zonaacme.infrastructure.ui.SicaApp;

import javafx.application.Application;

/**
 * Punto de entrada del programa.
 *
 * No extiende de Application a proposito: si la clase principal extiende
 * de Application y JavaFX no esta como modulo, Java lanza el error
 * "JavaFX runtime components are missing". Con esta clase "lanzadora"
 * se evita ese problema.
 */
public class Main {

    public static void main(String[] args) {
        Application.launch(SicaApp.class, args);
    }
}
