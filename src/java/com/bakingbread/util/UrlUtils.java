package com.bakingbread.util;

// ============================================================
// CLASSE: UrlUtils
// Classe di utilità per costruire URL corretti nelle pagine JSP.
// Il problema: le immagini salvate nel DB possono avere URL
// relativi (es. "/uploads/avatars/foto.jpg") oppure assoluti
// (es. "https://esempio.com/foto.jpg"). Questo metodo gestisce
// entrambi i casi aggiungendo il contextPath quando necessario.
//
// Il contextPath è il prefisso dell'applicazione web, ad esempio
// "/BakingBread" se l'app è deployata in quella cartella.
// ============================================================
public final class UrlUtils {

    // Costruttore privato: questa classe non si istanzia
    private UrlUtils() {}

    // --------------------------------------------------------
    // METODO: risolvi
    // Converte un URL grezzo (dal database) in un URL utilizzabile
    // direttamente in un tag HTML <img> o <a>.
    //
    // Parametri:
    //   contextPath → prefisso dell'app (da request.getContextPath())
    //   urlGrezzo   → URL come salvato nel database
    //
    // Restituisce: URL completo pronto per l'uso in HTML
    // --------------------------------------------------------
    public static String risolvi(String contextPath, String urlGrezzo) {

        // Se l'URL è null, restituisce stringa vuota (sicuro per HTML)
        if (urlGrezzo == null) {
            return "";
        }

        // Rimuove spazi bianchi all'inizio e alla fine
        String url = urlGrezzo.trim();

        // Se l'URL è vuoto, non c'è nulla da fare
        if (url.isEmpty()) {
            return "";
        }

        // Se l'URL è già assoluto (inizia con http/https/data/blob)
        // lo restituisce così com'è senza modifiche
        if (url.startsWith("http://") || url.startsWith("https://") ||
            url.startsWith("data:")   || url.startsWith("blob:")) {
            return url;
        }

        // Se contextPath è null, lo imposta come stringa vuota
        if (contextPath == null) {
            contextPath = "";
        }

        // Evita di aggiungere il contextPath se è già presente nell'URL
        if (!contextPath.isEmpty() && url.startsWith(contextPath + "/")) {
            return url; // L'URL ha già il prefisso corretto
        }

        // Se l'URL è relativo dalla radice (inizia con "/"),
        // aggiunge il contextPath davanti
        if (url.startsWith("/")) {
            return contextPath + url;
        }

        // In tutti gli altri casi aggiunge contextPath + "/"
        return contextPath + "/" + url;
    }
}
