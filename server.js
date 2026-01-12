const http = require("http");
const fs = require("fs");
const path = require("path");

const port = Number(process.env.PORT) || 8000;
const host = "0.0.0.0";
const publicDir = __dirname;

const contentTypes = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
};

const server = http.createServer((req, res) => {
  const urlPath = req.url.split("?")[0];
  const filePath = urlPath === "/" ? "index.html" : urlPath.slice(1);
  const resolvedPath = path.join(publicDir, filePath);

  fs.readFile(resolvedPath, (err, data) => {
    if (err) {
      res.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
      res.end("Not found");
      return;
    }

    const ext = path.extname(resolvedPath);
    res.writeHead(200, {
      "Content-Type": contentTypes[ext] || "application/octet-stream",
    });
    res.end(data);
  });
});

server.listen(port, host, () => {
  console.log(`Slot prototype running at http://${host}:${port}`);
});
