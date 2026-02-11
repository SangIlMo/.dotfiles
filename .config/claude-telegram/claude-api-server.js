#!/usr/bin/env node

const http = require('http');
const { execSync } = require('child_process');

const PORT = process.env.API_PORT || 3456;
const HOST = '127.0.0.1';
const API_KEY = process.env.API_KEY || 'claude-local-key';

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

  // Only accept POST /execute
  if (req.method !== 'POST' || req.url !== '/execute') {
    res.writeHead(404);
    res.end(JSON.stringify({ error: 'Not found' }));
    return;
  }

  // Check auth
  const apiKey = req.headers['x-api-key'];
  if (apiKey !== API_KEY) {
    console.log(`[${new Date().toISOString()}] Auth failed: ${apiKey}`);
    res.writeHead(401);
    res.end(JSON.stringify({ error: 'Unauthorized' }));
    return;
  }

  // Read body
  let body = '';
  req.on('data', chunk => {
    body += chunk.toString();
  });

  req.on('end', () => {
    try {
      const { command } = JSON.parse(body);

      if (!command || typeof command !== 'string') {
        res.writeHead(400);
        res.end(JSON.stringify({ error: 'Missing or invalid command' }));
        return;
      }

      console.log(`[${new Date().toISOString()}] Executing: ${command.substring(0, 100)}${command.length > 100 ? '...' : ''}`);

      try {
        // Execute command with timeout and buffer limits
        const stdout = execSync(command, {
          encoding: 'utf8',
          timeout: 120000, // 120 seconds
          maxBuffer: 10 * 1024 * 1024, // 10MB
          shell: '/bin/bash',
          env: { ...process.env }
        });

        const result = {
          stdout: stdout,
          stderr: '',
          exitCode: 0
        };

        console.log(`[${new Date().toISOString()}] Success (${stdout.length} bytes)`);
        res.writeHead(200);
        res.end(JSON.stringify(result));

      } catch (execError) {
        // Command executed but failed (non-zero exit code)
        const result = {
          stdout: execError.stdout ? execError.stdout.toString() : '',
          stderr: execError.stderr ? execError.stderr.toString() : execError.message,
          exitCode: execError.status || 1
        };

        console.log(`[${new Date().toISOString()}] Command failed with exit code ${result.exitCode}`);
        res.writeHead(200); // Still return 200, error is in the command execution
        res.end(JSON.stringify(result));
      }

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
