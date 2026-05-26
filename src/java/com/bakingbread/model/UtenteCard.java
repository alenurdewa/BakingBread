package com.bakingbread.model;

// ============================================================
// CLASSE: UtenteCard
// Contiene i dati essenziali di un utente per mostrarlo
// nelle liste: network (follower/seguiti) e messaggi.
// ============================================================
public class UtenteCard {

    // --- ATTRIBUTI PRIVATI ---

    private int     idUtente;         // ID univoco dell'utente nel DB
    private String  username;         // Username (usato nei link al profilo)
    private String  nomeVisualizzato; // Nome mostrato nell'interfaccia
    private String  avatarUrl;        // URL dell'immagine profilo
    private boolean followDaMe;       // true se l'utente corrente lo segue
    private String  ultimoMessaggio;  // Anteprima ultimo messaggio (per messaggi.jsp)

    // --- COSTRUTTORE VUOTO ---
    public UtenteCard() {}

    // --- GETTER ---

    public int     getIdUtente()          { return idUtente; }
    public String  getUsername()          { return username; }
    public String  getNomeVisualizzato()  { return nomeVisualizzato; }
    public String  getAvatarUrl()         { return avatarUrl; }
    public boolean isFollowDaMe()         { return followDaMe; }
    public String  getUltimoMessaggio()   { return ultimoMessaggio; }

    // --- SETTER ---

    public void setIdUtente(int idUtente)                    { this.idUtente = idUtente; }
    public void setUsername(String username)                 { this.username = username; }
    public void setNomeVisualizzato(String nome)             { this.nomeVisualizzato = nome; }
    public void setAvatarUrl(String avatarUrl)               { this.avatarUrl = avatarUrl; }
    public void setFollowDaMe(boolean followDaMe)            { this.followDaMe = followDaMe; }
    public void setUltimoMessaggio(String ultimoMessaggio)   { this.ultimoMessaggio = ultimoMessaggio; }
}
