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

// Steam Web API key (optional; if set, uses GetPlayerSummaries for batch queries)
// Set via env: STEAM_API_KEY=xxxxx node server.js
// Without key: fallback to scraping public Steam profile XML pages (no key needed).
const STEAM_API_KEY = process.env.STEAM_API_KEY || '';

// ==================== Avatar Cache ====================
// In-memory cache: steamid64 -> { avatarfull, avatar, avatarmedium, personaname, fetched }
const avatarCache = new Map();
const AVATAR_TTL_MS = 30 * 60 * 1000; // 30 min
const AVATAR_FETCH_TIMEOUT_MS = 5000;

// ==================== SteamID format normalization ====================
// Accepts: SteamID64 (17 digits), STEAM_0:X:Y, [U:1:W]
// Returns SteamID64 string or null.
function normalizeSteamID(sid) {
    if (!sid || typeof sid !== 'string') return null;
    sid = sid.trim();
    // SteamID64 (17 digits, starts with 7656)
    if (/^7656\d{13}$/.test(sid)) return sid;
    // STEAM_0:Y:Z -> 76561197960265728 + Z*2 + Y
    const steamX = sid.match(/^STEAM_[0-9]:([0-9]):([0-9]+)$/);
    if (steamX) {
        const y = parseInt(steamX[1]);
        const z = parseInt(steamX[2]);
        return (BigInt(76561197960265728) + BigInt(z * 2 + y)).toString();
    }
    // [U:1:W] -> 76561197960265728 + W
    const u1 = sid.match(/^\[U:1:(\d+)\]$/);
    if (u1) {
        return (BigInt(76561197960265728) + BigInt(u1[1])).toString();
    }
    return null;
}

// ==================== Fetch Avatar (No Key, via public XML) ====================
// Scrapes https://steamcommunity.com/profiles/<SteamID64>?xml=1 (no API key required).
// Returns { avatarfull, avatar, avatarmedium, personaname } or null on failure.
async function fetchAvatarFromXML(steamid64) {
    try {
        const url = `https://steamcommunity.com/profiles/${steamid64}?xml=1`;
        const controller = new AbortController();
        const timer = setTimeout(() => controller.abort(), AVATAR_FETCH_TIMEOUT_MS);
        const res = await fetch(url, {
            signal: controller.signal,
            headers: {
                'User-Agent': 'Mozilla/5.0 (compatible; CS2Radar/1.0)',
                'Accept': 'text/xml,application/xml'
            }
        });
        clearTimeout(timer);
        if (!res.ok) {
            console.log(`[Avatar] HTTP ${res.status} for ${steamid64}`);
            return null;
        }
        const text = await res.text();
        const grab = (tag) => {
            const m = text.match(new RegExp(`<${tag}><!\\[CDATA\\[(.*?)\\]\\]></${tag}>`, 'i'));
            return m ? m[1] : null;
        };
        const avatarfull = grab('avatarFull');
        if (!avatarfull) return null; // profile is private or no avatar
        return {
            avatar: grab('avatarIcon'),
            avatarmedium: grab('avatarMedium'),
            avatarfull,
            personaname: grab('steamID'),
            fetched: Date.now()
        };
    } catch (e) {
        console.log(`[Avatar] ${steamid64}: ${e.message}`);
        return null;
    }
}

// ==================== Fetch Avatar (Web API, batch) ====================
// Uses Steam Web API (STEAM_API_KEY) for batch efficiency. Falls back to XML per-id.
async function fetchSteamAvatars(steamids) {
    if (steamids.length === 0) return {};
    const now = Date.now();
    const missing = [];
    for (const sid of steamids) {
        const cached = avatarCache.get(sid);
        if (!cached || (now - cached.fetched) > AVATAR_TTL_MS) {
            missing.push(sid);
        }
    }
    const result = {};
    // Servce cached entries first
    for (const sid of steamids) {
        const cached = avatarCache.get(sid);
        if (cached) result[sid] = cached;
    }

    if (missing.length === 0) return result;

    // Try Web API batch first (if key set)
    if (STEAM_API_KEY) {
        try {
            const idsParam = missing.join(',');
            const url = `https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=${STEAM_API_KEY}&steamids=${idsParam}`;
            const controller = new AbortController();
            const timer = setTimeout(() => controller.abort(), AVATAR_FETCH_TIMEOUT_MS);
            const res = await fetch(url, { signal: controller.signal });
            clearTimeout(timer);
            if (res.ok) {
                const data = await res.json();
                const players = data?.response?.players || [];
                const fetched = Date.now();
                for (const p of players) {
                    const entry = {
                        avatar: p.avatar,
                        avatarmedium: p.avatarmedium,
                        avatarfull: p.avatarfull,
                        personaname: p.personaname,
                        fetched
                    };
                    avatarCache.set(p.steamid, entry);
                    result[p.steamid] = entry;
                }
                console.log(`[SteamAPI] ${players.length}/${missing.length} avatars`);
                return result;
            }
            console.log(`[SteamAPI] HTTP ${res.status}, falling back to XML`);
        } catch (e) {
            console.log(`[SteamAPI] ${e.message}, falling back to XML`);
        }
    }

    // Fallback: parallel XML scrape (no key needed)
    const xmlResults = await Promise.all(missing.map(async (sid) => {
        const entry = await fetchAvatarFromXML(sid);
        return [sid, entry];
    }));
    for (const [sid, entry] of xmlResults) {
        if (entry) {
            avatarCache.set(sid, entry);
            result[sid] = entry;
        }
    }
    const ok = xmlResults.filter(([, e]) => e).length;
    console.log(`[AvatarXML] ${ok}/${missing.length} avatars fetched`);
    return result;
}

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

    // /avatars?steamids=7656119...,STEAM_0:1:12345,[U:1:12345] -> { sid: avatarObj }
    // Accepts SteamID64, STEAM_x:y:z, and [U:1:W] formats. No API key required.
    if (req.url.startsWith('/avatars')) {
        const urlObj = new URL(req.url, 'http://localhost');
        const steamidsParam = urlObj.searchParams.get('steamids') || '';
        const rawIds = steamidsParam.split(',').map(s => s.trim()).filter(s => s.length > 0).slice(0, 100);
        const normalized = [];
        const idMap = new Map(); // normalized -> raw
        for (const raw of rawIds) {
            const norm = normalizeSteamID(raw);
            if (norm) {
                normalized.push(norm);
                idMap.set(norm, raw);
            }
        }
        if (normalized.length === 0) {
            res.writeHead(400, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' });
            res.end(JSON.stringify({ error: 'no valid steamids', got: rawIds }));
            return;
        }
        fetchSteamAvatars(normalized).then(result => {
            res.writeHead(200, {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Cache-Control': 'public, max-age=600'
            });
            res.end(JSON.stringify(result));
        }).catch(err => {
            res.writeHead(500, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' });
            res.end(JSON.stringify({ error: err.message }));
        });
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
