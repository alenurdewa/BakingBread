package com.bakingbread.util;

import java.sql.Connection;       // Rappresenta una connessione aperta al DB
import java.sql.DriverManager;    // Classe che crea la connessione JDBC
import java.sql.SQLException;     // Errore specifico del database

// ============================================================
// CLASSE: Db
// Classe di utilità per aprire connessioni al database MySQL.
// È "final" perché non deve essere estesa da altre classi.
// Il costruttore è privato perché non si devono creare istanze:
// si usa solo il metodo statico getConnection().
// ============================================================
public final class Db {

    // URL di connessione JDBC al database MySQL locale
    // - localhost:3306 → host e porta del server MySQL
    // - bakingbread → nome del database da usare
    // - useSSL=false → disabilita SSL (non serve in locale)
    // - serverTimezone=UTC → fuso orario del server
    // - allowPublicKeyRetrieval=true → necessario per MySQL 8+
    private static final String URL =
        "jdbc:mysql://localhost:3306/bakingbread" +
        "?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true";

    // Credenziali di accesso al database
    private static final String USER = "root"; // Nome utente MySQL
    private static final String PASS = "";     // Password MySQL (vuota in locale)

    // Costruttore privato: impedisce di fare "new Db()"
    private Db() {}

    // --------------------------------------------------------
    // METODO: getConnection
    // Apre e restituisce una nuova connessione al database.
    // Chi chiama questo metodo deve chiuderla con conn.close()
    // quando ha finito, altrimenti si esauriscono le connessioni.
    // --------------------------------------------------------
    public static Connection getConnection() throws SQLException, ClassNotFoundException {
        // Carica il driver JDBC di MySQL in memoria
        // Necessario per far "capire" a Java come parlare con MySQL
        Class.forName("com.mysql.cj.jdbc.Driver");

        // Apre la connessione usando URL, utente e password
        // e la restituisce al chiamante
        return DriverManager.getConnection(URL, USER, PASS);
    }
}
