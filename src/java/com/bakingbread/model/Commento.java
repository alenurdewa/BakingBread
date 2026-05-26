package com.bakingbread.model;

import java.sql.Timestamp; // Timestamp = tipo Java che rappresenta data + ora

// ============================================================
// CLASSE: Commento
// Rappresenta un singolo commento lasciato su una ricetta.
// Può essere un commento principale oppure una risposta
// ad un altro commento (tramite il campo idParent).
// ============================================================
public class Commento {

    // --- ATTRIBUTI PRIVATI ---

    private int       idCommento;  // ID univoco del commento nel DB
    private int       idParent;    // ID del commento padre (0 se è principale)
    private int       idUtente;    // ID dell'utente che ha scritto il commento
    private String    nomeUtente;  // Nome visualizzato dell'autore
    private String    username;    // Username dell'autore (per i link al profilo)
    private String    avatarUrl;   // URL immagine profilo dell'autore
    private String    testo;       // Testo del commento
    private Timestamp data;        // Data e ora di creazione

    // --- COSTRUTTORE VUOTO ---
    public Commento() {}

    // --- GETTER ---

    public int getIdCommento()      { return idCommento; }
    public int getIdParent()        { return idParent; }
    public int getIdUtente()        { return idUtente; }
    public String getNomeUtente()   { return nomeUtente; }
    public String getUsername()     { return username; }
    public String getAvatarUrl()    { return avatarUrl; }
    public String getTesto()        { return testo; }
    public Timestamp getData()      { return data; }

    // --- SETTER ---

    public void setIdCommento(int idCommento)         { this.idCommento = idCommento; }
    public void setIdParent(int idParent)             { this.idParent = idParent; }
    public void setIdUtente(int idUtente)             { this.idUtente = idUtente; }
    public void setNomeUtente(String nomeUtente)      { this.nomeUtente = nomeUtente; }
    public void setUsername(String username)          { this.username = username; }
    public void setAvatarUrl(String avatarUrl)        { this.avatarUrl = avatarUrl; }
    public void setTesto(String testo)                { this.testo = testo; }
    public void setData(Timestamp data)               { this.data = data; }
}
