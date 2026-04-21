// vercel_api/api/statuses/index.js
const { getDb, authMiddleware, cors, ok, err } = require('../_lib/db');

module.exports = async function handler(req, res) {
  cors(res);
  if (req.method === 'OPTIONS') return res.status(200).end();

  const auth = authMiddleware(req);
  if (!auth) return err(res, 'Unauthorized', 401);

  const sql = getDb();

  if (req.method === 'GET') {
    try {
      // Get statuses from contacts (people you have chats with)
      const statuses = await sql`
        SELECT s.id, s.user_id, s.media_url, s.text, s.created_at, s.expires_at,
               u.name AS user_name, u.avatar_url AS user_avatar,
               ARRAY(
                 SELECT viewer_id FROM status_views sv WHERE sv.status_id = s.id
               ) AS viewed_by
        FROM status_updates s
        JOIN users u ON u.id = s.user_id
        WHERE s.expires_at > NOW()
          AND s.user_id IN (
            SELECT DISTINCT cp2.user_id
            FROM chat_participants cp1
            JOIN chat_participants cp2 ON cp2.chat_id = cp1.chat_id AND cp2.user_id != cp1.user_id
            WHERE cp1.user_id = ${auth.userId}
          )
        ORDER BY s.created_at DESC
      `;
      return ok(res, { statuses: statuses.map(s => ({
        id: s.id, user_id: s.user_id, user_name: s.user_name, user_avatar: s.user_avatar,
        media_url: s.media_url, text: s.text,
        created_at: s.created_at, expires_at: s.expires_at,
        viewed_by: s.viewed_by || [],
      })) });
    } catch (e) {
      return err(res, 'Failed to get statuses', 500);
    }
  }

  if (req.method === 'POST') {
    const { text, media_url } = req.body || {};
    if (!text && !media_url) return err(res, 'text or media_url required');
    try {
      const [status] = await sql`
        INSERT INTO status_updates (user_id, text, media_url)
        VALUES (${auth.userId}, ${text || null}, ${media_url || null})
        RETURNING *
      `;
      return ok(res, { status }, 201);
    } catch (e) {
      return err(res, 'Failed to post status', 500);
    }
  }

  err(res, 'Method not allowed', 405);
};
