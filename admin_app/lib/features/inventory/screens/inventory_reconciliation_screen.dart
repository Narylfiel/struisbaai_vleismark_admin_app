import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InventoryReconciliationScreen extends StatefulWidget {
  const InventoryReconciliationScreen({super.key});

  @override
  State<InventoryReconciliationScreen> createState() => _InventoryReconciliationScreenState();
}

class _InventoryReconciliationScreenState extends State<InventoryReconciliationScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _reconciliationData = [];
  List<Map<String, dynamic>> _anomalyData = [];
  Map<String, dynamic>? _summaryData;

  @override
  void initState() {
    super.initState();
    _loadReconciliationData();
  }

  Future<void> _loadReconciliationData() async {
    setState(() => _isLoading = true);
    
    try {
      final client = Supabase.instance.client;
      
      // Load today's summary data
      final summaryResponse = await client
          .from('inventory_reconciliation_summary')
          .select('*')
          .eq('checked_at', DateTime.now().toIso8601String().split('T')[0])
          .maybeSingle();
      
      // Load today's mismatches only (optimized logging)
      final reconciliationResponse = await client
          .from('inventory_reconciliation_log')
          .select('*')
          .eq('status', 'MISMATCH')
          .gte('checked_at', DateTime.now().toIso8601String().split('T')[0])
          .order('variance', ascending: false);
      
      // Load anomalies
      final anomalyResponse = await client
          .from('system_anomalies')
          .select('*')
          .eq('type', 'stock_mismatch')
          .eq('status', 'open')
          .order('detected_at', ascending: false);
      
      setState(() {
        _reconciliationData = List<Map<String, dynamic>>.from(reconciliationResponse);
        _anomalyData = List<Map<String, dynamic>>.from(anomalyResponse);
        
        if (summaryResponse != null) {
          _summaryData = {
            'total_items': summaryResponse['total_items'],
            'ok_items': summaryResponse['ok_items'],
            'mismatched_items': summaryResponse['mismatched_items'],
            'total_variance': summaryResponse['total_variance'],
            'anomalies_detected': summaryResponse['anomalies_detected'],
            'anomalies_resolved': summaryResponse['anomalies_resolved'] ?? 0,
            'execution_time_ms': summaryResponse['execution_time_ms'],
            'last_run': summaryResponse['created_at'],
          };
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading reconciliation data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runReconciliation() async {
    try {
      final client = Supabase.instance.client;
      
      // Call the reconciliation function
      final response = await client.rpc('reconcile_inventory');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reconciliation completed: ${response[0]['mismatched_items']} mismatches found'),
            backgroundColor: response[0]['mismatched_items'] > 0 ? Colors.orange : Colors.green,
          ),
        );
      }
      
      // Reload data
      await _loadReconciliationData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error running reconciliation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Reconciliation'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReconciliationData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: _runReconciliation,
            tooltip: 'Run Reconciliation',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 16),
                  _buildAnomaliesCard(),
                  const SizedBox(height: 16),
                  _buildMismatchesCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    if (_summaryData == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No reconciliation data available for today.'),
        ),
      );
    }

    final isHealthy = _summaryData!['mismatched_items'] == 0;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isHealthy ? Icons.check_circle : Icons.warning,
                  color: isHealthy ? Colors.green : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'System Status: ${isHealthy ? 'HEALTHY' : 'MISMATCHES DETECTED'}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isHealthy ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatItem('Total Items', _summaryData!['total_items'].toString()),
                _buildStatItem('OK', _summaryData!['ok_items'].toString(), Colors.green),
                _buildStatItem('Mismatches', _summaryData!['mismatched_items'].toString(), Colors.red),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatItem('Total Variance', _summaryData!['total_variance'].toString()),
                _buildStatItem('New Anomalies', _summaryData!['anomalies_detected'].toString(), 
                    _summaryData!['anomalies_detected'] > 0 ? Colors.red : Colors.green),
                _buildStatItem('Resolved', _summaryData!['anomalies_resolved'].toString(), 
                    _summaryData!['anomalies_resolved'] > 0 ? Colors.blue : Colors.grey),
              ],
            ),
            if (_summaryData!['execution_time_ms'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Execution time: ${_summaryData!['execution_time_ms']}ms',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            if (_summaryData!['last_run'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Last run: ${DateTime.parse(_summaryData!['last_run']).toLocal()}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, [Color? color]) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAnomaliesCard() {
    if (_anomalyData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Active Anomalies (${_anomalyData.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ..._anomalyData.map((anomaly) => ListTile(
            title: Text(anomaly['description']),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Detected: ${DateTime.parse(anomaly['detected_at']).toLocal()}'),
                if (anomaly['source_reference_type'] != null && anomaly['source_reference_type'] != 'unknown')
                  Text(
                    'Source: ${_formatSourceType(anomaly['source_reference_type'])} (${anomaly['source_reference_id']})',
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                  ),
              ],
            ),
            trailing: Chip(
              label: Text(anomaly['severity'].toUpperCase()),
              backgroundColor: _getSeverityColor(anomaly['severity']),
              labelStyle: const TextStyle(color: Colors.white),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildMismatchesCard() {
    if (_reconciliationData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Stock Mismatches (${_reconciliationData.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ..._reconciliationData.map((item) => ListTile(
            title: Text(item['item_name']),
            subtitle: Text('Expected: ${item['expected_stock']}, Actual: ${item['actual_stock']}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Variance: ${item['variance']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: item['variance'] != 0 ? Colors.red : Colors.green,
                  ),
                ),
                Text(
                  item['status'],
                  style: TextStyle(
                    fontSize: 12,
                    color: item['status'] == 'OK' ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange[700]!;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow[700]!;
      default:
        return Colors.grey;
    }
  }

  String _formatSourceType(String sourceType) {
    switch (sourceType.toLowerCase()) {
      case 'transaction':
        return 'POS Sale';
      case 'supplier_invoice':
        return 'Supplier Invoice';
      case 'adjustment':
        return 'Stock Adjustment';
      case 'waste':
        return 'Waste';
      case 'transfer':
        return 'Stock Transfer';
      case 'production':
        return 'Production';
      case 'donation':
        return 'Donation';
      case 'sponsorship':
        return 'Sponsorship';
      case 'staff_meal':
        return 'Staff Meal';
      case 'in':
        return 'Stock In';
      case 'out':
        return 'Stock Out';
      case 'freezer':
        return 'Freezer Transfer';
      default:
        return sourceType;
    }
  }
}
