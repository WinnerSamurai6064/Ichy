// vercel_api/api/messages/[chatId].js
const { getDb, authMiddleware, cors, ok, err } = require('../_lib/db');

module.exports = async function handler(req, res) {
  cors(res);
  if (req.method === 'OPTIONS') return res.status(200).end();

  const auth = authMiddleware(req);
  if (!auth) return err(res, 'Unauthorized', 401);

  const { chatId } = req.query;
  const sql = getDb();

  // Verify user is a participant
  const [participant] = await sql`
    SELECT 1 FROM chat_participants WHERE chat_id = ${chatId} AND user_id = ${auth.userId}
  `;
  if (!participant) return err(res, 'Not a participant of this chat', 403);

  // ── GET /api/messages/:chatId ──────────────────────────────────
  if (req.method === 'GET') {
    const page  = parseInt(req.query.page || '1');
    const limit = parseInt(req.query.limit || '50');
    const offset = (page - 1) * limit;

    try {
      const messages = await sql`
        SELECT m.id, m.chat_id, m.sender_id, m.text, m.type, m.status,
               m.media_url, m.media_thumb, m.reply_to_id, m.is_deleted, m.created_at,
               u.name AS sender_name, u.avatar_url AS sender_avatar
        FROM messages m
        JOIN users u ON u.id = m.sender_id
        WHERE m.chat_id = ${chatId}
        ORDER BY m.created_at DESC
        LIMIT ${limit} OFFSET ${offset}
      `;

      return ok(res, {
        messages: messages.map(m => ({
          id: m.id, chat_id: m.chat_id, sender_id: m.sender_id,
          text: m.text, type: m.type, status: m.status,
          media_url: m.media_url, media_thumb: m.media_thumb,
          reply_to_id: m.reply_to_id, is_deleted: m.is_deleted,
          created_at: m.created_at, reactions: [],
          sender_name: m.sender_name, sender_avatar: m.sender_avatar,
        })),
        page, limit,
      });
    } catch (e) {
      console.error('Get messages error:', e);
      return err(res, 'Failed to get messages', 500);
    }
  }

  // ── POST /api/messages/:chatId ─────────────────────────────────
  if (req.method === 'POST') {
    const { text, type = 'text', media_url } = req.body || {};
    if (!text && !media_url) return err(res, 'text or media_url required');

    try {
      const [message] = await sql`
        INSERT INTO messages (chat_id, sender_id, text, type, media_url, status)
        VALUES (${chatId}, ${auth.userId}, ${text || null}, ${type}, ${media_url || null}, 'sent')
        RETURNING id, chat_id, sender_id, text, type, status, media_url, is_deleted, created_at
      `;

      // Reset unread for sender, increment for others
      await sql`
        UPDATE chat_participants
        SET unread_count = CASE
          WHEN user_id = ${auth.userId} THEN 0
          ELSE unread_count + 1
        END
        WHERE chat_id = ${chatId}
      `;

      return ok(res, { message: { ...message, reactions: [] } }, 201);
    } catch (e) {
      console.error('Send message error:', e);
      return err(res, 'Failed to send message', 500);
    }
  }

  // ── PUT /api/messages/:chatId/read ─────────────────────────────
  if (req.method === 'PUT') {
    try {
      await sql`
        UPDATE messages SET status = 'read'
        WHERE chat_id = ${chatId} AND sender_id != ${auth.userId} AND status != 'read'
      `;
      await sql`
        UPDATE chat_participants SET unread_count = 0
        WHERE chat_id = ${chatId} AND user_id = ${auth.userId}
      `;
      return ok(res, { success: true });
    } catch (e) {
      return err(res, 'Failed to mark as read', 500);
    }
  }

  err(res, 'Method not allowed', 405);
};
