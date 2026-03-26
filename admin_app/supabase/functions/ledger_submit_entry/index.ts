import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { requireEdgeSecret, jsonResponse } from '../_shared/edge_auth.ts'
import { createServiceClient } from '../_shared/supabase_admin.ts'
import { writeAudit } from '../_shared/audit.ts'

const FN = 'ledger_submit_entry'

type LedgerRow = Record<string, unknown>

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
    const entry = body?.entry as LedgerRow | undefined
    const entries = body?.entries as LedgerRow[] | undefined
    if (!correlationId) return jsonResponse({ error: 'correlation_id required' }, 400)

    const rows = Array.isArray(entries) && entries.length > 0 ? entries : entry ? [entry] : []
    if (rows.length === 0) return jsonResponse({ error: 'entry or entries required' }, 400)

    let debitSum = 0
    let creditSum = 0
    for (const row of rows) {
      if (!row['account_code']) return jsonResponse({ error: 'account_code required' }, 400)
      debitSum += Number(row['debit'] ?? 0)
      creditSum += Number(row['credit'] ?? 0)
      if (Number(row['debit'] ?? 0) < 0 || Number(row['credit'] ?? 0) < 0) {
        return jsonResponse({ error: 'debit/credit must be non-negative' }, 400)
      }
    }
    if (rows.length > 1 && Math.abs(debitSum - creditSum) > 0.02) {
      return jsonResponse({ error: 'entries must balance', debitSum, creditSum }, 400)
    }

    const inserted: LedgerRow[] = []
    for (const row of rows) {
      referenceId = String(row['reference_id'] ?? referenceId ?? '').trim()
      const { data, error } = await admin.from('ledger_entries').insert(row).select().single()
      if (error) throw error
      inserted.push(data as LedgerRow)
    }

    await writeAudit(admin, {
      correlation_id: correlationId,
      reference_id: referenceId || undefined,
      action: 'CREATE',
      module: 'Bookkeeping',
      description: `ledger_submit_entry posted ${inserted.length} row(s)`,
      success: true,
      function_name: FN,
      extra: { rows: inserted.length },
    })

    return jsonResponse({
      ok: true,
      correlation_id: correlationId,
      row: inserted[0] ?? null,
      rows: inserted,
    })
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e)
    try {
      const admin2 = createServiceClient()
      await writeAudit(admin2, {
        correlation_id: correlationId || 'unknown',
        reference_id: referenceId || undefined,
        action: 'CREATE',
        module: 'Bookkeeping',
        description: 'ledger_submit_entry failed',
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
