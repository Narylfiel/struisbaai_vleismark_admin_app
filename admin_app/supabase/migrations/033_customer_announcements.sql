-- M1: customer_announcements for Announcement screen (WhatsApp/SMS, recipient tracking).
-- Create only if not exists; add missing columns if table exists from other migrations.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'customer_announcements') THEN
    CREATE TABLE customer_announcements (
      id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
      title TEXT NOT NULL,
      body TEXT NOT NULL,
      channel TEXT NOT NULL CHECK (channel IN ('WhatsApp', 'SMS', 'Both')),
      recipient_count INTEGER NOT NULL DEFAULT 0,
      status TEXT NOT NULL DEFAULT 'sent' CHECK (status IN ('draft', 'sent', 'failed')),
      sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      image_url TEXT,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'customer_announcements') THEN
    ALTER TABLE customer_announcements ADD COLUMN IF NOT EXISTS title TEXT;
    ALTER TABLE customer_announcements ADD COLUMN IF NOT EXISTS body TEXT;
    ALTER TABLE customer_announcements ADD COLUMN IF NOT EXISTS channel TEXT;
    ALTER TABLE customer_announcements ADD COLUMN IF NOT EXISTS recipient_count INTEGER DEFAULT 0;
    ALTER TABLE customer_announcements ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'sent';
    ALTER TABLE customer_announcements ADD COLUMN IF NOT EXISTS sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    ALTER TABLE customer_announcements ADD COLUMN IF NOT EXISTS image_url TEXT;
    ALTER TABLE customer_announcements ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_customer_announcements_sent_at ON customer_announcements(sent_at DESC);
CREATE INDEX IF NOT EXISTS idx_customer_announcements_channel ON customer_announcements(channel);
CREATE INDEX IF NOT EXISTS idx_customer_announcements_status ON customer_announcements(status);

-- Ensure loyalty_customers has tags for By Tag filter (optional jsonb).
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'loyalty_customers' AND column_name = 'tags') THEN
    ALTER TABLE loyalty_customers ADD COLUMN tags JSONB DEFAULT '[]';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'loyalty_customers' AND column_name = 'full_name') THEN
    ALTER TABLE loyalty_customers ADD COLUMN full_name TEXT;
    UPDATE loyalty_customers SET full_name = customer_name WHERE full_name IS NULL;
  END IF;
END $$;
