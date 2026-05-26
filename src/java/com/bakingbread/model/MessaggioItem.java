package com.bakingbread.model;

import java.sql.Timestamp; // Tipo Java per data+ora

// ============================================================
// CLASSE: MessaggioItem
// Rappresenta un singolo messaggio privato tra due utenti.
// Usato in messaggi.jsp per mostrare i "bubble" della chat.
// ============================================================
public class MessaggioItem {

    // --- ATTRIBUTI PRIVATI ---

    private int       idMessaggio;  // ID univoco del messaggio nel DB
    private int       mittenteId;   // ID dell'utente che ha inviato il messaggio
    private String    testo;        // Testo del messaggio
    private Timestamp data;         // Data e ora di invio

    // --- COSTRUTTORE VUOTO ---
    public MessaggioItem() {}

    // --- GETTER ---

    public int       getIdMessaggio() { return idMessaggio; }
    public int       getMittenteId()  { return mittenteId; }
    public String    getTesto()       { return testo; }
    public Timestamp getData()        { return data; }

    // --- SETTER ---

    public void setIdMessaggio(int idMessaggio) { this.idMessaggio = idMessaggio; }
    public void setMittenteId(int mittenteId)   { this.mittenteId = mittenteId; }
    public void setTesto(String testo)          { this.testo = testo; }
    public void setData(Timestamp data)         { this.data = data; }
}
