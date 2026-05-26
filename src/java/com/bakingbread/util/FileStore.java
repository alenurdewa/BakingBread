package com.bakingbread.util;

import java.io.File;             // Rappresenta un file o cartella su disco
import java.io.FileOutputStream; // Permette di scrivere byte su un file
import java.io.IOException;      // Errore generico di input/output
import java.io.InputStream;      // Flusso di byte in ingresso (dal form)
import javax.servlet.ServletContext; // Fornisce il percorso reale dell'app web
import javax.servlet.http.Part;      // Rappresenta un file caricato da un form HTML

// ============================================================
// CLASSE: FileStore
// Classe di utilità per salvare i file caricati dagli utenti
// (avatar e immagini delle ricette) sul disco del server.
// È "final" e ha costruttore privato: si usa solo salva().
// ============================================================
public final class FileStore {

    // Costruttore privato: impedisce di istanziare questa classe
    private FileStore() {}

    // --------------------------------------------------------
    // METODO: salva
    // Salva sul disco un file ricevuto da un form HTML.
    //
    // Parametri:
    //   part       → il file caricato dall'utente tramite il form
    //   context    → contesto dell'applicazione (serve per trovare
    //                il percorso fisico della cartella uploads)
    //   cartella   → sottocartella di destinazione (es. "avatars")
    //   prefisso   → testo aggiunto al nome file (es. "avatar_5")
    //
    // Restituisce: il percorso relativo del file salvato
    //              (es. "/uploads/avatars/avatar_5_12345_foto.jpg")
    //              oppure null se non c'è nessun file da salvare.
    // --------------------------------------------------------
    public static String salva(Part part, ServletContext context,
                               String cartella, String prefisso) throws IOException {

        // Controlla se il file è stato davvero allegato
        if (part == null || part.getSize() <= 0) {
            return null; // Nessun file caricato: restituisce null
        }

        // Ottiene il nome originale del file caricato dall'utente
        String nomeOriginale = part.getSubmittedFileName();

        // Controlla che il nome del file non sia vuoto
        if (nomeOriginale == null || nomeOriginale.trim().isEmpty()) {
            return null; // Nome file mancante: restituisce null
        }

        // Sanitizza il nome file: sostituisce caratteri pericolosi
        // con underscore per evitare problemi di sicurezza
        String nomeSanitizzato = nomeOriginale
            .replaceAll("[\\\\/]+", "_")          // rimuove slash e backslash
            .replaceAll("[^a-zA-Z0-9._-]", "_");  // rimuove caratteri speciali

        // Costruisce il nome finale del file aggiungendo prefisso
        // e il timestamp attuale (per evitare conflitti di nomi)
        String nomeFinale = prefisso + "_" + System.currentTimeMillis() + "_" + nomeSanitizzato;

        // Trova il percorso fisico della cartella "uploads" del server
        String percorsoBase = context.getRealPath("/uploads");

        // Se il percorso non è disponibile, usa la radice dell'app
        if (percorsoBase == null) {
            percorsoBase = context.getRealPath("/");
        }

        // Se il percorso è ancora null, lancia un errore
        if (percorsoBase == null) {
            throw new IOException("Impossibile trovare la cartella uploads sul server.");
        }

        // Costruisce il percorso della sottocartella di destinazione
        File cartellaDestinazione = new File(percorsoBase, cartella);

        // Crea la sottocartella se non esiste ancora
        if (!cartellaDestinazione.exists()) {
            cartellaDestinazione.mkdirs(); // mkdirs crea anche le cartelle intermedie
        }

        // Costruisce il percorso completo del file di destinazione
        File fileDestinazione = new File(cartellaDestinazione, nomeFinale);

        // Copia i byte del file ricevuto nel file di destinazione
        // "try-with-resources" chiude automaticamente i flussi
        try (InputStream input = part.getInputStream();
             FileOutputStream output = new FileOutputStream(fileDestinazione)) {

            // Buffer: blocco di byte letti alla volta (8 KB)
            byte[] buffer = new byte[8192];
            int byteLetti; // Quanti byte sono stati letti in questo ciclo

            // Ciclo: legge dal form e scrive su disco finché non finisce
            while ((byteLetti = input.read(buffer)) != -1) {
                output.write(buffer, 0, byteLetti); // Scrive solo i byte letti
            }
        }

        // Restituisce il percorso relativo che si può usare come URL
        return "/uploads/" + cartella + "/" + nomeFinale;
    }
}
