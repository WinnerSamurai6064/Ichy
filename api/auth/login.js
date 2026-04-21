// vercel_api/api/auth/login.js
const crypto = require(‘crypto’);
const { getDb, signToken, cors, ok, err } = require(’../_lib/db’);

module.exports = async function handler(req, res) {
cors(res);
if (req.method === ‘OPTIONS’) return res.status(200).end();
if (req.method !== ‘POST’) return err(res, ‘Method not allowed’, 405);

const { phone, password } = req.body || {};
if (!phone || !password) return err(res, ‘phone and password are required’);

const sql = getDb();
try {
const [user] = await sql`SELECT id, name, phone, password_hash, avatar_url, about, respond_speed, is_online, last_seen FROM users WHERE phone = ${phone}`;
if (!user) return err(res, ‘Invalid phone number or password’, 401);

```
// Verify password
const [salt, hash] = user.password_hash.split(':');
const attempt = crypto.createHmac('sha256', salt).update(password).digest('hex');
if (attempt !== hash) return err(res, 'Invalid phone number or password', 401);

// Update online status
await sql`UPDATE users SET is_online = TRUE, last_seen = NOW() WHERE id = ${user.id}`;

const token = signToken({ userId: user.id, phone: user.phone });
ok(res, { token, user: formatUser(user) });
```

} catch (e) {
console.error(‘Login error:’, e);
err(res, ‘Login failed’, 500);
}
};

function formatUser(u) {
return {
id: u.id, name: u.name, phone: u.phone,
avatar_url: u.avatar_url, about: u.about,
respond_speed: u.respond_speed,
is_online: true, last_seen: new Date().toISOString(),
};
}
