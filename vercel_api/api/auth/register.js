// vercel_api/api/auth/register.js
const crypto = require('crypto');
const { getDb, signToken, cors, ok, err } = require('../_lib/db');

module.exports = async function handler(req, res) {
  cors(res);
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return err(res, 'Method not allowed', 405);

  const { name, phone, password } = req.body || {};
  if (!name || !phone || !password) return err(res, 'name, phone and password are required');
  if (password.length < 6) return err(res, 'Password must be at least 6 characters');

  const sql = getDb();
  try {
    // Check existing
    const existing = await sql`SELECT id FROM users WHERE phone = ${phone}`;
    if (existing.length > 0) return err(res, 'Phone number already registered', 409);

    // Hash password
    const salt = crypto.randomBytes(16).toString('hex');
    const hash = crypto.createHmac('sha256', salt).update(password).digest('hex');
    const passwordHash = `${salt}:${hash}`;

    const [user] = await sql`
      INSERT INTO users (name, phone, password_hash)
      VALUES (${name}, ${phone}, ${passwordHash})
      RETURNING id, name, phone, avatar_url, about, respond_speed, is_online, last_seen, created_at
    `;

    const token = signToken({ userId: user.id, phone: user.phone });
    ok(res, { token, user: formatUser(user) }, 201);
  } catch (e) {
    console.error('Register error:', e);
    err(res, 'Registration failed', 500);
  }
};

function formatUser(u) {
  return {
    id: u.id, name: u.name, phone: u.phone,
    avatar_url: u.avatar_url, about: u.about,
    respond_speed: u.respond_speed,
    is_online: u.is_online, last_seen: u.last_seen,
  };
}
