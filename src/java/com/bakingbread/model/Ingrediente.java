package com.bakingbread.model;

// ============================================================
// CLASSE: Ingrediente
// Rappresenta un singolo ingrediente di una ricetta.
// Segue le regole JavaBean: attributi privati, metodi pubblici.
// ============================================================
public class Ingrediente {

    // --- ATTRIBUTI PRIVATI ---
    // Incapsulamento: nessuno può modificare questi valori
    // dall'esterno se non tramite i metodi setter.

    private String nome;        // Nome dell'ingrediente (es. "Farina 00")
    private String quantita;    // Quantità in forma testuale (es. "200")
    private String unitaMisura; // Unità di misura (es. "g", "ml", "cucchiai")

    // --- COSTRUTTORE VUOTO ---
    // Obbligatorio per i JavaBean: permette di creare un oggetto
    // vuoto da riempire successivamente con i setter.
    public Ingrediente() {}

    // --- GETTER: leggono il valore degli attributi privati ---

    // Restituisce il nome dell'ingrediente
    public String getNome() {
        return nome;
    }

    // Restituisce la quantità
    public String getQuantita() {
        return quantita;
    }

    // Restituisce l'unità di misura
    public String getUnitaMisura() {
        return unitaMisura;
    }

    // --- SETTER: scrivono il valore degli attributi privati ---

    // Imposta il nome dell'ingrediente
    public void setNome(String nome) {
        this.nome = nome;
    }

    // Imposta la quantità
    public void setQuantita(String quantita) {
        this.quantita = quantita;
    }

    // Imposta l'unità di misura
    public void setUnitaMisura(String unitaMisura) {
        this.unitaMisura = unitaMisura;
    }
}
