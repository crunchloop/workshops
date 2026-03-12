const express = require('express');
const http = require('http');
const { WebSocketServer } = require('ws');
const pty = require('node-pty');
const { randomUUID } = require('crypto');
const path = require('path');
const fs = require('fs');
const { execSync } = require('child_process');

const PORT = process.env.PORT || 8090;
const WORKSHOP_REPO = process.env.WORKSHOP_REPO || 'https://github.com/crunchloop/git-workshop-for-docxers.git';
const WORKSHOP_GIT_TOKEN = process.env.WORKSHOP_GIT_TOKEN || '';
const SESSIONS_DIR = '/tmp/sessions';
const SESSION_TIMEOUT_MS = 30 * 60 * 1000; // 30 minutes

// Ensure sessions directory exists
fs.mkdirSync(SESSIONS_DIR, { recursive: true });

const app = express();

// Route /en and /en/ to index.html
app.get(['/', '/en', '/en/'], (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

// Serve static files
app.use(express.static(__dirname, {
  index: false, // We handle / ourselves
}));

const server = http.createServer(app);
const wss = new WebSocketServer({ server });

// Track active sessions for cleanup
const sessions = new Map();

wss.on('connection', (ws, req) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);
  const userName = url.searchParams.get('name') || 'Workshop User';
  const userEmail = url.searchParams.get('email') || 'user@workshop.local';
  const sessionId = randomUUID();
  const sessionDir = path.join(SESSIONS_DIR, sessionId);

  console.log(`[${sessionId}] New session for ${userName}`);

  try {
    // Create isolated session directory
    fs.mkdirSync(sessionDir, { recursive: true });

    // Build clone URL with token if available
    let cloneUrl = WORKSHOP_REPO;
    if (WORKSHOP_GIT_TOKEN && cloneUrl.startsWith('https://')) {
      cloneUrl = cloneUrl.replace('https://', `https://x-access-token:${WORKSHOP_GIT_TOKEN}@`);
    }

    // Clone the workshop repo
    execSync(`git clone ${cloneUrl} repo`, {
      cwd: sessionDir,
      stdio: 'pipe',
      timeout: 30000,
    });

    const repoDir = path.join(sessionDir, 'repo');

    // Configure git user
    execSync(`git config user.name "${userName.replace(/"/g, '\\"')}"`, { cwd: repoDir, stdio: 'pipe' });
    execSync(`git config user.email "${userEmail.replace(/"/g, '\\"')}"`, { cwd: repoDir, stdio: 'pipe' });

    // Configure credential helper if token is available
    if (WORKSHOP_GIT_TOKEN) {
      execSync(`git config credential.helper '!f() { echo "password=${WORKSHOP_GIT_TOKEN}"; }; f'`, {
        cwd: repoDir,
        stdio: 'pipe',
      });
    }

    // Spawn PTY
    const shell = pty.spawn('/bin/bash', [], {
      name: 'xterm-256color',
      cols: 80,
      rows: 24,
      cwd: repoDir,
      env: {
        ...process.env,
        HOME: sessionDir,
        TERM: 'xterm-256color',
        PS1: '\\[\\033[01;32m\\]workshop\\[\\033[00m\\]:\\[\\033[01;34m\\]\\W\\[\\033[00m\\]$ ',
      },
    });

    sessions.set(sessionId, {
      ws,
      shell,
      sessionDir,
      lastActivity: Date.now(),
    });

    // PTY -> WebSocket
    shell.onData((data) => {
      if (ws.readyState === ws.OPEN) {
        ws.send(JSON.stringify({ type: 'output', data }));
      }
    });

    shell.onExit(() => {
      console.log(`[${sessionId}] PTY exited`);
      cleanup(sessionId);
    });

    // WebSocket -> PTY
    ws.on('message', (msg) => {
      const session = sessions.get(sessionId);
      if (session) session.lastActivity = Date.now();

      try {
        const message = JSON.parse(msg);
        switch (message.type) {
          case 'input':
            shell.write(message.data);
            break;
          case 'resize':
            if (message.cols && message.rows) {
              shell.resize(message.cols, message.rows);
            }
            break;
        }
      } catch {
        // If not JSON, treat as raw input
        shell.write(msg.toString());
      }
    });

    ws.on('close', () => {
      console.log(`[${sessionId}] WebSocket closed`);
      cleanup(sessionId);
    });

    ws.on('error', (err) => {
      console.error(`[${sessionId}] WebSocket error:`, err.message);
      cleanup(sessionId);
    });

  } catch (err) {
    console.error(`[${sessionId}] Setup failed:`, err.message);
    ws.send(JSON.stringify({ type: 'output', data: `\r\nError setting up session: ${err.message}\r\n` }));
    ws.close();
    // Clean up the directory
    try { fs.rmSync(sessionDir, { recursive: true, force: true }); } catch {}
  }
});

function cleanup(sessionId) {
  const session = sessions.get(sessionId);
  if (!session) return;
  sessions.delete(sessionId);

  try { session.shell.kill(); } catch {}
  try {
    if (session.ws.readyState === session.ws.OPEN) session.ws.close();
  } catch {}

  // Clean up session directory
  setTimeout(() => {
    try { fs.rmSync(session.sessionDir, { recursive: true, force: true }); } catch {}
  }, 1000);

  console.log(`[${sessionId}] Cleaned up`);
}

// Periodic cleanup of orphaned sessions
setInterval(() => {
  const now = Date.now();
  for (const [id, session] of sessions) {
    if (now - session.lastActivity > SESSION_TIMEOUT_MS) {
      console.log(`[${id}] Timed out, cleaning up`);
      cleanup(id);
    }
  }
}, 60000);

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Workshop server running on http://localhost:${PORT}`);
  console.log(`Sessions directory: ${SESSIONS_DIR}`);
  if (WORKSHOP_GIT_TOKEN) {
    console.log('Git token configured - push will work');
  } else {
    console.log('No WORKSHOP_GIT_TOKEN set - push will require auth');
  }
});
