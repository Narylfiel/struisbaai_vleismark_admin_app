import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'

export async function writeAudit(
  admin: SupabaseClient,
  params: {
    correlation_id: string
    reference_id?: string
    action: string
    module: string
    description: string
    success: boolean
    error_detail?: string
    function_name: string
    extra?: Record<string, unknown>
  },
): Promise<void> {
  const details = [
    params.description,
    `fn=${params.function_name}`,
    `correlation_id=${params.correlation_id}`,
    params.reference_id ? `reference_id=${params.reference_id}` : '',
    `success=${params.success}`,
    params.error_detail ? `error=${params.error_detail}` : '',
    params.extra ? `ctx=${JSON.stringify(params.extra)}` : '',
  ]
    .filter(Boolean)
    .join(' | ')
  try {
    await admin.from('audit_log').insert({
      action: params.action,
      module: params.module,
      details,
      entity_type: 'EdgeFunction',
      record_id: params.reference_id ?? params.correlation_id,
    })
  } catch (e) {
    console.error('[audit] insert failed', e)
  }
}
