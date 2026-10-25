const express = require("express");
const http = require("http");
const app = express();
const PORT = Number(process.env.PORT || 3000);
const FLASK_URL = (process.env.FLASK_URL || "").replace(/\/$/, "");

app.get("/", (_req, res) => {
  res.type("html").send(`<!doctype html><html><head><meta charset="utf-8"><title>Terraform Flask + Express</title></head>
  <body style="font-family:Arial,sans-serif;margin:3rem"><h1>Express frontend is running ✅</h1>
  <p>Node.js/Express service deployed for the Terraform assignment.</p>
  <p>Backend endpoint: <a href="/api/hello">/api/hello</a></p></body></html>`);
});

app.get("/api/hello", (req, res) => {
  if (!FLASK_URL) {
    return res.status(200).json({service:"express-frontend", status:"ok",
      message:"Express is healthy. Set FLASK_URL to enable backend forwarding."});
  }
  const target = new URL("/api/hello", FLASK_URL);
  const proxyReq = http.request(target, {method:"GET", timeout:5000}, proxyRes => {
    res.status(proxyRes.statusCode || 502);
    res.setHeader("content-type", proxyRes.headers["content-type"] || "application/json");
    proxyRes.pipe(res);
  });
  proxyReq.on("timeout", () => proxyReq.destroy(new Error("backend timeout")));
  proxyReq.on("error", err => res.status(502).json({error:"Backend request failed", detail:err.message}));
  proxyReq.end();
});

app.get("/health", (_req, res) => res.json({status:"ok", service:"express-frontend"}));
app.listen(PORT, "0.0.0.0", () => console.log(`Express listening on ${PORT}; FLASK_URL=${FLASK_URL || "(unset)"}`));
