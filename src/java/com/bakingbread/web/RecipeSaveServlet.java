package com.bakingbread.web;

import com.bakingbread.util.Db;
import com.bakingbread.util.FileStore;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;

@WebServlet(name = "RecipeSaveServlet", urlPatterns = {"/recipe/save"})
@MultipartConfig(maxFileSize = 8 * 1024 * 1024, maxRequestSize = 20 * 1024 * 1024)
public class RecipeSaveServlet extends HttpServlet {

    private static final class IngredientRow {
        final String nome;
        final String quantita;
        final String unita;
        IngredientRow(String nome, String quantita, String unita) {
            this.nome = nome;
            this.quantita = quantita;
            this.unita = unita;
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession(false);
        Integer idUtente = session != null ? (Integer) session.getAttribute("id_utente") : null;
        if (idUtente == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        int idRicetta = parseInt(request.getParameter("id_ricetta"), 0);
        boolean editing = idRicetta > 0;

        String titolo = safe(request.getParameter("titolo"));
        String descrizione = safe(request.getParameter("descrizione"));
        String categoria = safe(request.getParameter("categoria"));
        int prep = parseInt(request.getParameter("tempo_preparazione"), 0);
        int cottura = parseInt(request.getParameter("tempo_cottura"), 0);
        int porzioni = Math.max(1, parseInt(request.getParameter("porzioni"), 4));
        String difficolta = safe(request.getParameter("difficolta"));
        String dieta = safe(request.getParameter("dieta"));
        boolean pubblica = request.getParameter("pubblica") != null;
        String currentImageUrl = safe(request.getParameter("current_image_url"));
        String manualImageUrl = safe(request.getParameter("immagine_url"));
        String imageUrl = currentImageUrl;

        Part imagePart = null;
        try {
            imagePart = request.getPart("recipe_image_file");
        } catch (Exception ignore) {
            imagePart = null;
        }

        if (titolo.isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/crea_ricetta.jsp?errore=1");
            return;
        }

        try (Connection conn = Db.getConnection()) {
            conn.setAutoCommit(false);
            int savedRecipeId = idRicetta;
            try {
                if (imagePart != null && imagePart.getSize() > 0 && imagePart.getSubmittedFileName() != null && !imagePart.getSubmittedFileName().trim().isEmpty()) {
                    imageUrl = request.getContextPath() + FileStore.savePart(imagePart, getServletContext(), "recipes", "ricetta_" + idUtente);
                } else if (!manualImageUrl.isEmpty()) {
                    imageUrl = manualImageUrl;
                }

                if (editing) {
                    try (PreparedStatement ps = conn.prepareStatement(
                            "UPDATE Ricetta SET titolo = ?, descrizione = ?, categoria = ?, tempo_preparazione_min = ?, tempo_cottura_min = ?, porzioni = ?, difficolta = ?, dieta = ?, immagine_url = ?, pubblicata = ?, aggiornato_il = NOW() WHERE id_ricetta = ? AND id_utente = ?")) {
                        ps.setString(1, titolo);
                        ps.setString(2, descrizione);
                        ps.setString(3, categoria.isEmpty() ? null : categoria);
                        if (prep > 0) ps.setInt(4, prep); else ps.setNull(4, java.sql.Types.INTEGER);
                        if (cottura > 0) ps.setInt(5, cottura); else ps.setNull(5, java.sql.Types.INTEGER);
                        ps.setInt(6, porzioni);
                        ps.setString(7, difficolta.isEmpty() ? "facile" : difficolta);
                        ps.setString(8, dieta.isEmpty() ? null : dieta);
                        ps.setString(9, imageUrl.isEmpty() ? null : imageUrl);
                        ps.setBoolean(10, pubblica);
                        ps.setInt(11, idRicetta);
                        ps.setInt(12, idUtente);
                        if (ps.executeUpdate() == 0) {
                            throw new SQLException("Ricetta non trovata o non autorizzata.");
                        }
                    }
                    try (PreparedStatement ps = conn.prepareStatement("DELETE FROM RicettaIngrediente WHERE id_ricetta = ?")) {
                        ps.setInt(1, idRicetta);
                        ps.executeUpdate();
                    }
                    try (PreparedStatement ps = conn.prepareStatement("DELETE FROM Passaggio WHERE id_ricetta = ?")) {
                        ps.setInt(1, idRicetta);
                        ps.executeUpdate();
                    }
                } else {
                    try (PreparedStatement ps = conn.prepareStatement(
                            "INSERT INTO Ricetta (id_utente, titolo, descrizione, categoria, tempo_preparazione_min, tempo_cottura_min, porzioni, difficolta, dieta, immagine_url, pubblicata) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                            PreparedStatement.RETURN_GENERATED_KEYS)) {
                        ps.setInt(1, idUtente);
                        ps.setString(2, titolo);
                        ps.setString(3, descrizione);
                        ps.setString(4, categoria.isEmpty() ? null : categoria);
                        if (prep > 0) ps.setInt(5, prep); else ps.setNull(5, java.sql.Types.INTEGER);
                        if (cottura > 0) ps.setInt(6, cottura); else ps.setNull(6, java.sql.Types.INTEGER);
                        ps.setInt(7, porzioni);
                        ps.setString(8, difficolta.isEmpty() ? "facile" : difficolta);
                        ps.setString(9, dieta.isEmpty() ? null : dieta);
                        ps.setString(10, imageUrl.isEmpty() ? null : imageUrl);
                        ps.setBoolean(11, pubblica);
                        ps.executeUpdate();
                        try (ResultSet rs = ps.getGeneratedKeys()) {
                            if (rs.next()) {
                                savedRecipeId = rs.getInt(1);
                            } else {
                                throw new SQLException("Impossibile recuperare l'ID della ricetta.");
                            }
                        }
                    }
                }

                List<IngredientRow> ingredienti = new ArrayList<IngredientRow>();
                String[] ingredientiNome = request.getParameterValues("ingrediente_nome");
                String[] ingredientiQta = request.getParameterValues("ingrediente_quantita");
                String[] ingredientiUnita = request.getParameterValues("ingrediente_unita");
                if (ingredientiNome != null) {
                    for (int i = 0; i < ingredientiNome.length; i++) {
                        String nome = safe(ingredientiNome[i]);
                        if (!nome.isEmpty()) {
                            String qta = ingredientiQta != null && ingredientiQta.length > i ? safe(ingredientiQta[i]) : "";
                            String unita = ingredientiUnita != null && ingredientiUnita.length > i ? safe(ingredientiUnita[i]) : "";
                            ingredienti.add(new IngredientRow(nome, qta, unita));
                        }
                    }
                }

                for (int i = 0; i < ingredienti.size(); i++) {
                    IngredientRow row = ingredienti.get(i);
                    int idIngrediente = ensureIngredient(conn, row.nome);
                    try (PreparedStatement ps = conn.prepareStatement(
                            "INSERT INTO RicettaIngrediente (id_ricetta, id_ingrediente, quantita, unita_misura, ordine_visualizzazione) VALUES (?, ?, ?, ?, ?)") ) {
                        ps.setInt(1, savedRecipeId);
                        ps.setInt(2, idIngrediente);
                        ps.setString(3, row.quantita.isEmpty() ? null : row.quantita);
                        ps.setString(4, row.unita.isEmpty() ? null : row.unita);
                        ps.setInt(5, i + 1);
                        ps.executeUpdate();
                    }
                }

                String[] passaggi = request.getParameterValues("passaggio_descrizione");
                if (passaggi != null) {
                    int ordine = 1;
                    for (String raw : passaggi) {
                        String descr = safe(raw);
                        if (!descr.isEmpty()) {
                            try (PreparedStatement ps = conn.prepareStatement(
                                    "INSERT INTO Passaggio (id_ricetta, ordine, descrizione) VALUES (?, ?, ?)") ) {
                                ps.setInt(1, savedRecipeId);
                                ps.setInt(2, ordine++);
                                ps.setString(3, descr);
                                ps.executeUpdate();
                            }
                        }
                    }
                }

                conn.commit();
                response.sendRedirect(request.getContextPath() + "/dettaglio_ricetta.jsp?id=" + savedRecipeId);
            } catch (Exception ex) {
                try { conn.rollback(); } catch (SQLException ignore) {}
                throw new ServletException("Errore nel salvataggio della ricetta: " + ex.getMessage(), ex);
            } finally {
                try { conn.setAutoCommit(true); } catch (SQLException ignore) {}
            }
        } catch (ClassNotFoundException e) {
            throw new ServletException("Driver JDBC non trovato.", e);
        } catch (SQLException e) {
            throw new ServletException("Errore database: " + e.getMessage(), e);
        }
    }

    private int ensureIngredient(Connection conn, String nome) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement("SELECT id_ingrediente FROM Ingrediente WHERE nome = ?")) {
            ps.setString(1, nome);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        }
        try (PreparedStatement ps = conn.prepareStatement("INSERT INTO Ingrediente (nome) VALUES (?)", PreparedStatement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, nome);
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) return rs.getInt(1);
            }
        }
        throw new SQLException("Impossibile salvare l'ingrediente: " + nome);
    }

    private static String safe(String value) {
        return value == null ? "" : value.trim();
    }

    private static int parseInt(String value, int defaultValue) {
        try { return Integer.parseInt(value); } catch (Exception ex) { return defaultValue; }
    }
}
