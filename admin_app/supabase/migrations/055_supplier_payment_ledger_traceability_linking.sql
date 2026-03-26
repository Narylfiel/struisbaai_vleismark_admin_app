create or replace function public.fn_update_invoice_on_payment()
returns trigger
language plpgsql
as $function$
declare
  v_total_paid numeric(12,2);
  v_invoice_total numeric(12,2);
  v_ap_ledger_id uuid;
  v_liquidity_ledger_id uuid;
  v_linked_count integer;
  v_updated_count integer;
begin
  select coalesce(sum(amount), 0)
  into v_total_paid
  from public.supplier_payments
  where invoice_id = new.invoice_id;

  select total
  into v_invoice_total
  from public.supplier_invoices
  where id = new.invoice_id;

  update public.supplier_invoices
  set
    amount_paid = v_total_paid,
    status = case
      when v_total_paid >= v_invoice_total then 'paid'
      else 'approved'
    end,
    updated_at = now()
  where id = new.invoice_id;

  select count(*)
  into v_linked_count
  from public.ledger_entries
  where source = 'supplier_payment'
    and reference_id = new.id;

  -- Traceability only: link already-posted supplier payment ledger entries to this payment.
  -- This does not create any new ledger entries.
  if new.ledger_entry_id is null and v_linked_count = 0 then
    select le.id
    into v_ap_ledger_id
    from public.ledger_entries le
    where le.source = 'supplier_payment'
      and le.reference_id is null
      and le.entry_date = new.payment_date::date
      and le.account_code = '2000'
      and coalesce(le.debit, 0) = new.amount
      and coalesce(le.credit, 0) = 0
    order by le.created_at asc
    limit 1;

    select le.id
    into v_liquidity_ledger_id
    from public.ledger_entries le
    where le.source = 'supplier_payment'
      and le.reference_id is null
      and le.entry_date = new.payment_date::date
      and le.account_code in ('1000', '1100')
      and coalesce(le.credit, 0) = new.amount
      and coalesce(le.debit, 0) = 0
    order by le.created_at asc
    limit 1;

    if v_ap_ledger_id is not null and v_liquidity_ledger_id is not null then
      update public.ledger_entries
      set
        reference_id = new.id,
        reference_type = 'supplier_payment'
      where id in (v_ap_ledger_id, v_liquidity_ledger_id)
        and reference_id is null;

      get diagnostics v_updated_count = row_count;

      if v_updated_count = 2 then
        update public.supplier_payments
        set ledger_entry_id = v_ap_ledger_id
        where id = new.id
          and ledger_entry_id is null;
      end if;
    end if;
  elsif new.ledger_entry_id is null and v_linked_count = 2 then
    update public.supplier_payments
    set ledger_entry_id = (
      select id
      from public.ledger_entries
      where source = 'supplier_payment'
        and reference_id = new.id
        and account_code = '2000'
      order by created_at asc
      limit 1
    )
    where id = new.id
      and ledger_entry_id is null;
  end if;

  return new;
end;
$function$;

do $$
declare
  p record;
  v_ap_ledger_id uuid;
  v_liquidity_ledger_id uuid;
  v_updated_count integer;
begin
  for p in
    select id, payment_date, amount
    from public.supplier_payments
    where ledger_entry_id is null
    order by payment_date asc, created_at asc
  loop
    select le.id
    into v_ap_ledger_id
    from public.ledger_entries le
    where le.source = 'supplier_payment'
      and le.reference_id is null
      and le.entry_date = p.payment_date::date
      and le.account_code = '2000'
      and coalesce(le.debit, 0) = p.amount
      and coalesce(le.credit, 0) = 0
    order by le.created_at asc
    limit 1;

    select le.id
    into v_liquidity_ledger_id
    from public.ledger_entries le
    where le.source = 'supplier_payment'
      and le.reference_id is null
      and le.entry_date = p.payment_date::date
      and le.account_code in ('1000', '1100')
      and coalesce(le.credit, 0) = p.amount
      and coalesce(le.debit, 0) = 0
    order by le.created_at asc
    limit 1;

    if v_ap_ledger_id is not null and v_liquidity_ledger_id is not null then
      update public.ledger_entries
      set
        reference_id = p.id,
        reference_type = 'supplier_payment'
      where id in (v_ap_ledger_id, v_liquidity_ledger_id)
        and reference_id is null;

      get diagnostics v_updated_count = row_count;

      if v_updated_count = 2 then
        update public.supplier_payments
        set ledger_entry_id = v_ap_ledger_id
        where id = p.id
          and ledger_entry_id is null;
      end if;
    end if;
  end loop;
end;
$$;
