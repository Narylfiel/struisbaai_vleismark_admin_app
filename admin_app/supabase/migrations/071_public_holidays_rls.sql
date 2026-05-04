-- Fix: public_holidays RLS missing anon SELECT policy
-- Admin app connects as anon role (no Supabase Auth)
-- Without this, phDates query returns empty and all 
-- public holiday pay calculates as R0
CREATE POLICY "Allow anon read public_holidays"
ON public_holidays
FOR SELECT
TO anon
USING (true);
