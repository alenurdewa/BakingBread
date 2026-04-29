package com.bakingbread.web;

import com.bakingbread.util.Db;
import com.bakingbread.util.FileStore;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;

@WebServlet(name = "ProfileUpdateServlet", urlPatterns = {"/profile/update"})
@MultipartConfig(maxFileSize = 5 * 1024 * 1024, maxRequestSize = 10 * 1024 * 1024)
public class ProfileUpdateServlet extends HttpServlet {

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

        String nomeVisualizzato = safe(request.getParameter("nome_visualizzato"));
        String email = safe(request.getParameter("email"));
        String bio = safe(request.getParameter("bio"));
        String currentAvatar = safe(request.getParameter("current_avatar_url"));
        String avatarUrl = currentAvatar;
        String manualAvatarUrl = safe(request.getParameter("avatar_url"));

        try {
            Part avatarPart = request.getPart("avatar_file");
            if (avatarPart != null && avatarPart.getSize() > 0 && avatarPart.getSubmittedFileName() != null && !avatarPart.getSubmittedFileName().trim().isEmpty()) {
                avatarUrl = request.getContextPath() + FileStore.savePart(avatarPart, getServletContext(), "avatars", "avatar_" + idUtente);
            } else if (!manualAvatarUrl.isEmpty()) {
                avatarUrl = manualAvatarUrl;
            }
        } catch (Exception ignore) {
            if (!manualAvatarUrl.isEmpty()) {
                avatarUrl = manualAvatarUrl;
            }
        }

        if (nomeVisualizzato.isEmpty() || email.isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/impostazioni.jsp?err=campi");
            return;
        }

        try (Connection conn = Db.getConnection();
             PreparedStatement ps = conn.prepareStatement("UPDATE Utente SET nome_visualizzato = ?, email = ?, avatar_url = ?, bio = ?, aggiornato_il = NOW() WHERE id_utente = ?")) {
            ps.setString(1, nomeVisualizzato);
            ps.setString(2, email);
            ps.setString(3, avatarUrl.isEmpty() ? null : avatarUrl);
            ps.setString(4, bio.isEmpty() ? null : bio);
            ps.setInt(5, idUtente);
            ps.executeUpdate();
            session.setAttribute("nome_utente", nomeVisualizzato);
            session.setAttribute("avatar_url", avatarUrl);
            response.sendRedirect(request.getContextPath() + "/impostazioni.jsp?ok=1");
        } catch (ClassNotFoundException e) {
            throw new ServletException("Driver JDBC non trovato.", e);
        } catch (SQLException e) {
            response.sendRedirect(request.getContextPath() + "/impostazioni.jsp?err=db");
        }
    }

    private static String safe(String value) {
        return value == null ? "" : value.trim();
    }
}
