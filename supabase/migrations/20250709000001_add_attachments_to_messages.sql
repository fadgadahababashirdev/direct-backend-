ALTER TABLE messages ADD COLUMN IF NOT EXISTS attachments jsonb DEFAULT NULL;
ALTER TABLE messages ALTER COLUMN content_encrypted SET DEFAULT '';