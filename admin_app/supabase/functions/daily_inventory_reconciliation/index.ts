import "jsr:@supabase/functions-js/edge-runtime.d.ts";

Deno.serve(async (req) => {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

    // Call the reconciliation function
    const response = await fetch(`${supabaseUrl}/rest/v1/rpc/reconcile_inventory`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${supabaseServiceKey}`,
        'Content-Type': 'application/json',
        'apikey': supabaseServiceKey,
      },
    });

    if (!response.ok) {
      throw new Error(`Reconciliation failed: ${response.statusText}`);
    }

    const result = await response.json();
    
    console.log('Daily inventory reconciliation completed:', result);

    return new Response(JSON.stringify({
      success: true,
      message: 'Daily inventory reconciliation completed',
      result: result[0] // First row from the function result
    }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200,
    });

  } catch (error) {
    console.error('Daily reconciliation error:', error);
    
    return new Response(JSON.stringify({
      success: false,
      error: error.message
    }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500,
    });
  }
});
