CREATE OR REPLACE FUNCTION public.next_customer_invoice_number()
 RETURNS text
 LANGUAGE plpgsql
AS $function$
BEGIN
  RETURN 'SVM-' || LPAD(nextval('customer_invoice_seq')::text, 4, '0');
END;
$function$;
