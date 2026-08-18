/**
 * Test simulator for the radar server.
 * Sends fake INIT / MID / HIGH packets to verify server.js decodes them correctly.
 *
 * Usage:
 *   node test_simulator.js
 *
 * Expect server.js running on port 12345 (UDP) and 8080 (HTTP).
 */

const dgram = require('dgram');
const http = require('http');

const UDP_PORT = 12345;

function send(msg) {
    const client = dgram.createSocket('udp4');
    const buf = Buffer.from(msg);
    client.send(buf, UDP_PORT, '127.0.0.1', (err) => {
        if (err) console.log('Send err:', err.message);
        client.close();
    });
    console.log(`[SENT] (${buf.length} bytes):`, msg.substring(0, 100) + (msg.length > 100 ? '...' : ''));
}

console.log('=== Radar Test Simulator ===\n');

// 1. INIT packet
setTimeout(() => {
    const init = JSON.stringify({
        t: 'init',
        r: 5,
        m: 'de_dust2',
        ts: 3,
        es: 2,
        p: [
            { i: 1, n: 'Alice', s: '76561198000000001', t: 2, f: 3 },
            { i: 2, n: 'Bob',   s: '76561198000000002', t: 2, f: 2 },
            { i: 3, n: 'Enemy1', s: '76561198000000003', t: 3, f: 0 },
            { i: 4, n: 'Enemy2', s: '76561198000000004', t: 3, f: 0 },
        ]
    });
    send('INIT:' + init);
}, 200);

// 2. MID packet
setTimeout(() => {
    const mid = JSON.stringify({
        t: 'mid',
        ts: 3,
        es: 2,
        p: [
            { i: 1, n: 'Alice', t: 2, f: 3, hp: 100, ar: 50, m: 4000, hb: 1, w: 'weapon_ak47' },
            { i: 2, n: 'Bob',   t: 2, f: 2, hp: 75,  ar: 0,  m: 2400, hb: 0, w: 'weapon_m4a1' },
            { i: 3, n: 'Enemy1', t: 3, f: 0, hp: 100, ar: 100, m: 5800, hb: 0, w: 'weapon_awp' },
            { i: 4, n: 'Enemy2', t: 3, f: 0, hp: 100, ar: 0, m: 1600, hb: 0, w: 'weapon_knife' },
        ]
    });
    send('MID:' + mid);
}, 800);

// 3. HIGH packet
setTimeout(() => {
    const high = JSON.stringify({
        t: 'hi',
        r: 5,
        p: [
            [1, -2400, 3380, 100, 3],
            [2, -2300, 3200, 75, 5],
            [3, -2100, 3500, 100, 1],
            [4, -2200, 3600, 100, 1],
        ]
    });
    send('HIGH|' + high);
}, 1400);

// 4. Multiple HIGH updates
let i = 0;
const hi = setInterval(() => {
    i++;
    const high = JSON.stringify({
        t: 'hi',
        r: 5,
        p: [
            [1, -2400 + i * 10, 3380 + i * 5, 100, 3],
            [2, -2300 + i * 8,  3200 - i * 3, 75,  5],
            [3, -2100 - i * 5,  3500 + i * 7, 100, 1],
            [4, -2200 + i * 6,  3600 - i * 2, 100, 1],
        ]
    });
    send('HIGH|' + high);
    if (i >= 5) clearInterval(hi);
}, 300);

// 5. Check /data endpoint
setTimeout(() => {
    http.get('http://127.0.0.1:8080/data', (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => {
            console.log('\n=== /data response ===');
            try {
                const obj = JSON.parse(data);
                console.log(`Map: ${obj.map_name}, Round: ${obj.round_number}`);
                console.log(`Score: ${obj.team_score}:${obj.enemy_score}`);
                console.log(`Players: ${obj.players.length}`);
                obj.players.forEach(p => {
                    console.log(`  [${p.index}] ${p.name} team=${p.team} hp=${p.hp} pos=(${p.x},${p.y}) alive=${p.is_alive} avatar=${p.avatar_url ? 'YES' : 'NO'}`);
                });
                console.log('=== Server decoded correctly! ===');
            } catch (e) {
                console.log('Parse error:', e.message);
                console.log('Raw:', data);
            }
        });
    }).on('error', (e) => {
        console.log('GET /data error:', e.message);
    });
}, 3000);