import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { requireEdgeSecret, jsonResponse } from '../_shared/edge_auth.ts'
import { createServiceClient } from '../_shared/supabase_admin.ts'
import { writeAudit } from '../_shared/audit.ts'

const FN = 'clock_submit_event'

type EventType =
  | 'clock_in_upsert'
  | 'start_break'
  | 'end_break'
  | 'clock_out'

serve(async (req) => {
  const unauthorized = requireEdgeSecret(req)
  if (unauthorized) return unauthorized
  if (req.method !== 'POST') return jsonResponse({ error: 'Method not allowed' }, 405)

  const admin = createServiceClient()
  let correlationId = ''

  try {
    const body = await req.json()
    correlationId = String(body?.correlation_id ?? '').trim()
    const event = String(body?.event ?? '').trim() as EventType
    const payload = body?.payload as Record<string, unknown> | undefined
    if (!correlationId) return jsonResponse({ error: 'correlation_id required' }, 400)
    if (!payload) return jsonResponse({ error: 'payload required' }, 400)

    switch (event) {
      case 'clock_in_upsert': {
        const staffId = String(payload['staff_id'] ?? '')
        const shiftDate = String(payload['shift_date'] ?? '')
        const { data: existingTc } = await admin
          .from('timecards')
          .select('*')
          .eq('staff_id', staffId)
          .eq('shift_date', shiftDate)
          .maybeSingle()
        if (existingTc) {
          await writeAudit(admin, {
            correlation_id: correlationId,
            reference_id: String((existingTc as { id?: string }).id ?? ''),
            action: 'CREATE',
            module: 'HR',
            description: 'clock_in_upsert idempotent duplicate',
            success: true,
            function_name: FN,
            extra: { duplicate: true },
          })
          return jsonResponse({
            ok: true,
            duplicate: true,
            timecard: existingTc,
            correlation_id: correlationId,
          })
        }
        const { data, error } = await admin
          .from('timecards')
          .insert({
            staff_id: staffId,
            shift_date: shiftDate,
            clock_in: payload['clock_in'],
            status: 'clocked_in',
          })
          .select()
          .single()
        if (error) throw error
        await writeAudit(admin, {
          correlation_id: correlationId,
          reference_id: String(data?.id ?? ''),
          action: 'CREATE',
          module: 'HR',
          description: 'clock_in_upsert',
          success: true,
          function_name: FN,
        })
        return jsonResponse({ ok: true, timecard: data, correlation_id: correlationId })
      }
      case 'start_break': {
        const insertData: Record<string, unknown> = {
          timecard_id: payload['timecard_id'],
          break_start: payload['break_start'],
          break_type: payload['break_type'],
        }
        if (payload['notes'] != null) insertData['notes'] = payload['notes']
        const { data: br, error } = await admin.from('timecard_breaks').insert(insertData).select().single()
        if (error) throw error
        await admin.from('timecards').update({ status: 'on_break' }).eq('id', String(payload['timecard_id']))
        await writeAudit(admin, {
          correlation_id: correlationId,
          reference_id: String(br?.id ?? ''),
          action: 'CREATE',
          module: 'HR',
          description: 'start_break',
          success: true,
          function_name: FN,
        })
        return jsonResponse({ ok: true, break: br, correlation_id: correlationId })
      }
      case 'end_break': {
        const breakId = String(payload['break_id'] ?? '')
        const timecardId = String(payload['timecard_id'] ?? '')
        const breakEnd = String(payload['break_end'] ?? '')
        const { data: breakData, error: e1 } = await admin
          .from('timecard_breaks')
          .select('break_start')
          .eq('id', breakId)
          .single()
        if (e1) throw e1
        const breakStart = new Date(String(breakData?.break_start))
        const breakEndDt = new Date(breakEnd)
        const durationMinutes = (breakEndDt.getTime() - breakStart.getTime()) / 60000
        const { error: e2 } = await admin
          .from('timecard_breaks')
          .update({
            break_end: breakEnd,
            break_duration_minutes: durationMinutes,
          })
          .eq('id', breakId)
        if (e2) throw e2
        await admin.from('timecards').update({ status: 'clocked_in' }).eq('id', timecardId)
        await writeAudit(admin, {
          correlation_id: correlationId,
          reference_id: breakId,
          action: 'UPDATE',
          module: 'HR',
          description: 'end_break',
          success: true,
          function_name: FN,
        })
        return jsonResponse({ ok: true, correlation_id: correlationId })
      }
      case 'clock_out': {
        const { error } = await admin
          .from('timecards')
          .update({
            clock_out: payload['clock_out'],
            status: 'clocked_out',
            break_minutes: payload['break_minutes'],
            total_hours: payload['total_hours'],
          })
          .eq('id', String(payload['timecard_id']))
        if (error) throw error
        await writeAudit(admin, {
          correlation_id: correlationId,
          reference_id: String(payload['timecard_id']),
          action: 'UPDATE',
          module: 'HR',
          description: 'clock_out',
          success: true,
          function_name: FN,
        })
        return jsonResponse({ ok: true, correlation_id: correlationId })
      }
      default:
        return jsonResponse({ error: `unknown event: ${event}` }, 400)
    }
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e)
    try {
      const admin2 = createServiceClient()
      await writeAudit(admin2, {
        correlation_id: correlationId || 'unknown',
        reference_id: undefined,
        action: 'UPDATE',
        module: 'HR',
        description: 'clock_submit_event failed',
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
