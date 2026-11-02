// Painel do SWX2: recebe os avisos anônimos do SWX2 (POST /api/ping) e mostra quem está jogando.
// Sem dependências: Node 24 (node:http + node:sqlite).
//
// Variáveis de ambiente:
//   ADMIN_PASSWORD  senha do painel (obrigatória)
//   ADMIN_USER      usuário do painel (padrão: admin)
//   PORT            porta (padrão: 3000)
//   DATA_DIR        pasta do banco (padrão: /data)

import http from 'node:http';
import { DatabaseSync } from 'node:sqlite';
import { timingSafeEqual, createHash } from 'node:crypto';
import { mkdirSync, readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const PORT = Number(process.env.PORT || 3000);
const DATA_DIR = process.env.DATA_DIR || '/data';
const ADMIN_USER = process.env.ADMIN_USER || 'admin';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || '';
if (!ADMIN_PASSWORD) {
  console.error('Defina ADMIN_PASSWORD.');
  process.exit(1);
}

// O SWX2 manda um aviso a cada 5 minutos; quem avisou nos últimos 6 está online.
const BEAT_MINUTES = 5;
const ONLINE_MS = 6 * 60 * 1000;
const KEEP_DAYS = 90;

mkdirSync(DATA_DIR, { recursive: true });
const db = new DatabaseSync(path.join(DATA_DIR, 'swx2.db'));
db.exec(`
  PRAGMA journal_mode = WAL;
  CREATE TABLE IF NOT EXISTS installs (id TEXT PRIMARY KEY, first_seen INTEGER, last_seen INTEGER, version TEXT, game TEXT, serial TEXT, game_since INTEGER);
  CREATE TABLE IF NOT EXISTS beats (id TEXT, ts INTEGER, game TEXT, serial TEXT);
  CREATE INDEX IF NOT EXISTS beats_ts ON beats (ts);
  CREATE TABLE IF NOT EXISTS days (id TEXT, day TEXT, PRIMARY KEY (id, day));
`);

const upsertInstall = db.prepare(`
  INSERT INTO installs (id, first_seen, last_seen, version, game, serial, game_since) VALUES (?, ?, ?, ?, ?, ?, ?)
  ON CONFLICT (id) DO UPDATE SET last_seen = excluded.last_seen, version = excluded.version,
    game_since = CASE WHEN installs.game IS excluded.game AND installs.last_seen > ? THEN installs.game_since ELSE excluded.game_since END,
    game = excluded.game, serial = excluded.serial`);
const insertBeat = db.prepare('INSERT INTO beats (id, ts, game, serial) VALUES (?, ?, ?, ?)');
const insertDay = db.prepare('INSERT OR IGNORE INTO days (id, day) VALUES (?, ?)');

function clean(value, max) {
  if (typeof value !== 'string') return null;
  const text = value.replace(/[\u0000-\u001f\u007f]/g, '').trim().slice(0, max);
  return text || null;
}

function recordPing(body) {
  const id = typeof body.id === 'string' && /^[0-9a-f-]{16,64}$/i.test(body.id) ? body.id.toLowerCase() : null;
  if (!id) return false;
  const now = Date.now();
  const game = clean(body.game, 200);
  const serial = clean(body.serial, 32);
  const version = clean(body.v, 32);
  upsertInstall.run(id, now, now, version, game, serial, game ? now : null, now - ONLINE_MS);
  insertDay.run(id, new Date(now).toISOString().slice(0, 10));
  if (game) insertBeat.run(id, now, game, serial);
  return true;
}

function stats() {
  const now = Date.now();
  const online = now - ONLINE_MS;
  const week = now - 7 * 86400000;
  const one = (sql, ...args) => db.prepare(sql).get(...args);
  const all = (sql, ...args) => db.prepare(sql).all(...args);
  return {
    now,
    online: one('SELECT COUNT(*) AS n FROM installs WHERE last_seen > ?', online).n,
    playing: one('SELECT COUNT(*) AS n FROM installs WHERE last_seen > ? AND game IS NOT NULL', online).n,
    installs: one('SELECT COUNT(*) AS n FROM installs').n,
    newWeek: one('SELECT COUNT(*) AS n FROM installs WHERE first_seen > ?', week).n,
    activeWeek: one('SELECT COUNT(*) AS n FROM installs WHERE last_seen > ?', week).n,
    playingNow: all(`SELECT substr(id, 1, 8) AS who, game, serial, version, game_since AS since FROM installs
      WHERE last_seen > ? AND game IS NOT NULL ORDER BY game_since`, online),
    topGames: all(`SELECT game, serial, COUNT(*) * ${BEAT_MINUTES} AS minutes, COUNT(DISTINCT id) AS players FROM beats
      WHERE ts > ? GROUP BY game ORDER BY minutes DESC LIMIT 15`, week),
    daily: all(`SELECT day, COUNT(*) AS n FROM days WHERE day >= ? GROUP BY day ORDER BY day`,
      new Date(now - 29 * 86400000).toISOString().slice(0, 10)),
    versions: all(`SELECT COALESCE(version, '?') AS version, COUNT(*) AS n FROM installs WHERE last_seen > ? GROUP BY version ORDER BY n DESC`, week),
  };
}

// Limpa avisos antigos uma vez por dia.
function prune() {
  db.prepare('DELETE FROM beats WHERE ts < ?').run(Date.now() - KEEP_DAYS * 86400000);
  db.prepare('DELETE FROM days WHERE day < ?').run(new Date(Date.now() - KEEP_DAYS * 86400000).toISOString().slice(0, 10));
}
prune();
setInterval(prune, 86400000).unref();

// Limite simples por IP (só em memória, o IP não é gravado).
const hits = new Map();
setInterval(() => hits.clear(), 60000).unref();
function limited(req) {
  const ip = req.headers['cf-connecting-ip'] || req.socket.remoteAddress || '?';
  const count = (hits.get(ip) || 0) + 1;
  hits.set(ip, count);
  return count > 30;
}

const digest = (text) => createHash('sha256').update(text).digest();
const expectedAuth = digest(`${ADMIN_USER}:${ADMIN_PASSWORD}`);
function authorized(req) {
  const header = req.headers.authorization || '';
  if (!header.startsWith('Basic ')) return false;
  const given = digest(Buffer.from(header.slice(6), 'base64').toString('utf8'));
  return timingSafeEqual(given, expectedAuth);
}

const dashboard = readFileSync(path.join(path.dirname(fileURLToPath(import.meta.url)), 'painel.html'));

function send(res, status, type, body, extra = {}) {
  res.writeHead(status, { 'Content-Type': type, 'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff', ...extra });
  res.end(body);
}

http.createServer((req, res) => {
  const url = new URL(req.url, 'http://x');

  if (req.method === 'POST' && url.pathname === '/api/ping') {
    if (limited(req)) return send(res, 429, 'text/plain', 'devagar');
    let size = 0;
    const chunks = [];
    req.on('data', (chunk) => {
      size += chunk.length;
      if (size > 4096) req.destroy();
      else chunks.push(chunk);
    });
    req.on('end', () => {
      let body;
      try { body = JSON.parse(Buffer.concat(chunks).toString('utf8')); } catch { body = null; }
      send(res, body && recordPing(body) ? 204 : 400, 'text/plain', '');
    });
    return;
  }

  if (req.method === 'GET' && url.pathname === '/health') return send(res, 200, 'text/plain', 'ok');

  if (req.method === 'GET' && (url.pathname === '/' || url.pathname === '/api/stats')) {
    if (!authorized(req))
      return send(res, 401, 'text/plain', 'Login necessário', { 'WWW-Authenticate': 'Basic realm="Painel SWX2", charset="UTF-8"' });
    if (url.pathname === '/') return send(res, 200, 'text/html; charset=utf-8', dashboard);
    return send(res, 200, 'application/json; charset=utf-8', JSON.stringify(stats()));
  }

  send(res, 404, 'text/plain', 'não encontrado');
}).listen(PORT, () => console.log(`Painel SWX2 na porta ${PORT}`));
