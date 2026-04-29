package com.bakingbread.web;

import com.bakingbread.util.Db;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet(name = "CommentServlet", urlPatterns = {"/recipe/comment"})
public class CommentServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession(false);
        Integer idUtente = session != null ? (Integer) session.getAttribute("id_utente") : null;
        if (idUtente == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        int idRicetta = parseInt(request.getParameter("id_ricetta"), 0);
        String testo = safe(request.getParameter("testo"));
        int parentCommento = parseInt(request.getParameter("parent_commento"), 0);

        if (idRicetta <= 0 || testo.isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/dettaglio_ricetta.jsp?id=" + idRicetta + "#commenti");
            return;
        }

        try (Connection conn = Db.getConnection();
             PreparedStatement ps = conn.prepareStatement("INSERT INTO Commento (id_ricetta, id_utente, parent_commento, testo) VALUES (?, ?, ?, ?)") ) {
            ps.setInt(1, idRicetta);
            ps.setInt(2, idUtente);
            if (parentCommento > 0) ps.setInt(3, parentCommento); else ps.setNull(3, java.sql.Types.INTEGER);
            ps.setString(4, testo);
            ps.executeUpdate();
        } catch (ClassNotFoundException e) {
            throw new ServletException("Driver JDBC non trovato.", e);
        } catch (SQLException e) {
            throw new ServletException("Errore nel salvataggio del commento: " + e.getMessage(), e);
        }

        response.sendRedirect(request.getContextPath() + "/dettaglio_ricetta.jsp?id=" + idRicetta + "#commenti");
    }

    private static String safe(String value) {
        return value == null ? "" : value.trim();
    }

    private static int parseInt(String value, int defaultValue) {
        try { return Integer.parseInt(value); } catch (Exception ex) { return defaultValue; }
    }
}
