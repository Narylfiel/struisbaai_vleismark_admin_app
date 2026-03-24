import 'package:admin_app/core/services/base_service.dart';
import 'package:admin_app/core/services/audit_service.dart';

/// Service for managing online product suggestions
/// Follows existing admin app patterns with BaseService and audit logging
class ProductSuggestionService extends BaseService {
  static final ProductSuggestionService _instance = ProductSuggestionService._internal();
  factory ProductSuggestionService() => _instance;
  ProductSuggestionService._internal();

  /// Create a new product suggestion
  Future<Map<String, dynamic>> createSuggestion({
    required String sourceProductId,
    required String suggestedProductId,
    required String suggestionType,
    required int displayOrder,
    required String performedBy,
  }) async {
    return executeQuery(
      () async {
        // Validate no self-reference
        if (sourceProductId == suggestedProductId) {
          throw ArgumentError('Cannot link product to itself');
        }

        // Check maximum suggestions limit (10 per product)
        final existingCount = await client
            .from('online_product_suggestions')
            .select('id')
            .eq('source_product_id', sourceProductId)
            .eq('is_active', true);
            
        if ((existingCount as List).length >= 10) {
          throw ArgumentError('Maximum 10 suggestions allowed per product');
        }

        // Check for existing duplicate
        final existing = await client
            .from('online_product_suggestions')
            .select('id')
            .eq('source_product_id', sourceProductId)
            .eq('suggested_product_id', suggestedProductId)
            .eq('suggestion_type', suggestionType)
            .maybeSingle();

        if (existing != null) {
          throw ArgumentError('This suggestion already exists');
        }

        final response = await client
            .from('online_product_suggestions')
            .insert({
              'source_product_id': sourceProductId,
              'suggested_product_id': suggestedProductId,
              'suggestion_type': suggestionType,
              'display_order': displayOrder,
              'is_active': true,
            })
            .select()
            .single();

        // Get product names for audit
        final sourceProduct = await client
            .from('inventory_items')
            .select('name')
            .eq('id', sourceProductId)
            .single();
        final suggestedProduct = await client
            .from('inventory_items')
            .select('name')
            .eq('id', suggestedProductId)
            .single();

        await AuditService.log(
          action: 'CREATE',
          module: 'Online Shop',
          description: 'Created product suggestion: "${sourceProduct['name']}" → "${suggestedProduct['name']}" ($suggestionType)',
          entityType: 'ProductSuggestion',
          entityId: response['id'],
          newValues: response,
        );

        return response;
      },
      operationName: 'CreateProductSuggestion',
    );
  }

  /// Update suggestion display order
  Future<void> updateSuggestionOrder({
    required String suggestionId,
    required int displayOrder,
    required String performedBy,
  }) async {
    await executeQuery(
      () async {
        final current = await client
            .from('online_product_suggestions')
            .select('display_order')
            .eq('id', suggestionId)
            .single();

        await client
            .from('online_product_suggestions')
            .update({'display_order': displayOrder})
            .eq('id', suggestionId);

        await AuditService.log(
          action: 'UPDATE',
          module: 'Online Shop',
          description: 'Updated suggestion display order: ${current['display_order']} → $displayOrder',
          entityType: 'ProductSuggestion',
          entityId: suggestionId,
          oldValues: {'display_order': current['display_order']},
          newValues: {'display_order': displayOrder},
        );
      },
      operationName: 'UpdateSuggestionOrder',
    );
  }

  /// Remove a suggestion
  Future<void> removeSuggestion({
    required String suggestionId,
    required String performedBy,
  }) async {
    await executeQuery(
      () async {
        final current = await client
            .from('online_product_suggestions')
            .select('source_product_id, suggested_product_id, suggestion_type')
            .eq('id', suggestionId)
            .single();

        final sourceProduct = await client
            .from('inventory_items')
            .select('name')
            .eq('id', current['source_product_id'])
            .single();
        final suggestedProduct = await client
            .from('inventory_items')
            .select('name')
            .eq('id', current['suggested_product_id'])
            .single();

        await client
            .from('online_product_suggestions')
            .delete()
            .eq('id', suggestionId);

        await AuditService.log(
          action: 'DELETE',
          module: 'Online Shop',
          description: 'Deleted product suggestion: "${sourceProduct['name']}" → "${suggestedProduct['name']}" (${current['suggestion_type']})',
          entityType: 'ProductSuggestion',
          entityId: suggestionId,
          oldValues: current,
        );
      },
      operationName: 'RemoveProductSuggestion',
    );
  }

  /// Get suggestions for a product
  Future<List<Map<String, dynamic>>> getSuggestionsForProduct(String productId) async {
    return executeQuery(
      () async {
        final response = await client
            .from('online_product_suggestions')
            .select('''
              id,
              suggestion_type,
              display_order,
              is_active,
              suggested_product_id,
              inventory_items!suggested_product_id(id, name, online_display_name, sell_price, plu_code, stock_on_hand_fresh, stock_on_hand_frozen, online_min_stock_threshold)
            ''')
            .eq('source_product_id', productId)
            .order('display_order');

        return List<Map<String, dynamic>>.from(response ?? []);
      },
      operationName: 'GetSuggestionsForProduct',
    );
  }

  /// Get products available for suggestion (excluding self)
  Future<List<Map<String, dynamic>>> getAvailableProducts(String excludeProductId) async {
    return executeQuery(
      () async {
        final response = await client
            .from('inventory_items')
            .select('id, name, online_display_name, sell_price, available_online')
            .eq('available_online', true)
            .neq('id', excludeProductId)
            .order('name');

        return List<Map<String, dynamic>>.from(response);
      },
      operationName: 'GetAvailableProducts',
    );
  }

  /// Search products with query (enhanced with SKU support and better filtering)
  Future<List<Map<String, dynamic>>> searchProducts({
    required String query,
    required String excludeProductId,
  }) async {
    return executeQuery(
      () async {
        final trimmedQuery = query.trim();
        if (trimmedQuery.isEmpty) {
          return [];
        }

        // Enhanced search: name, online_display_name, plu_code (SKU)
        final response = await client
            .from('inventory_items')
            .select('id, name, online_display_name, sell_price, available_online, plu_code, stock_on_hand_fresh, stock_on_hand_frozen, online_min_stock_threshold')
            .eq('available_online', true)
            .neq('id', excludeProductId)
            .or('name.ilike.%$trimmedQuery%,online_display_name.ilike.%$trimmedQuery%,plu_code.ilike.%$trimmedQuery%')
            .order('name')
            .limit(20); // Reduced limit for better performance

        return List<Map<String, dynamic>>.from(response);
      },
      operationName: 'SearchProducts',
    );
  }

  /// Create multiple suggestions in bulk (efficient for large operations)
  Future<void> bulkCreateSuggestions({
    required String sourceProductId,
    required List<String> productIds,
    required String suggestionType,
    required String performedBy,
  }) async {
    // Guard: prevent empty bulk operations
    if (productIds.isEmpty) return;
    
    await executeQuery(
      () async {
        // Check maximum suggestions limit
        final existingCount = await client
            .from('online_product_suggestions')
            .select('id')
            .eq('source_product_id', sourceProductId)
            .eq('is_active', true);
            
        final currentCount = (existingCount as List).length;
        if (currentCount + productIds.length > 10) {
          throw ArgumentError('Cannot add ${productIds.length} suggestions. Would exceed maximum 10 suggestions per product (currently have $currentCount)');
        }

        // Validate no self-reference and duplicates
        for (final productId in productIds) {
          if (sourceProductId == productId) {
            throw ArgumentError('Cannot link product to itself');
          }

          final existing = await client
              .from('online_product_suggestions')
              .select('id')
              .eq('source_product_id', sourceProductId)
              .eq('suggested_product_id', productId)
              .eq('suggestion_type', suggestionType)
              .maybeSingle();

          if (existing != null) {
            throw ArgumentError('Suggestion already exists for product $productId');
          }
        }

        // Get next display order
        final maxOrder = await client
            .from('online_product_suggestions')
            .select('display_order')
            .eq('source_product_id', sourceProductId)
            .eq('suggestion_type', suggestionType)
            .order('display_order', ascending: false)
            .limit(1)
            .maybeSingle();
        
        int startOrder = (maxOrder?['display_order'] as int? ?? 0) + 1;

        // Bulk insert
        final suggestionsToInsert = productIds.asMap().entries.map((entry) {
          return {
            'source_product_id': sourceProductId,
            'suggested_product_id': entry.value,
            'suggestion_type': suggestionType,
            'display_order': startOrder + entry.key,
            'is_active': true,
          };
        }).toList();

        await client
            .from('online_product_suggestions')
            .insert(suggestionsToInsert);

        // Get source product name for audit
        final sourceProduct = await client
            .from('inventory_items')
            .select('name')
            .eq('id', sourceProductId)
            .single();

        await AuditService.log(
          action: 'CREATE',
          module: 'Online Shop',
          description: 'Bulk created ${productIds.length} $suggestionType suggestions for "${sourceProduct['name']}"',
          entityType: 'ProductSuggestion',
          newValues: {
            'source_product_id': sourceProductId,
            'suggestion_type': suggestionType,
            'count': productIds.length,
            'product_ids': productIds,
          },
        );
      },
      operationName: 'BulkCreateSuggestions',
    );
  }

  /// Toggle suggestion active status (instead of delete)
  Future<void> toggleSuggestionStatus({
    required String suggestionId,
    required bool isActive,
    required String performedBy,
  }) async {
    await executeQuery(
      () async {
        final current = await client
            .from('online_product_suggestions')
            .select('is_active, source_product_id, suggested_product_id, suggestion_type')
            .eq('id', suggestionId)
            .single();

        await client
            .from('online_product_suggestions')
            .update({'is_active': isActive})
            .eq('id', suggestionId);

        final sourceProduct = await client
            .from('inventory_items')
            .select('name')
            .eq('id', current['source_product_id'])
            .single();
        final suggestedProduct = await client
            .from('inventory_items')
            .select('name')
            .eq('id', current['suggested_product_id'])
            .single();

        await AuditService.log(
          action: 'UPDATE',
          module: 'Online Shop',
          description: '${isActive ? 'Activated' : 'Deactivated'} suggestion: "${sourceProduct['name']}" → "${suggestedProduct['name']}" (${current['suggestion_type']})',
          entityType: 'ProductSuggestion',
          entityId: suggestionId,
          oldValues: {'is_active': current['is_active']},
          newValues: {'is_active': isActive},
        );
      },
      operationName: 'ToggleSuggestionStatus',
    );
  }

  /// Batch update display orders for reordering
  Future<void> batchUpdateOrders({
    required List<Map<String, dynamic>> updates,
    required String performedBy,
  }) async {
    // Guard: prevent empty batch operations
    if (updates.isEmpty) return;
    
    await executeQuery(
      () async {
        for (final update in updates) {
          await client
              .from('online_product_suggestions')
              .update({'display_order': update['display_order']})
              .eq('id', update['id']);
        }

        await AuditService.log(
          action: 'UPDATE',
          module: 'Online Shop',
          description: 'Reordered ${updates.length} product suggestions',
          entityType: 'ProductSuggestion',
          newValues: {'updates_count': updates.length},
        );
      },
      operationName: 'BatchUpdateSuggestionOrders',
    );
  }
}
