/**
 * CS2 Web Radar Server - Node.js Version
 * UDP + WebSocket Real-time Broadcasting
 * 
 * Usage:
 *   npm install ws
 *   node server.js
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const dgram = require('dgram');
const { WebSocketServer } = require('ws');

// ==================== Configuration ====================
const HTTP_PORT = 8080;
const WS_PORT = 8765;
const UDP_PORT = 12345;
const HOST = '127.0.0.1';

// ==================== Data Storage ====================
let radarData = {
    players: [],
    local_player: null,
    map_name: 'Unknown',
    timestamp: 0
};

// ==================== WebSocket Server ====================
const wss = new WebSocketServer({ port: WS_PORT });

console.log(`[WS] WebSocket server running on ws://${HOST}:${WS_PORT}`);

wss.on('connection', (ws) => {
    console.log('[WS] Client connected, total:', wss.clients.size);
    
    // Send initial data immediately
    ws.send(JSON.stringify(radarData));
    
    ws.on('message', (message) => {
        // Handle ping/pong or other messages
        if (message.toString() === 'ping') {
            ws.send(JSON.stringify(radarData));
        }
    });
    
    ws.on('close', () => {
        console.log('[WS] Client disconnected, remaining:', wss.clients.size);
    });
    
    ws.on('error', (err) => {
        console.log('[WS] Client error:', err.message);
    });
});

// Broadcast to all clients
function broadcast() {
    const dataStr = JSON.stringify(radarData);
    wss.clients.forEach((client) => {
        if (client.readyState === 1) { // WebSocket.OPEN
            client.send(dataStr);
        }
    });
}

// ==================== UDP Server ====================
const udpServer = dgram.createSocket('udp4');

udpServer.on('error', (err) => {
    console.log('[UDP] Server error:', err.message);
    udpServer.close();
});

udpServer.on('message', (msg, rinfo) => {
    try {
        radarData = JSON.parse(msg.toString());
        radarData.timestamp = Date.now();
        
        const playerCount = radarData.players?.length || 0;
        const mapName = radarData.map_name || 'Unknown';
        
        // Broadcast immediately to all WebSocket clients
        broadcast();
        
        // Only log periodically (every ~5 seconds worth of messages)
        if (Math.random() < 0.1) {
            console.log(`[UDP] ${playerCount} players, map: ${mapName}`);
        }
    } catch (e) {
        console.log('[UDP] Invalid JSON:', e.message);
    }
});

udpServer.on('listening', () => {
    const address = udpServer.address();
    console.log(`[UDP] Listening on ${address.address}:${address.port}`);
});

udpServer.bind(UDP_PORT, HOST);

// ==================== HTTP Server (Static Files) ====================
const MIME_TYPES = {
    '.html': 'text/html',
    '.js': 'application/javascript',
    '.css': 'text/css',
    '.json': 'application/json',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.gif': 'image/gif',
    '.svg': 'image/svg+xml',
    '.ico': 'image/x-icon'
};

const httpServer = http.createServer((req, res) => {
    let filePath = req.url === '/' ? '/radar.html' : req.url;
    
    // Remove query strings
    filePath = filePath.split('?')[0];
    
    // Security: prevent directory traversal
    filePath = path.normalize(filePath).replace(/^(\.\.[\/\\])+/, '');
    
    const fullPath = path.join(__dirname, filePath);
    const ext = path.extname(fullPath);
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';
    
    // Special handling for /data endpoint (HTTP polling fallback)
    if (req.url === '/data') {
        res.writeHead(200, {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Cache-Control': 'no-cache'
        });
        res.end(JSON.stringify(radarData));
        return;
    }
    
    fs.readFile(fullPath, (err, content) => {
        if (err) {
            if (err.code === 'ENOENT') {
                res.writeHead(404);
                res.end('404 Not Found');
            } else {
                res.writeHead(500);
                res.end('500 Internal Server Error');
            }
        } else {
            res.writeHead(200, { 'Content-Type': contentType });
            res.end(content);
        }
    });
});

httpServer.listen(HTTP_PORT, HOST, () => {
    console.log('='.repeat(60));
    console.log('  CS2 Web Radar Server (Node.js)');
    console.log('='.repeat(60));
    console.log(`  HTTP Server:  http://localhost:${HTTP_PORT}`);
    console.log(`  WebSocket:    ws://localhost:${WS_PORT}`);
    console.log(`  UDP Listener:  ${HOST}:${UDP_PORT}`);
    console.log('='.repeat(60));
    console.log(`  Open radar:   http://localhost:${HTTP_PORT}`);
    console.log('='.repeat(60));
    console.log('  Waiting for Aimware Lua script data...');
    console.log('='.repeat(60));
});

// ==================== Graceful Shutdown ====================
process.on('SIGINT', () => {
    console.log('\n[Server] Shutting down...');
    udpServer.close();
    wss.close();
    httpServer.close();
    process.exit(0);
});
