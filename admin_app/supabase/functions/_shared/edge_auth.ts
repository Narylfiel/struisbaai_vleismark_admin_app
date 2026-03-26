/**
 * Validates that the caller provided the shared Edge Function secret.
 * Set EDGE_FUNCTION_SECRET in Supabase project secrets (same value passed from apps via dart-define).
 */
export function requireEdgeSecret(req: Request): Response | null {
  const expected = Deno.env.get('EDGE_FUNCTION_SECRET') ?? ''
  if (!expected) {
    return new Response(
      JSON.stringify({ error: 'EDGE_FUNCTION_SECRET not configured on server' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    )
  }
  const header =
    req.headers.get('x-edge-secret') ??
    (req.headers.get('Authorization')?.startsWith('Bearer ')
      ? req.headers.get('Authorization')!.slice(7)
      : null)
  if (!header || header !== expected) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    })
  }
  return null
}

export function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}
