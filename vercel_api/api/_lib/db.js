// vercel_api/api/_lib/db.js
const { neon } = require('@neondatabase/serverless');

let _sql;
function getDb() {
  if (!_sql) _sql = neon(process.env.DATABASE_URL);
  return _sql;
}

// ── JWT (no external lib needed - simple HMAC) ─────────────────────
const crypto = require('crypto');
const SECRET = process.env.JWT_SECRET || 'iechilli-secret-change-me';

function signToken(payload) {
  const header = b64u(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
  const body   = b64u(JSON.stringify({ ...payload, iat: Math.floor(Date.now()/1000), exp: Math.floor(Date.now()/1000)+86400*30 }));
  const sig    = b64u(crypto.createHmac('sha256', SECRET).update(`${header}.${body}`).digest());
  return `${header}.${body}.${sig}`;
}

function verifyToken(token) {
  try {
    const [header, body, sig] = token.split('.');
    const expected = b64u(crypto.createHmac('sha256', SECRET).update(`${header}.${body}`).digest());
    if (sig !== expected) return null;
    const payload = JSON.parse(Buffer.from(body, 'base64url').toString());
    if (payload.exp < Math.floor(Date.now()/1000)) return null;
    return payload;
  } catch { return null; }
}

function b64u(data) {
  return Buffer.from(data).toString('base64url');
}

function getTokenFromReq(req) {
  const auth = req.headers['authorization'] || '';
  if (auth.startsWith('Bearer ')) return auth.slice(7);
  return null;
}

function authMiddleware(req) {
  const token = getTokenFromReq(req);
  if (!token) return null;
  return verifyToken(token);
}

// ── CORS helper ────────────────────────────────────────────────────
function cors(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,PUT,DELETE,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type,Authorization');
}

function ok(res, data, status=200) {
  cors(res);
  res.status(status).json(data);
}

function err(res, message, status=400) {
  cors(res);
  res.status(status).json({ error: message });
}

module.exports = { getDb, signToken, verifyToken, authMiddleware, cors, ok, err };
