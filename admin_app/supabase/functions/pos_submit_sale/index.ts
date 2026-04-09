import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { requireEdgeSecret, jsonResponse } from '../_shared/edge_auth.ts'
import { createServiceClient } from '../_shared/supabase_admin.ts'
import { writeAudit } from '../_shared/audit.ts'

const FN = 'pos_submit_sale'

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
    if (!Array.isArray(items) || items.length === 0) return jsonResponse({ error: 'items required' }, 400)

    const txId = String(header['id'] ?? '').trim()
    referenceId = txId
    if (!txId) return jsonResponse({ error: 'header.id (transaction id) required' }, 400)

    if (header['is_refund'] === true) {
      return jsonResponse({ error: 'use pos_submit_refund for refunds' }, 400)
    }

    const { data: existing } = await admin.from('transactions').select('id').eq('id', txId).maybeSingle()
    if (existing) {
      await writeAudit(admin, {
        correlation_id: correlationId,
        reference_id: txId,
        action: 'CREATE',
        module: 'POS',
        description: 'pos_submit_sale idempotent duplicate',
        success: true,
        function_name: FN,
        extra: { duplicate: true },
      })
      return jsonResponse({ ok: true, duplicate: true, transaction_id: txId, correlation_id: correlationId })
    }

    const lineRows = items.map((raw) => {
      const row = raw as Record<string, unknown>
      return {
        ...row,
        transaction_id: txId,
      }
    })

    const sumLines = lineRows.reduce((s, r) => s + Number((r as { line_total?: number }).line_total ?? 0), 0)
    const totalAmt = Number(header['total_amount'] ?? 0)
    if (Math.abs(sumLines - totalAmt) > 0.05) {
      return jsonResponse(
        { error: 'Line totals do not match transaction total_amount', sumLines, total_amount: totalAmt },
        400,
      )
    }

    const { error: e1 } = await admin.from('transactions').insert(header as Record<string, unknown>)
    if (e1) throw e1
    const { error: e2 } = await admin.from('transaction_items').insert(lineRows as Record<string, unknown>[])
    if (e2) throw e2

    const staffId = String(header['staff_id'] ?? '')
    const stockRows: Record<string, unknown>[] = []
    for (const raw of lineRows) {
      const r = raw as Record<string, unknown>
      const iid = r['inventory_item_id']
      if (iid == null || String(iid).trim() === '') continue
      const qty = Number(r['quantity'] ?? 0)
      stockRows.push({
        item_id: iid,
        movement_type: 'sale',
        quantity: -qty,
        unit_type: r['unit_type'] ?? 'units',
        reference_id: txId,
        reference_type: 'transaction',
        staff_id: staffId || null,
        reason: `POS sale: ${r['product_name'] ?? ''}`,
      })
    }
    if (stockRows.length > 0) {
      const { error: e3 } = await admin
        .from('stock_movements')
        .insert(stockRows)
        .onConflict('line_id')
        .ignore()
      if (e3) throw e3
    }

    const loyaltyId = header['loyalty_customer_id'] as string | null | undefined
    if (loyaltyId) {
      const points = Math.floor(totalAmt)
      const { error: e4 } = await admin.rpc('increment_loyalty', {
        customer_id: loyaltyId,
        points_to_add: points,
        spend_to_add: totalAmt,
        transaction_id: txId,
      })
      if (e4) console.error('[pos_submit_sale] increment_loyalty', e4)
    }

    await writeAudit(admin, {
      correlation_id: correlationId,
      reference_id: txId,
      action: 'CREATE',
      module: 'POS',
      description: `Sale posted transaction_id=${txId}`,
      success: true,
      function_name: FN,
    })

    return jsonResponse({
      ok: true,
      transaction_id: txId,
      correlation_id: correlationId,
    })
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e)
    try {
      const admin2 = createServiceClient()
      await writeAudit(admin2, {
        correlation_id: correlationId || 'unknown',
        reference_id: referenceId || undefined,
        action: 'CREATE',
        module: 'POS',
        description: 'pos_submit_sale failed',
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
