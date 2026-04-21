// vercel_api/api/users/search.js
const { getDb, authMiddleware, cors, ok, err } = require('../_lib/db');

module.exports = async function handler(req, res) {
  cors(res);
  if (req.method === 'OPTIONS') return res.status(200).end();

  const auth = authMiddleware(req);
  if (!auth) return err(res, 'Unauthorized', 401);

  if (req.method !== 'GET') return err(res, 'Method not allowed', 405);

  const q = req.query.q || '';
  if (q.length < 2) return ok(res, { users: [] });

  const sql = getDb();
  try {
    const users = await sql`
      SELECT id, name, phone, avatar_url, about, is_online, last_seen
      FROM users
      WHERE (name ILIKE ${'%' + q + '%'} OR phone ILIKE ${'%' + q + '%'})
        AND id != ${auth.userId}
      LIMIT 20
    `;
    return ok(res, { users });
  } catch (e) {
    return err(res, 'Search failed', 500);
  }
};
