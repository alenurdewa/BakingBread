package com.bakingbread.model;

// ============================================================
// CLASSE: Passaggio
// Rappresenta un singolo passaggio (step) di una ricetta.
// Ogni ricetta ha N passaggi numerati in sequenza.
// ============================================================
public class Passaggio {

    // --- ATTRIBUTI PRIVATI ---

    private int    ordine;      // Numero del passaggio (1, 2, 3...)
    private String descrizione; // Testo che descrive cosa fare in questo step

    // --- COSTRUTTORE VUOTO ---
    public Passaggio() {}

    // --- GETTER ---

    // Restituisce il numero d'ordine del passaggio
    public int getOrdine() {
        return ordine;
    }

    // Restituisce la descrizione testuale del passaggio
    public String getDescrizione() {
        return descrizione;
    }

    // --- SETTER ---

    // Imposta il numero d'ordine del passaggio
    public void setOrdine(int ordine) {
        this.ordine = ordine;
    }

    // Imposta la descrizione del passaggio
    public void setDescrizione(String descrizione) {
        this.descrizione = descrizione;
    }
}
