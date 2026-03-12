const express = require("express");
const path = require("path");
const fs = require("fs");

const app = express();
const PORT = process.env.PORT || 8090;
const ROOT = __dirname;

// Serve each workshop folder as static files
app.use(express.static(ROOT, { extensions: ["html"] }));

// Landing page: list available workshops
app.get("/", (_req, res) => {
  const workshops = fs
    .readdirSync(ROOT, { withFileTypes: true })
    .filter(
      (d) =>
        d.isDirectory() &&
        !d.name.startsWith(".") &&
        d.name !== "node_modules" &&
        fs.existsSync(path.join(ROOT, d.name, "index.html"))
    )
    .map((d) => d.name);

  const items = workshops
    .map((w) => `<li><a href="/${w}/">${w}</a></li>`)
    .join("\n        ");

  res.send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Workshops — Crunchloop</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif; max-width: 600px; margin: 4em auto; color: #24292e; }
    h1 { border-bottom: 1px solid #e1e4e8; padding-bottom: 0.3em; }
    a { color: #0366d6; text-decoration: none; }
    a:hover { text-decoration: underline; }
    li { margin: 0.5em 0; font-size: 1.1em; }
  </style>
</head>
<body>
  <h1>Workshops</h1>
  <ul>
    ${items}
  </ul>
</body>
</html>`);
});

app.listen(PORT, () => {
  console.log(`Workshops server running at http://localhost:${PORT}`);
});
