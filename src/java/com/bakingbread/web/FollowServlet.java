package com.bakingbread.web;

import com.bakingbread.util.Db;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet(name = "FollowServlet", urlPatterns = {"/profile/follow"})
public class FollowServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession(false);
        Integer idUtente = session != null ? (Integer) session.getAttribute("id_utente") : null;
        if (idUtente == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        int idProfilo = 0;
        try { idProfilo = Integer.parseInt(request.getParameter("id")); } catch (Exception ignore) {}

        if (idProfilo == 0 || idProfilo == idUtente) {
            response.sendRedirect(request.getContextPath() + "/profile.jsp?id=" + idProfilo);
            return;
        }

        String action = request.getParameter("action");

        try (Connection conn = Db.getConnection()) {
            if ("unfollow".equals(action)) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "DELETE FROM Seguito WHERE follower_id = ? AND followed_id = ?")) {
                    ps.setInt(1, idUtente);
                    ps.setInt(2, idProfilo);
                    ps.executeUpdate();
                }
            } else {
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT IGNORE INTO Seguito (follower_id, followed_id) VALUES (?, ?)")) {
                    ps.setInt(1, idUtente);
                    ps.setInt(2, idProfilo);
                    ps.executeUpdate();
                }
            }
        } catch (Exception ex) {
            throw new ServletException("Errore nel salvataggio del follow: " + ex.getMessage(), ex);
        }

        String referer = request.getHeader("Referer");
        if (referer != null && !referer.isEmpty()) {
            response.sendRedirect(referer);
        } else {
            response.sendRedirect(request.getContextPath() + "/profile.jsp?id=" + idProfilo);
        }
    }
}
