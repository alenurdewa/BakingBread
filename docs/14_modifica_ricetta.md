# modifica_ricetta.jsp

## Descrizione
Pagina di solo reindirizzamento. Riceve un parametro `?id=N` e lo passa a `crea_ricetta.jsp?modifica=N`. Esiste per compatibilità con link che puntano direttamente a questa URL.

## Funzionamento

```java
String id = request.getParameter("id");
if (id != null) {
    Integer.parseInt(id); // Valida che sia un numero
    response.sendRedirect("crea_ricetta.jsp?modifica=" + id.trim());
} else {
    response.sendRedirect("home.jsp");
}
```

Non renderizza nessun HTML. Non accede al database. Non legge né scrive la sessione.

## Parametri GET
| Parametro | Obbligatorio | Descrizione |
|-----------|:---:|-------------|
| `id` | ✓ | ID della ricetta da modificare |
