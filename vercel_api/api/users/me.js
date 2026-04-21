// vercel_api/api/users/me.js
const { getDb, authMiddleware, cors, ok, err } = require('../_lib/db');

module.exports = async function handler(req, res) {
  cors(res);
  if (req.method === 'OPTIONS') return res.status(200).end();

  const auth = authMiddleware(req);
  if (!auth) return err(res, 'Unauthorized', 401);

  const sql = getDb();

  if (req.method === 'GET') {
    try {
      const [user] = await sql`
        SELECT id, name, phone, avatar_url, about, respond_speed, is_online, last_seen, created_at
        FROM users WHERE id = ${auth.userId}
      `;
      if (!user) return err(res, 'User not found', 404);
      return ok(res, { user });
    } catch (e) {
      return err(res, 'Failed to get user', 500);
    }
  }

  if (req.method === 'PUT') {
    const { name, about, avatar_url, respond_speed } = req.body || {};
    try {
      const [user] = await sql`
        UPDATE users SET
          name          = COALESCE(${name || null}, name),
          about         = COALESCE(${about || null}, about),
          avatar_url    = COALESCE(${avatar_url || null}, avatar_url),
          respond_speed = COALESCE(${respond_speed || null}, respond_speed)
        WHERE id = ${auth.userId}
        RETURNING id, name, phone, avatar_url, about, respond_speed, is_online, last_seen
      `;
      return ok(res, { user });
    } catch (e) {
      return err(res, 'Failed to update user', 500);
    }
  }

  err(res, 'Method not allowed', 405);
};
