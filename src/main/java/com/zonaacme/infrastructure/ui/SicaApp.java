package com.zonaacme.infrastructure.ui;

import javafx.application.Application;
import javafx.geometry.Pos;
import javafx.scene.Scene;
import javafx.scene.control.Label;
import javafx.scene.layout.VBox;
import javafx.stage.Stage;

/**
 * Aplicacion JavaFX (adaptador de entrada).
 * Por ahora solo muestra una ventana de prueba para comprobar que
 * Java 21 + JavaFX quedaron bien configurados. Luego cargara el login.
 */
public class SicaApp extends Application {

    @Override
    public void start(Stage ventana) {
        Label titulo = new Label("SICA - Zona Acme");
        titulo.getStyleClass().add("titulo");

        Label detalle = new Label(String.format("Java %s  |  JavaFX %s",
                System.getProperty("java.version"),
                System.getProperty("javafx.version")));

        VBox raiz = new VBox(12, titulo, detalle);
        raiz.setAlignment(Pos.CENTER);

        Scene escena = new Scene(raiz, 480, 260);
        escena.getStylesheets().add(getClass().getResource("/css/estilos.css").toExternalForm());

        ventana.setTitle("SICA - Sistema Integrado de Control de Acceso");
        ventana.setScene(escena);
        ventana.show();
    }
}
