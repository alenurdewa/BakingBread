package com.bakingbread.util;

public final class UrlUtils {
    private UrlUtils() {}

    public static String resolve(String contextPath, String rawUrl) {
        if (rawUrl == null) {
            return "";
        }
        String value = rawUrl.trim();
        if (value.isEmpty()) {
            return "";
        }
        if (value.startsWith("http://") || value.startsWith("https://") || value.startsWith("data:") || value.startsWith("blob:")) {
            return value;
        }
        if (contextPath == null) {
            contextPath = "";
        }
        if (!contextPath.isEmpty() && value.startsWith(contextPath + "/")) {
            return value;
        }
        if (value.startsWith("/")) {
            return contextPath + value;
        }
        return contextPath + "/" + value;
    }
}
