/// Gated Edge Function write pipeline (RLS hardening plan).
/// Build with: `--dart-define=USE_EDGE_PIPELINE=true --dart-define=EDGE_FUNCTION_SECRET=...`
class EdgePipelineConfig {
  EdgePipelineConfig._();

  static const bool useEdgePipeline = bool.fromEnvironment(
    'USE_EDGE_PIPELINE',
    defaultValue: false,
  );

  static const String edgeFunctionSecret = String.fromEnvironment(
    'EDGE_FUNCTION_SECRET',
    defaultValue: '',
  );

  static bool get hasSecret => edgeFunctionSecret.isNotEmpty;

  static bool get canUseEdgePipeline => useEdgePipeline && hasSecret;
}
