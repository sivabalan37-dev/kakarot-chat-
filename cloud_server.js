#!/usr/bin/env node
/*
  cloud_server.js - private relay + mailbox for the Kakarot friends chat.
  Zero dependencies. Needs Node 18+.   Run:  node cloud_server.js   (honours PORT)

  WHAT IT DOES
    - Keeps each conversation as an ordered log of ENCRYPTED messages. The app encrypts
      (AES-GCM) before sending and never gives this server the encryption key, so the
      server cannot read anything it stores.
    - Pushes new messages live to everyone in the room (Server-Sent Events) and lets a
      friend who was offline catch up later. Also works as a fallback when peer-to-peer
      (WebRTC) cannot connect.
    - What the server can still see: room id, IP addresses, timing, message sizes.
      Put the sender name INSIDE the encrypted payload and leave "from" out if you
      want even that hidden.

  API   (<id> = 16-64 hex chars, <key> = 22-128 chars of [A-Za-z0-9_-];
         both are derived from the shared passphrase inside the app)
    POST   /v1/rooms/<id>/messages   body {ct, iv?, from?, cid?, kind?}  -> {seq, ts}
    GET    /v1/rooms/<id>/messages?after=<seq>&limit=200  or  ?tail=50   -> {messages, last}
    GET    /v1/rooms/<id>/stream?after=<seq>   live events: "msg" and "presence" {online}
    DELETE /v1/rooms/<id>                      wipes the conversation from the server
    GET    /health                             -> {ok:true}
    Auth: header  X-Room-Key: <key>   (EventSource cannot set headers, so ?k=<key> works too)
    The first client to use a room id claims it; everyone else must present the same key.
    "cid" is a client message id: a message re-sent with the same cid is stored only once,
    so the app can safely send over both WebRTC and the server.

  SETTINGS (env vars, all optional)
    PORT 8787 | DATA_FILE ./cloud_data.json | KEEP_DAYS 90 (0 = keep forever)
    MAX_MSGS 2000 per room | MAX_ROOM_KB 2048 per room | MAX_ROOMS 100 | TRUST_PROXY 1

  DEPLOY (Render example): New > Web Service > this repo, Build Command empty,
    Start Command  node cloud_server.js  . Note: free hosts wipe the disk on restart,
    so stored history only lasts as long as the instance does.
*/
'use strict';
const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const num = (k, d) => (process.env[k] && !Number.isNaN(Number(process.env[k])) ? Number(process.env[k]) : d);
const PORT = num('PORT', 8787);
const DATA_FILE = process.env.DATA_FILE || path.join(__dirname, 'cloud_data.json');
const KEEP_DAYS = num('KEEP_DAYS', 90);
const MAX_MSGS = num('MAX_MSGS', 2000);
const MAX_ROOM_BYTES = num('MAX_ROOM_KB', 2048) * 1024;
const MAX_ROOMS = num('MAX_ROOMS', 100);
const TRUST_PROXY = process.env.TRUST_PROXY !== '0';
const MAX_BODY = 256 * 1024;
const DAY = 86400000;

const ID_RE = /^[a-f0-9]{16,64}$/;
const KEY_RE = /^[A-Za-z0-9_-]{22,128}$/;
const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET,POST,DELETE,OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type,X-Room-Key,Last-Event-ID',
  'Access-Control-Max-Age': '86400',
};

/* ---------- state + persistence ---------- */
let rooms = Object.create(null);   // id -> {salt, auth, seq, bytes, touched, msgs[]}
const streams = new Map();         // id -> Set of open SSE responses
const ipStreams = new Map();       // ip -> open SSE count
const hits = new Map();            // ip -> {n, t} request counter
let dirty = false;

const msgSize = (m) => m.ct.length + 120;
const recount = (r) => { r.bytes = r.msgs.reduce((s, m) => s + msgSize(m), 0); };

try {
  const saved = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
  for (const [id, r] of Object.entries(saved.rooms || {})) {
    if (ID_RE.test(id) && r && Array.isArray(r.msgs)) { recount(r); rooms[id] = r; }
  }
  console.log(`loaded ${Object.keys(rooms).length} room(s) from ${DATA_FILE}`);
} catch (e) {
  if (e.code !== 'ENOENT') console.error('could not load saved data:', e.message);
}

function save() {
  if (!dirty) return;
  dirty = false;
  try {
    const tmp = DATA_FILE + '.tmp';
    fs.writeFileSync(tmp, JSON.stringify({ v: 1, rooms }));
    fs.renameSync(tmp, DATA_FILE);
  } catch (e) {
    dirty = true;
    console.error('save failed:', e.message);
  }
}
setInterval(save, 3000).unref();

/* ---------- helpers ---------- */
function send(res, code, obj, extra) {
  const body = JSON.stringify(obj);
  res.writeHead(code, Object.assign({}, CORS, extra, {
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store',
    'Content-Length': Buffer.byteLength(body),
  }));
  res.end(body);
}

function readBody(req, limit) {
  return new Promise((resolve, reject) => {
    let size = 0;
    const chunks = [];
    req.on('data', (c) => {
      size += c.length;
      if (size > limit) { chunks.length = 0; req.pause(); reject(Object.assign(new Error('too large'), { status: 413 })); return; }
      chunks.push(c);
    });
    req.on('end', () => resolve(Buffer.concat(chunks).toString('utf8')));
    req.on('error', reject);
  });
}

function ipOf(req) {
  if (TRUST_PROXY && req.headers['x-forwarded-for']) return String(req.headers['x-forwarded-for']).split(',')[0].trim();
  return req.socket.remoteAddress || 'unknown';
}

function tooMany(ip) {
  const now = Date.now();
  let h = hits.get(ip);
  if (!h || now - h.t > 60000) { h = { n: 0, t: now }; hits.set(ip, h); }
  return ++h.n > 120;   // 120 requests per minute per IP
}
setInterval(() => { const now = Date.now(); for (const [ip, h] of hits) if (now - h.t > 60000) hits.delete(ip); }, 60000).unref();

const hashKey = (salt, key) => crypto.createHash('sha256').update(salt).update(key).digest('hex');

// First contact claims the room; later contact must present the same key.
function openRoom(id, key) {
  let r = rooms[id];
  if (!r) {
    if (Object.keys(rooms).length >= MAX_ROOMS) return { status: 503, error: 'server full' };
    const salt = crypto.randomBytes(16).toString('hex');
    r = rooms[id] = { salt, auth: hashKey(salt, key), seq: 0, bytes: 0, touched: Date.now(), msgs: [] };
    dirty = true;
    return { room: r };
  }
  const a = Buffer.from(hashKey(r.salt, key), 'hex');
  const b = Buffer.from(r.auth, 'hex');
  if (a.length !== b.length || !crypto.timingSafeEqual(a, b)) return { status: 403, error: 'wrong room key' };
  r.touched = Date.now();
  return { room: r };
}

function cleanMsg(b) {
  if (!b || typeof b !== 'object' || Array.isArray(b)) return null;
  if (typeof b.ct !== 'string' || !b.ct || b.ct.length > 200000) return null;
  const m = { ct: b.ct };
  for (const [k, max] of [['iv', 64], ['from', 48], ['cid', 64], ['kind', 16]]) {
    if (b[k] === undefined) continue;
    if (typeof b[k] !== 'string' || b[k].length > max) return null;
    m[k] = b[k];
  }
  return m;
}

function fanout(id, event, data, evId) {
  const set = streams.get(id);
  if (!set) return;
  const payload = (evId ? `id: ${evId}\n` : '') + `event: ${event}\ndata: ${JSON.stringify(data)}\n\n`;
  for (const res of set) res.write(payload);
}

function addMessage(id, r, m) {
  if (m.cid) {
    const dup = r.msgs.slice(-500).find((x) => x.cid === m.cid);
    if (dup) return dup;
  }
  const msg = Object.assign({ seq: ++r.seq, ts: Date.now() }, m);
  r.msgs.push(msg);
  r.bytes += msgSize(msg);
  while (r.msgs.length > 1 && (r.msgs.length > MAX_MSGS || r.bytes > MAX_ROOM_BYTES)) r.bytes -= msgSize(r.msgs.shift());
  dirty = true;
  fanout(id, 'msg', msg, msg.seq);
  return msg;
}

function openStream(req, res, ip, id, r, after) {
  const n = (ipStreams.get(ip) || 0) + 1;
  let set = streams.get(id);
  if (n > 10 || (set && set.size >= 20)) return send(res, 429, { error: 'too many live connections' });
  if (!set) streams.set(id, (set = new Set()));
  ipStreams.set(ip, n);
  res.writeHead(200, Object.assign({}, CORS, {
    'Content-Type': 'text/event-stream; charset=utf-8',
    'Cache-Control': 'no-cache, no-transform',
    Connection: 'keep-alive',
    'X-Accel-Buffering': 'no',
  }));
  res.write('retry: 3000\n\n');
  for (const m of r.msgs) if (m.seq > after) res.write(`id: ${m.seq}\nevent: msg\ndata: ${JSON.stringify(m)}\n\n`);
  set.add(res);
  fanout(id, 'presence', { online: set.size });
  const ping = setInterval(() => res.write(': ping\n\n'), 20000);
  res.on('error', () => {});
  res.on('close', () => {
    clearInterval(ping);
    set.delete(res);
    ipStreams.set(ip, Math.max(0, (ipStreams.get(ip) || 1) - 1));
    if (set.size) fanout(id, 'presence', { online: set.size }); else streams.delete(id);
  });
}

/* ---------- http ---------- */
const server = http.createServer(async (req, res) => {
  try {
    const url = new URL(req.url, 'http://x');
    const p = url.pathname.replace(/\/+$/, '') || '/';
    if (req.method === 'OPTIONS') { res.writeHead(204, CORS); return res.end(); }
    if (p === '/' || p === '/health') return send(res, 200, { ok: true });

    const m = /^\/v1\/rooms\/([a-f0-9]{16,64})(?:\/(messages|stream))?$/.exec(p);
    if (!m) return send(res, 404, { error: 'not found' });
    const id = m[1];
    const part = m[2];
    const ip = ipOf(req);
    if (tooMany(ip)) return send(res, 429, { error: 'slow down' });

    const key = req.headers['x-room-key'] || url.searchParams.get('k') || '';
    if (!KEY_RE.test(key)) return send(res, 401, { error: 'missing or malformed room key' });
    const opened = openRoom(id, key);
    if (!opened.room) return send(res, opened.status, { error: opened.error });
    const r = opened.room;

    if (!part && req.method === 'DELETE') {
      for (const s of streams.get(id) || []) s.end();
      streams.delete(id);
      delete rooms[id];
      dirty = true;
      return send(res, 200, { ok: true });
    }
    if (part === 'messages' && req.method === 'POST') {
      let body;
      try { body = JSON.parse(await readBody(req, MAX_BODY)); } catch (e) { if (e.status) throw e; return send(res, 400, { error: 'bad json' }); }
      const msg = cleanMsg(body);
      if (!msg) return send(res, 400, { error: 'bad message' });
      const saved = addMessage(id, r, msg);
      return send(res, 201, { seq: saved.seq, ts: saved.ts });
    }
    if (part === 'messages' && req.method === 'GET') {
      const q = url.searchParams;
      const tail = parseInt(q.get('tail'), 10);
      let out;
      if (tail > 0) out = r.msgs.slice(-Math.min(tail, 500));
      else {
        const after = Math.max(0, parseInt(q.get('after'), 10) || 0);
        const limit = Math.min(500, Math.max(1, parseInt(q.get('limit'), 10) || 200));
        out = r.msgs.filter((x) => x.seq > after).slice(0, limit);
      }
      return send(res, 200, { messages: out, last: r.seq });
    }
    if (part === 'stream' && req.method === 'GET') {
      const after = parseInt(req.headers['last-event-id'], 10) || parseInt(url.searchParams.get('after'), 10) || 0;
      return openStream(req, res, ip, id, r, after);
    }
    return send(res, 405, { error: 'method not allowed' });
  } catch (e) {
    if (res.headersSent) return;
    if (e.status === 413) return send(res, 413, { error: 'message too large' }, { Connection: 'close' });
    console.error('request failed:', e.message);
    return send(res, 500, { error: 'server error' });
  }
});
server.keepAliveTimeout = 65000;   // longer than typical proxy idle timeouts
server.headersTimeout = 66000;

/* ---------- housekeeping ---------- */
setInterval(() => {
  const now = Date.now();
  for (const id of Object.keys(rooms)) {
    const r = rooms[id];
    if (KEEP_DAYS > 0) {
      const before = r.msgs.length;
      r.msgs = r.msgs.filter((m) => m.ts >= now - KEEP_DAYS * DAY);
      if (r.msgs.length !== before) { recount(r); dirty = true; }
    }
    if (!r.msgs.length && !streams.has(id) && r.touched < now - 7 * DAY) { delete rooms[id]; dirty = true; }
  }
}, 3600000).unref();

function shutdown() { save(); process.exit(0); }
process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);

server.listen(PORT, '0.0.0.0', () => console.log(`cloud server listening on :${PORT}`));
