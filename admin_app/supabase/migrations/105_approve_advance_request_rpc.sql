-- Atomic approve: staff_requests -> approved + staff_credit insert (single transaction).

CREATE OR REPLACE FUNCTION public.approve_advance_request(
  p_request_id uuid,
  p_amount numeric,
  p_reviewer_id uuid
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_deduct text;
BEGIN
  IF p_amount IS NULL OR p_amount <= 0 THEN
    RAISE EXCEPTION 'Invalid approved amount';
  END IF;

  UPDATE public.staff_requests
  SET
    status = 'approved',
    amount_approved = p_amount,
    reviewed_by = p_reviewer_id,
    reviewed_at = NOW()
  WHERE id = p_request_id
    AND status = 'pending'
    AND request_type = 'salary_advance';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Request not found or already processed';
  END IF;

  v_deduct := to_char(
    ((date_trunc('month', CURRENT_DATE)::date + interval '1 month - interval '1 day')::date),
    'YYYY-MM-DD'
  );

  INSERT INTO public.staff_credit (
    staff_id,
    credit_amount,
    credit_type,
    status,
    granted_date,
    granted_by,
    deduct_from,
    reason,
    is_paid
  )
  SELECT
    sr.staff_id,
    p_amount,
    'salary_advance',
    'pending',
    CURRENT_DATE,
    p_reviewer_id,
    v_deduct,
    COALESCE(NULLIF(trim(sr.advance_reason), ''), 'Salary advance'),
    false
  FROM public.staff_requests sr
  WHERE sr.id = p_request_id;
END;
$$;

COMMENT ON FUNCTION public.approve_advance_request(uuid, numeric, uuid) IS
  'Approves a pending salary_advance staff_requests row and inserts matching staff_credit in one transaction.';

GRANT EXECUTE ON FUNCTION public.approve_advance_request(uuid, numeric, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.approve_advance_request(uuid, numeric, uuid) TO service_role;
