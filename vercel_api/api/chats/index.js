// vercel_api/api/chats/index.js
const { getDb, authMiddleware, cors, ok, err } = require('../_lib/db');

module.exports = async function handler(req, res) {
  cors(res);
  if (req.method === 'OPTIONS') return res.status(200).end();

  const auth = authMiddleware(req);
  if (!auth) return err(res, 'Unauthorized', 401);

  const sql = getDb();

  // ── GET /api/chats ─────────────────────────────────────────────
  if (req.method === 'GET') {
    try {
      const rows = await sql`
        SELECT
          c.id, c.is_group, c.group_name, c.group_avatar_url, c.created_at,
          cp.is_muted, cp.is_pinned, cp.unread_count,
          -- last message
          lm.id AS lm_id, lm.sender_id AS lm_sender, lm.text AS lm_text,
          lm.type AS lm_type, lm.status AS lm_status, lm.created_at AS lm_created,
          lm.is_deleted AS lm_deleted,
          -- other participant (for 1-on-1)
          ou.id AS ou_id, ou.name AS ou_name, ou.avatar_url AS ou_avatar,
          ou.is_online AS ou_online, ou.last_seen AS ou_last_seen,
          ou.respond_speed AS ou_respond_speed
        FROM chat_participants cp
        JOIN chats c ON c.id = cp.chat_id
        LEFT JOIN LATERAL (
          SELECT * FROM messages m WHERE m.chat_id = c.id
          ORDER BY m.created_at DESC LIMIT 1
        ) lm ON TRUE
        LEFT JOIN LATERAL (
          SELECT u.id, u.name, u.avatar_url, u.is_online, u.last_seen, u.respond_speed
          FROM chat_participants cp2
          JOIN users u ON u.id = cp2.user_id
          WHERE cp2.chat_id = c.id AND cp2.user_id != ${auth.userId}
          LIMIT 1
        ) ou ON NOT c.is_group
        WHERE cp.user_id = ${auth.userId}
        ORDER BY COALESCE(lm.created_at, c.created_at) DESC
      `;

      const chats = rows.map(r => ({
        id: r.id,
        is_group: r.is_group,
        group_name: r.group_name,
        group_avatar_url: r.group_avatar_url,
        participant_ids: [],
        is_muted: r.is_muted,
        is_pinned: r.is_pinned,
        unread_count: r.unread_count,
        updated_at: r.lm_created || r.created_at,
        last_message: r.lm_id ? {
          id: r.lm_id, chat_id: r.id, sender_id: r.lm_sender,
          text: r.lm_text, type: r.lm_type, status: r.lm_status,
          created_at: r.lm_created, is_deleted: r.lm_deleted,
        } : null,
        other_user: r.ou_id ? {
          id: r.ou_id, name: r.ou_name, avatar_url: r.ou_avatar,
          is_online: r.ou_online, last_seen: r.ou_last_seen,
          respond_speed: r.ou_respond_speed,
        } : null,
      }));

      return ok(res, { chats });
    } catch (e) {
      console.error('Get chats error:', e);
      return err(res, 'Failed to get chats', 500);
    }
  }

  // ── POST /api/chats ────────────────────────────────────────────
  if (req.method === 'POST') {
    const { target_user_id, is_group, group_name } = req.body || {};

    try {
      if (!is_group) {
        // Check if 1-on-1 chat already exists
        const existing = await sql`
          SELECT c.id FROM chats c
          JOIN chat_participants cp1 ON cp1.chat_id = c.id AND cp1.user_id = ${auth.userId}
          JOIN chat_participants cp2 ON cp2.chat_id = c.id AND cp2.user_id = ${target_user_id}
          WHERE c.is_group = FALSE
          LIMIT 1
        `;
        if (existing.length > 0) {
          // Return existing chat
          const [chat] = existing;
          return ok(res, { chat: { id: chat.id, is_group: false, participant_ids: [auth.userId, target_user_id] } });
        }
      }

      const [chat] = await sql`
        INSERT INTO chats (is_group, group_name, created_by)
        VALUES (${is_group || false}, ${group_name || null}, ${auth.userId})
        RETURNING id, is_group, group_name, created_at
      `;

      // Add participants
      await sql`
        INSERT INTO chat_participants (chat_id, user_id)
        VALUES (${chat.id}, ${auth.userId})
      `;
      if (target_user_id) {
        await sql`
          INSERT INTO chat_participants (chat_id, user_id)
          VALUES (${chat.id}, ${target_user_id})
        `;
      }

      return ok(res, {
        chat: { ...chat, participant_ids: [auth.userId, target_user_id].filter(Boolean), unread_count: 0, updated_at: chat.created_at }
      }, 201);
    } catch (e) {
      console.error('Create chat error:', e);
      return err(res, 'Failed to create chat', 500);
    }
  }

  err(res, 'Method not allowed', 405);
};
