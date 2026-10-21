package com.leanbitlab.ltvL;

import com.sun.net.httpserver.HttpServer;
import java.net.InetSocketAddress;
import java.util.concurrent.atomic.AtomicInteger;

public class RemoteWebhookClientTest {
    static void require(boolean value, String message) { if (!value) throw new AssertionError(message); }
    public static void main(String[] args) throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        AtomicInteger posts = new AtomicInteger(), redirected = new AtomicInteger();
        server.createContext("/ok", exchange -> {
            require(exchange.getRequestMethod().equals("POST"), "Use POST");
            require(new String(exchange.getRequestBody().readAllBytes(), java.nio.charset.StandardCharsets.UTF_8).equals("{}"), "Bounded JSON body");
            posts.incrementAndGet(); exchange.sendResponseHeaders(200, -1); exchange.close();
        });
        server.createContext("/redirect", exchange -> {
            exchange.getResponseHeaders().set("Location", "/target"); exchange.sendResponseHeaders(302, -1); exchange.close();
        });
        server.createContext("/target", exchange -> { redirected.incrementAndGet(); exchange.sendResponseHeaders(200,-1); exchange.close(); });
        server.createContext("/fail", exchange -> { posts.incrementAndGet(); exchange.sendResponseHeaders(503,-1); exchange.close(); });
        server.createContext("/slow", exchange -> {
            try { Thread.sleep(500); } catch (InterruptedException ignored) { Thread.currentThread().interrupt(); }
            try { exchange.sendResponseHeaders(200,-1); } catch (java.io.IOException ignored) { }
            exchange.close();
        });
        server.start();
        String base = "http://127.0.0.1:" + server.getAddress().getPort();
        try {
            require(RemoteWebhookClient.post(base + "/ok", 1000), "Accept success");
            require(posts.get() == 1, "One POST per action");
            require(!RemoteWebhookClient.post(base + "/redirect", 1000), "Reject redirect");
            require(redirected.get() == 0, "Never forward secret webhook to redirect target");
            require(!RemoteWebhookClient.post(base + "/fail", 1000), "Report non-success");
            require(posts.get() == 2, "Do not retry failed POST");
            try {
                RemoteWebhookClient.post(base + "/slow", 100);
                throw new AssertionError("Read must time out");
            } catch (java.net.SocketTimeoutException expected) { }
            System.out.println("RemoteWebhookClient: all checks passed");
        } finally { server.stop(0); }
    }
}
