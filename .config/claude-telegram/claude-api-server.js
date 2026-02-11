#!/usr/bin/env node

const http = require('http');
const https = require('https');
const { execSync, exec } = require('child_process');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const os = require('os');

const PORT = process.env.API_PORT || 3456;
const HOST = '127.0.0.1';
const API_KEY = process.env.API_KEY || 'claude-local-key';
const BOT_TOKEN = process.env.BOT_TOKEN || '';
const SESSION_FILE = path.join(os.homedir(), '.config/claude-telegram/current-session');

// Session management
let currentSessionId = null;
let sessionInitialized = false; // true after first --session-id call succeeds

// Request queue to ensure only one claude command runs at a time
let commandQueue = Promise.resolve();

function loadSession() {
  try {
    if (fs.existsSync(SESSION_FILE)) {
      currentSessionId = fs.readFileSync(SESSION_FILE, 'utf8').trim();
      // Check if this session was previously used (jsonl file exists)
      const sessionFile = path.join(os.homedir(), '.claude/projects/-Users-sangil-mo', `${currentSessionId}.jsonl`);
      sessionInitialized = fs.existsSync(sessionFile);
      console.log(`[${new Date().toISOString()}] Loaded session: ${currentSessionId} (initialized: ${sessionInitialized})`);
    } else {
      currentSessionId = crypto.randomUUID();
      saveSession();
      console.log(`[${new Date().toISOString()}] Created new session: ${currentSessionId}`);
    }
  } catch (err) {
    console.error(`[${new Date().toISOString()}] Error loading session:`, err.message);
    currentSessionId = crypto.randomUUID();
    saveSession();
  }
}

function saveSession() {
  try {
    const dir = path.dirname(SESSION_FILE);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    fs.writeFileSync(SESSION_FILE, currentSessionId, 'utf8');
    console.log(`[${new Date().toISOString()}] Saved session: ${currentSessionId}`);
  } catch (err) {
    console.error(`[${new Date().toISOString()}] Error saving session:`, err.message);
  }
}

function createNewSession() {
  const oldSessionId = currentSessionId;
  currentSessionId = crypto.randomUUID();
  sessionInitialized = false;
  saveSession();

  // Delete old session environment
  if (oldSessionId) {
    const oldSessionDir = path.join(os.homedir(), '.claude/session-env', oldSessionId);
    try {
      if (fs.existsSync(oldSessionDir)) {
        execSync(`rm -rf "${oldSessionDir}"`, { encoding: 'utf8' });
        console.log(`[${new Date().toISOString()}] Deleted old session directory: ${oldSessionDir}`);
      }
    } catch (err) {
      console.error(`[${new Date().toISOString()}] Error deleting old session directory:`, err.message);
    }
  }

  return currentSessionId;
}

// Send message to Telegram directly
function sendTelegram(chatId, text, replyToMessageId) {
  if (!BOT_TOKEN) {
    console.log(`[${new Date().toISOString()}] No BOT_TOKEN, skipping Telegram send`);
    return;
  }
  // Truncate to 4000 chars
  if (text.length > 4000) {
    text = text.substring(0, 3900) + '\n\n... (truncated)';
  }
  const body = { chat_id: chatId, text: text };
  if (replyToMessageId) body.reply_to_message_id = replyToMessageId;
  const payload = JSON.stringify(body);
  const options = {
    hostname: 'api.telegram.org',
    path: `/bot${BOT_TOKEN}/sendMessage`,
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(payload) }
  };
  const req = https.request(options, (res) => {
    let body = '';
    res.on('data', c => body += c);
    res.on('end', () => {
      console.log(`[${new Date().toISOString()}] Telegram send ${res.statusCode === 200 ? 'OK' : 'FAIL'}: ${res.statusCode} (${body.length} bytes)`);
    });
  });
  req.on('error', (e) => console.error(`[${new Date().toISOString()}] Telegram request error:`, e.message));
  req.write(payload);
  req.end();
}

// Load session on startup
loadSession();

const server = http.createServer((req, res) => {
  // Log incoming request
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url} from ${req.socket.remoteAddress}`);

  // CORS headers (optional, but useful for local development)
  res.setHeader('Content-Type', 'application/json');
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, X-API-KEY');

  // Handle preflight
  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  // Check auth for all protected endpoints
  const apiKey = req.headers['x-api-key'];
  if (req.url !== '/health') {
    if (apiKey !== API_KEY) {
      console.log(`[${new Date().toISOString()}] Auth failed: ${apiKey}`);
      res.writeHead(401);
      res.end(JSON.stringify({ error: 'Unauthorized' }));
      return;
    }
  }

  // Route handling
  if (req.method === 'GET' && req.url === '/session') {
    // GET /session - Return current session ID
    res.writeHead(200);
    res.end(JSON.stringify({ sessionId: currentSessionId }));
    return;
  }

  if (req.method === 'POST' && req.url === '/session/new') {
    // POST /session/new - Create new session
    const newSessionId = createNewSession();
    console.log(`[${new Date().toISOString()}] Created new session: ${newSessionId}`);
    res.writeHead(200);
    res.end(JSON.stringify({ sessionId: newSessionId }));
    return;
  }

  if (req.method !== 'POST' || req.url !== '/execute') {
    res.writeHead(404);
    res.end(JSON.stringify({ error: 'Not found' }));
    return;
  }

  // Read body
  let body = '';
  req.on('data', chunk => {
    body += chunk.toString();
  });

  req.on('end', () => {
    try {
      const { command, chatId, messageId, commandType } = JSON.parse(body);

      if (!command || typeof command !== 'string') {
        res.writeHead(400);
        res.end(JSON.stringify({ error: 'Missing or invalid command' }));
        return;
      }

      // Auto-inject session flag for claude commands
      let finalCommand = command;
      if (command.includes('claude -p') && !command.includes('--session-id') && !command.includes('--resume')) {
        if (sessionInitialized) {
          // Subsequent calls: use --resume to continue existing session
          finalCommand = command.replace(/claude -p/, `claude -p --resume "${currentSessionId}"`);
        } else {
          // First call: use --session-id to create session
          finalCommand = command.replace(/claude -p/, `claude -p --session-id "${currentSessionId}"`);
        }
      }
      // Redirect stdin from /dev/null to prevent TTY hangs
      if (command.includes('claude ')) {
        finalCommand = finalCommand + ' < /dev/null';
      }

      console.log(`[${new Date().toISOString()}] Executing (async): ${finalCommand.substring(0, 100)}${finalCommand.length > 100 ? '...' : ''}`);

      // Respond immediately - execution happens in background
      res.writeHead(202);
      res.end(JSON.stringify({ status: 'accepted', message: 'Command queued for execution' }));

      // Queue the command execution to ensure only one runs at a time
      commandQueue = commandQueue.then(() => {
        return new Promise((resolve) => {
          const executeCommand = (cmd, isRetry = false) => {
            exec(cmd, {
              encoding: 'utf8',
              timeout: 300000,
              maxBuffer: 10 * 1024 * 1024,
              shell: '/bin/zsh',
              env: { ...process.env }
            }, (error, stdout, stderr) => {
              if (error) {
                // Check for session lock error and retry once
                if (!isRetry && ((stderr || '').includes('already in use') || (stderr || '').includes('Could not resume'))) {
                  console.log(`[${new Date().toISOString()}] Session error detected, creating new session and retrying...`);
                  const newSessionId = createNewSession();
                  // Replace either --resume or --session-id with new --session-id
                  const retryCommand = cmd.replace(/--(?:resume|session-id) "[^"]*"/, `--session-id "${newSessionId}"`);
                  executeCommand(retryCommand, true);
                  return;
                }

                console.log(`[${new Date().toISOString()}] Command failed with exit code ${error.code || 1}`);
                if (chatId) {
                  const prefix = commandType === 'status' ? '📊 ' : '❌ Error:\n\n';
                  sendTelegram(chatId, prefix + (stderr || error.message), messageId);
                }
                resolve();
                return;
              }

              console.log(`[${new Date().toISOString()}] Success (${(stdout || '').length} bytes)`);
              // Mark session as initialized after first successful claude call
              if (cmd.includes('claude -p') && !sessionInitialized) {
                sessionInitialized = true;
                console.log(`[${new Date().toISOString()}] Session initialized: ${currentSessionId}`);
              }
              if (chatId) {
                const prefixes = { ask: '🤖 Claude:\n\n', run: '🚀 Result:\n\n', status: '📊 Status:\n\n' };
                const prefix = prefixes[commandType] || '';
                sendTelegram(chatId, prefix + (stdout || '(no output)'), messageId);
              }
              resolve();
            });
          };

          executeCommand(finalCommand);
        });
      });

    } catch (parseError) {
      console.error(`[${new Date().toISOString()}] Parse error:`, parseError.message);
      res.writeHead(400);
      res.end(JSON.stringify({ error: 'Invalid JSON body' }));
    }
  });

  req.on('error', (err) => {
    console.error(`[${new Date().toISOString()}] Request error:`, err.message);
    res.writeHead(500);
    res.end(JSON.stringify({ error: 'Internal server error' }));
  });
});

// Start server
server.listen(PORT, HOST, () => {
  console.log(`[${new Date().toISOString()}] Claude API Server listening on http://${HOST}:${PORT}`);
  console.log(`[${new Date().toISOString()}] API Key: ${API_KEY}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log(`[${new Date().toISOString()}] SIGTERM received, shutting down gracefully...`);
  server.close(() => {
    console.log(`[${new Date().toISOString()}] Server closed`);
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log(`[${new Date().toISOString()}] SIGINT received, shutting down gracefully...`);
  server.close(() => {
    console.log(`[${new Date().toISOString()}] Server closed`);
    process.exit(0);
  });
});
