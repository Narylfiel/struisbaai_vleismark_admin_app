import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { requireEdgeSecret, jsonResponse } from '../_shared/edge_auth.ts'
import { createServiceClient } from '../_shared/supabase_admin.ts'
import { writeAudit } from '../_shared/audit.ts'

const FN = 'admin_post_supplier_ledger'

/**
 * Client runs mapping UI, then sends final ledger_rows (same shape as ledger_entries insert)
 * + invoice_id + supplier_invoices patch fields.
 */
serve(async (req) => {
  const unauthorized = requireEdgeSecret(req)
  if (unauthorized) return unauthorized
  if (req.method !== 'POST') return jsonResponse({ error: 'Method not allowed' }, 405)

  const admin = createServiceClient()
  let correlationId = ''

  try {
    const body = await req.json()
    correlationId = String(body?.correlation_id ?? '').trim()
    const invoiceId = String(body?.invoice_id ?? '').trim()
    const ledgerRows = body?.ledger_rows as Record<string, unknown>[] | undefined
    if (!correlationId) return jsonResponse({ error: 'correlation_id required' }, 400)
    if (!invoiceId) return jsonResponse({ error: 'invoice_id required' }, 400)
    if (!Array.isArray(ledgerRows) || ledgerRows.length === 0) {
      return jsonResponse({ error: 'ledger_rows required (non-empty)' }, 400)
    }

    const { data: dup } = await admin
      .from('ledger_entries')
      .select('id')
      .eq('reference_type', 'supplier_invoice')
      .eq('reference_id', invoiceId)
      .limit(1)
      .maybeSingle()
    if (dup) {
      await writeAudit(admin, {
        correlation_id: correlationId,
        reference_id: invoiceId,
        action: 'APPROVE',
        module: 'Bookkeeping',
        description: 'admin_post_supplier_ledger idempotent duplicate',
        success: true,
        function_name: FN,
        extra: { duplicate: true },
      })
      return jsonResponse({ ok: true, duplicate: true, invoice_id: invoiceId, correlation_id: correlationId })
    }

    let debitSum = 0
    let creditSum = 0
    for (const row of ledgerRows) {
      debitSum += Number(row['debit'] ?? 0)
      creditSum += Number(row['credit'] ?? 0)
    }
    if (Math.abs(debitSum - creditSum) > 0.02) {
      return jsonResponse(
        { error: 'Ledger rows must balance (sum debit == sum credit)', debitSum, creditSum },
        400,
      )
    }

    for (const row of ledgerRows) {
      const { error } = await admin.from('ledger_entries').insert(row)
      if (error) throw error
    }

    const invPatch = body?.invoice_patch as Record<string, unknown> | undefined
    if (invPatch && typeof invPatch === 'object') {
      const { error: e2 } = await admin.from('supplier_invoices').update(invPatch).eq('id', invoiceId)
      if (e2) throw e2
    } else {
      const { error: e2 } = await admin
        .from('supplier_invoices')
        .update({
          status: 'approved',
          mappings_complete: true,
          updated_at: new Date().toISOString(),
        })
        .eq('id', invoiceId)
      if (e2) throw e2
    }

    await writeAudit(admin, {
      correlation_id: correlationId,
      reference_id: invoiceId,
      action: 'APPROVE',
      module: 'Bookkeeping',
      description: `Supplier invoice ledger posted (${ledgerRows.length} rows)`,
      success: true,
      function_name: FN,
    })

    return jsonResponse({ ok: true, invoice_id: invoiceId, correlation_id: correlationId })
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e)
    try {
      const admin2 = createServiceClient()
      await writeAudit(admin2, {
        correlation_id: correlationId || 'unknown',
        reference_id: undefined,
        action: 'APPROVE',
        module: 'Bookkeeping',
        description: 'admin_post_supplier_ledger failed',
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
