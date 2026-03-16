-- Add raised_by and raised_against columns to disputes table
-- These allow filtering disputes where the user is either the initiator or the respondent.

ALTER TABLE disputes ADD COLUMN IF NOT EXISTS raised_by UUID REFERENCES profiles(id);
ALTER TABLE disputes ADD COLUMN IF NOT EXISTS raised_against UUID REFERENCES profiles(id);

-- Backfill existing disputes: raised_by = initiator_id
UPDATE disputes SET raised_by = initiator_id WHERE raised_by IS NULL;

-- Make raised_by NOT NULL going forward (alias for initiator_id)
ALTER TABLE disputes ALTER COLUMN raised_by SET NOT NULL;

-- Create index for querying disputes by either party
CREATE INDEX IF NOT EXISTS idx_disputes_raised_by ON disputes (raised_by);
CREATE INDEX IF NOT EXISTS idx_disputes_raised_against ON disputes (raised_against);
