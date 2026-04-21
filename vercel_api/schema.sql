-- Run this once against your Neon DB to bootstrap the schema
-- psql $DATABASE_URL -f schema.sql

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS users (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name          TEXT NOT NULL,
  phone         TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  avatar_url    TEXT,
  about         TEXT DEFAULT 'Hey there! I am using IEchilli.',
  respond_speed TEXT,
  is_online     BOOLEAN DEFAULT FALSE,
  last_seen     TIMESTAMPTZ DEFAULT NOW(),
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS chats (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  is_group        BOOLEAN DEFAULT FALSE,
  group_name      TEXT,
  group_avatar_url TEXT,
  created_by      UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS chat_participants (
  chat_id   UUID REFERENCES chats(id) ON DELETE CASCADE,
  user_id   UUID REFERENCES users(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  is_muted  BOOLEAN DEFAULT FALSE,
  is_pinned BOOLEAN DEFAULT FALSE,
  unread_count INT DEFAULT 0,
  PRIMARY KEY (chat_id, user_id)
);

CREATE TABLE IF NOT EXISTS messages (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  chat_id     UUID REFERENCES chats(id) ON DELETE CASCADE NOT NULL,
  sender_id   UUID REFERENCES users(id) ON DELETE SET NULL NOT NULL,
  text        TEXT,
  type        TEXT DEFAULT 'text',   -- text|image|video|audio|document|sticker
  status      TEXT DEFAULT 'sent',   -- sending|sent|delivered|read
  media_url   TEXT,
  media_thumb TEXT,
  reply_to_id UUID REFERENCES messages(id) ON DELETE SET NULL,
  is_deleted  BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS message_reactions (
  message_id UUID REFERENCES messages(id) ON DELETE CASCADE,
  user_id    UUID REFERENCES users(id) ON DELETE CASCADE,
  emoji      TEXT NOT NULL,
  PRIMARY KEY (message_id, user_id)
);

CREATE TABLE IF NOT EXISTS status_updates (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  media_url   TEXT,
  text        TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  expires_at  TIMESTAMPTZ DEFAULT NOW() + INTERVAL '24 hours'
);

CREATE TABLE IF NOT EXISTS status_views (
  status_id  UUID REFERENCES status_updates(id) ON DELETE CASCADE,
  viewer_id  UUID REFERENCES users(id) ON DELETE CASCADE,
  viewed_at  TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (status_id, viewer_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_messages_chat_id ON messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_messages_created ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_participants_user ON chat_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_status_expires ON status_updates(expires_at);
