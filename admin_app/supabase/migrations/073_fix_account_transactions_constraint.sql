-- bridge_account_sale_to_ledger() inserts account_transactions.payment_method = 'account'
-- (matching transactions.payment_method for on-account POS sales). The legacy CHECK
-- allowed only Cash/Card/EFT/Other, causing sync failures on account sales.

ALTER TABLE public.account_transactions
  DROP CONSTRAINT IF EXISTS account_transactions_payment_method_check;

ALTER TABLE public.account_transactions
  ADD CONSTRAINT account_transactions_payment_method_check
  CHECK (
    payment_method IS NULL
    OR payment_method = ANY (
      ARRAY[
        'EFT'::text,
        'Cash'::text,
        'Card'::text,
        'Other'::text,
        'account'::text
      ]
    )
  );
