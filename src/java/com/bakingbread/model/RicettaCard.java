package com.bakingbread.model;

// ============================================================
// CLASSE: RicettaCard
// Contiene tutti i dati necessari per mostrare una ricetta
// come "card" nel feed della home o nella griglia del profilo.
// Include anche info sull'autore e sui like/salvataggi.
// ============================================================
public class RicettaCard {

    // --- ATTRIBUTI PRIVATI ---

    // Dati della ricetta
    private int    idRicetta;       // ID univoco della ricetta
    private String titolo;          // Titolo della ricetta
    private String descrizione;     // Breve descrizione
    private String immagineUrl;     // URL immagine di copertina
    private String categoria;       // Categoria (es. "dolci", "pasta")
    private int    tempoPrep;       // Minuti di preparazione
    private int    tempoCottura;    // Minuti di cottura
    private String difficolta;      // "facile", "media", "difficile"
    private int    porzioni;        // Numero di porzioni

    // Dati dell'autore della ricetta
    private int    idAutore;        // ID dell'utente autore
    private String nomeAutore;      // Nome visualizzato dell'autore
    private String usernameAutore;  // Username dell'autore
    private String avatarAutore;    // URL avatar dell'autore

    // Dati sociali (like e salvataggi)
    private int     numLike;        // Numero totale di "Mi piace"
    private boolean likedDaMe;      // true se l'utente corrente ha messo like
    private boolean salvataDaMe;    // true se l'utente corrente ha salvato la ricetta

    // --- COSTRUTTORE VUOTO ---
    public RicettaCard() {}

    // --- GETTER ---

    public int    getIdRicetta()      { return idRicetta; }
    public String getTitolo()         { return titolo; }
    public String getDescrizione()    { return descrizione; }
    public String getImmagineUrl()    { return immagineUrl; }
    public String getCategoria()      { return categoria; }
    public int    getTempoPrep()      { return tempoPrep; }
    public int    getTempoCottura()   { return tempoCottura; }
    public String getDifficolta()     { return difficolta; }
    public int    getPorzioni()       { return porzioni; }
    public int    getIdAutore()       { return idAutore; }
    public String getNomeAutore()     { return nomeAutore; }
    public String getUsernameAutore() { return usernameAutore; }
    public String getAvatarAutore()   { return avatarAutore; }
    public int    getNumLike()        { return numLike; }
    public boolean isLikedDaMe()     { return likedDaMe; }
    public boolean isSalvataDaMe()   { return salvataDaMe; }

    // --- SETTER ---

    public void setIdRicetta(int idRicetta)           { this.idRicetta = idRicetta; }
    public void setTitolo(String titolo)              { this.titolo = titolo; }
    public void setDescrizione(String descrizione)    { this.descrizione = descrizione; }
    public void setImmagineUrl(String immagineUrl)    { this.immagineUrl = immagineUrl; }
    public void setCategoria(String categoria)        { this.categoria = categoria; }
    public void setTempoPrep(int tempoPrep)           { this.tempoPrep = tempoPrep; }
    public void setTempoCottura(int tempoCottura)     { this.tempoCottura = tempoCottura; }
    public void setDifficolta(String difficolta)      { this.difficolta = difficolta; }
    public void setPorzioni(int porzioni)             { this.porzioni = porzioni; }
    public void setIdAutore(int idAutore)             { this.idAutore = idAutore; }
    public void setNomeAutore(String nomeAutore)      { this.nomeAutore = nomeAutore; }
    public void setUsernameAutore(String u)           { this.usernameAutore = u; }
    public void setAvatarAutore(String avatarAutore)  { this.avatarAutore = avatarAutore; }
    public void setNumLike(int numLike)               { this.numLike = numLike; }
    public void setLikedDaMe(boolean likedDaMe)       { this.likedDaMe = likedDaMe; }
    public void setSalvataDaMe(boolean salvataDaMe)   { this.salvataDaMe = salvataDaMe; }
}
