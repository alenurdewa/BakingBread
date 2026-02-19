package com.utils;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 * Utility per ottenere Connection SQLite.
 * L'URL viene impostato da AppContextListener all'avvio dell'app con DBUtils.setDbUrl(...)
 */
public class DBUtils {

    private static volatile String DB_URL = null;

    static {
        try {
            // carica il driver SQLite (assicurati di avere il jar in WEB-INF/lib)
            Class.forName("org.sqlite.JDBC");
        } catch (ClassNotFoundException e) {
            System.err.println("[DBUtils] Impossibile trovare il driver SQLite: " + e.getMessage());
            e.printStackTrace();
        }
    }

    /**
     * Imposta l'URL JDBC (es: "jdbc:sqlite:/percorso/assoluto/WEB-INF/db/bakingbread.db")
     */
    public static void setDbUrl(String dbUrl) {
        DB_URL = dbUrl;
        System.out.println("[DBUtils] DB_URL impostato a: " + DB_URL);
    }

    /**
     * Ottieni una nuova Connection.
     * @throws SQLException se DB_URL non è impostato o la connessione fallisce
     */
    public static Connection getConnection() throws SQLException {
        if (DB_URL == null) {
            throw new SQLException("DB_URL non impostato. Usa AppContextListener o DBUtils.setDbUrl(...) prima.");
        }
        return DriverManager.getConnection(DB_URL);
    }
}
