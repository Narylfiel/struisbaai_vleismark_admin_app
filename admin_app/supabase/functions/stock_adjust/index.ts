import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { requireEdgeSecret, jsonResponse } from '../_shared/edge_auth.ts'
import { createServiceClient } from '../_shared/supabase_admin.ts'
import { writeAudit } from '../_shared/audit.ts'

const FN = 'stock_adjust'

type StockRow = Record<string, unknown>

serve(async (req) => {
  const unauthorized = requireEdgeSecret(req)
  if (unauthorized) return unauthorized
  if (req.method !== 'POST') return jsonResponse({ error: 'Method not allowed' }, 405)

  const admin = createServiceClient()
  let correlationId = ''
  let referenceId = ''

  try {
    const body = await req.json()
    correlationId = String(body?.correlation_id ?? '').trim()
    const movement = body?.movement as StockRow | undefined
    if (!correlationId) return jsonResponse({ error: 'correlation_id required' }, 400)
    if (!movement || typeof movement !== 'object') {
      return jsonResponse({ error: 'movement required' }, 400)
    }

    const itemId = String(movement['item_id'] ?? '').trim()
    const movementType = String(movement['movement_type'] ?? '').trim()
    const quantity = Number(movement['quantity'] ?? NaN)
    referenceId = String(movement['reference_id'] ?? '').trim()
    if (!itemId) return jsonResponse({ error: 'movement.item_id required' }, 400)
    if (!movementType) return jsonResponse({ error: 'movement.movement_type required' }, 400)
    if (!Number.isFinite(quantity)) return jsonResponse({ error: 'movement.quantity required' }, 400)

    const refType = String(movement['reference_type'] ?? '').trim()
    if (referenceId && refType) {
      const { data: dup } = await admin
        .from('stock_movements')
        .select('*')
        .eq('item_id', itemId)
        .eq('movement_type', movementType)
        .eq('reference_id', referenceId)
        .eq('reference_type', refType)
        .limit(1)
        .maybeSingle()
      if (dup) {
        await writeAudit(admin, {
          correlation_id: correlationId,
          reference_id: referenceId,
          action: 'UPDATE',
          module: 'Inventory',
          description: 'stock_adjust idempotent duplicate',
          success: true,
          function_name: FN,
          extra: { duplicate: true },
        })
        return jsonResponse({ ok: true, duplicate: true, movement: dup, correlation_id: correlationId })
      }
    }

    const { data, error } = await admin
      .from('stock_movements')
      .insert(movement)
      .onConflict('line_id')
      .ignore()
      .select()
      .single()
    if (error) throw error

    await writeAudit(admin, {
      correlation_id: correlationId,
      reference_id: referenceId || undefined,
      action: 'UPDATE',
      module: 'Inventory',
      description: `stock_adjust posted movement_type=${movementType}`,
      success: true,
      function_name: FN,
      extra: { item_id: itemId, quantity },
    })

    return jsonResponse({ ok: true, movement: data, correlation_id: correlationId })
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e)
    try {
      const admin2 = createServiceClient()
      await writeAudit(admin2, {
        correlation_id: correlationId || 'unknown',
        reference_id: referenceId || undefined,
        action: 'UPDATE',
        module: 'Inventory',
        description: 'stock_adjust failed',
        success: false,
        error_detail: msg,
        function_name: FN,
      })
    } catch (_) {
      /* ignore */
    }
    return jsonResponse({ error: msg, correlation_id: correlationId }, 500)
  }
})
