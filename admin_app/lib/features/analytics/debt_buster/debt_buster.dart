/// Debt Buster feature exports.
/// 
/// A target-driven decision engine for debt clearance that:
/// - Calculates total debt from supplier invoices and staff credits
/// - Supports user-defined repayment deadlines
/// - Determines required monthly repayment
/// - Calculates current available monthly cash (real data only)
/// - Identifies the GAP between required vs available
/// - Generates actionable, data-driven strategies to close the gap
/// - Matches opportunities to the gap to determine feasibility
/// 
/// READ-ONLY: This feature does not modify any database records.

// Models
export 'models/debt_summary.dart';
export 'models/gap_analysis.dart';
export 'models/strategy_plan.dart';
export 'models/opportunity.dart';

// Services
export 'services/debt_buster_service.dart';

// Widgets
export 'widgets/debt_summary_card.dart';
export 'widgets/gap_indicator.dart';
export 'widgets/strategy_cards.dart';
export 'widgets/opportunity_list.dart';

// Screens
export 'screens/debt_buster_tab.dart';
