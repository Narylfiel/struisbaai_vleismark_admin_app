import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { requireEdgeSecret, jsonResponse } from '../_shared/edge_auth.ts'
import { createServiceClient } from '../_shared/supabase_admin.ts'
import { writeAudit } from '../_shared/audit.ts'

const FN = 'pos_submit_refund'

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
    const header = body?.header as Record<string, unknown> | undefined
    const items = body?.items as unknown[] | undefined
    if (!correlationId) return jsonResponse({ error: 'correlation_id required' }, 400)
    if (!header || typeof header !== 'object') return jsonResponse({ error: 'header required' }, 400)
    if (!Array.isArray(items)) return jsonResponse({ error: 'items required' }, 400)

    const txId = String(header['id'] ?? '').trim()
    referenceId = txId
    if (!txId) return jsonResponse({ error: 'header.id required' }, 400)
    if (header['is_refund'] !== true) return jsonResponse({ error: 'header.is_refund must be true' }, 400)
    const origId = String(header['refund_of_transaction_id'] ?? '').trim()
    if (!origId) return jsonResponse({ error: 'refund_of_transaction_id required' }, 400)

    const { data: dup } = await admin
      .from('transactions')
      .select('id')
      .eq('refund_of_transaction_id', origId)
      .eq('is_refund', true)
      .maybeSingle()
    if (dup) {
      await writeAudit(admin, {
        correlation_id: correlationId,
        reference_id: txId,
        action: 'CREATE',
        module: 'POS',
        description: 'pos_submit_refund idempotent duplicate',
        success: true,
        function_name: FN,
        extra: { duplicate: true },
      })
      return jsonResponse({ ok: true, duplicate: true, transaction_id: dup.id, correlation_id: correlationId })
    }

    for (const raw of items) {
      const r = raw as Record<string, unknown>
      if (r['inventory_item_id'] != null) {
        return jsonResponse({ error: 'refund line must have inventory_item_id null' }, 400)
      }
      if (Number(r['quantity'] ?? -1) !== 0) {
        return jsonResponse({ error: 'refund line quantity must be 0' }, 400)
      }
      const lt = Number(r['line_total'] ?? 0)
      if (lt >= 0) {
        return jsonResponse({ error: 'refund line_total must be negative' }, 400)
      }
    }

    const { error: e1 } = await admin.from('transactions').insert(header as Record<string, unknown>)
    if (e1) throw e1
    if (items.length > 0) {
      const lineRows = items.map((raw) => ({ ...(raw as object), transaction_id: txId }))
      const { error: e2 } = await admin.from('transaction_items').insert(lineRows as Record<string, unknown>[])
      if (e2) throw e2
    }

    await writeAudit(admin, {
      correlation_id: correlationId,
      reference_id: txId,
      action: 'CREATE',
      module: 'POS',
      description: `Refund posted for original=${origId}`,
      success: true,
      function_name: FN,
    })

    return jsonResponse({ ok: true, transaction_id: txId, correlation_id: correlationId })
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e)
    try {
      const admin2 = createServiceClient()
      await writeAudit(admin2, {
        correlation_id: correlationId || 'unknown',
        reference_id: referenceId || undefined,
        action: 'CREATE',
        module: 'POS',
        description: 'pos_submit_refund failed',
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
