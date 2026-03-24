# Product Suggestion Manager

A complete admin management system for online product suggestions, allowing staff to create, edit, reorder, and delete product suggestions safely using existing architecture patterns.

## Features

### 🎯 Core Functionality
- **Full CRUD Operations**: Create, read, update, and delete product suggestions
- **Three Suggestion Types**: 
  - Frequently Bought Together
  - Upsell Items  
  - Related Products
- **Drag-and-Drop Reordering**: Intuitive visual reordering with real-time updates
- **Product Search**: Fast, searchable product selection with exclusion of current product
- **Validation**: Prevents duplicates, self-references, and maintains data integrity

### 🛡️ Safety & Audit
- **BaseService Integration**: Follows existing admin app patterns with retry logic
- **Comprehensive Audit Logging**: All operations logged via AuditService
- **Error Handling**: Graceful error handling with user-friendly messages
- **Optimistic UI Updates**: Fast UI feedback with rollback on errors

### 🎨 User Experience
- **Clean Interface**: Follows existing admin app design patterns
- **Loading States**: Proper loading indicators and error states
- **Empty States**: Helpful empty states with clear call-to-actions
- **Responsive Design**: Works on various screen sizes
- **Confirmation Dialogs**: Safe deletion with confirmation prompts

## Architecture

### Service Layer
```
ProductSuggestionService extends BaseService
├── createSuggestion()
├── removeSuggestion()
├── updateSuggestionOrder()
├── getSuggestionsForProduct()
├── getAvailableProducts()
├── searchProducts()
└── batchUpdateOrders()
```

### BLoC Layer
```
ProductSuggestionBloc
├── Events: LoadSuggestions, AddSuggestion, RemoveSuggestion, ReorderSuggestions, SearchProducts
├── States: Initial, Loading, Loaded, Error
└── Optimistic updates with error handling
```

### UI Layer
```
ProductSuggestionManagerScreen
├── Header with product info and add button
├── SuggestionSectionWidget (x3 for each type)
├── AddSuggestionDialog (searchable product selection)
└── Drag-and-drop reordering
```

## Database Schema

Uses existing `online_product_suggestions` table:

```sql
CREATE TABLE online_product_suggestions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_product_id UUID NOT NULL REFERENCES inventory_items(id),
  suggested_product_id UUID NOT NULL REFERENCES inventory_items(id),
  suggestion_type TEXT NOT NULL CHECK (
    suggestion_type IN ('frequently_bought_together', 'related', 'upsell')
  ),
  display_order INTEGER DEFAULT 1,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  CHECK (source_product_id != suggested_product_id),
  UNIQUE(source_product_id, suggested_product_id, suggestion_type)
);
```

## Usage

### Basic Integration

```dart
// Navigate to suggestion manager
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => BlocProvider(
      create: (context) => ProductSuggestionBloc(),
      child: ProductSuggestionManagerScreen(
        productId: product['id'],
        productName: product['online_display_name'] ?? product['name'],
      ),
    ),
  ),
);
```

### Service Usage

```dart
final service = ProductSuggestionService();

// Create suggestion
await service.createSuggestion(
  sourceProductId: 'product-1',
  suggestedProductId: 'product-2',
  suggestionType: 'frequently_bought_together',
  displayOrder: 1,
  performedBy: userId,
);

// Get suggestions
final suggestions = await service.getSuggestionsForProduct('product-1');

// Search products
final products = await service.searchProducts(
  query: 'steak',
  excludeProductId: 'product-1',
);
```

## Files Structure

```
lib/features/online_shop/
├── blocs/product_suggestion/
│   ├── product_suggestion_bloc.dart
│   ├── product_suggestion_event.dart
│   └── product_suggestion_state.dart
├── screens/
│   └── product_suggestion_manager_screen.dart
├── widgets/
│   ├── add_suggestion_dialog.dart
│   └── suggestion_section_widget.dart
└── integration_example.dart

lib/core/services/
└── product_suggestion_service.dart
```

## Dependencies

- `flutter_bloc`: State management
- `equatable`: BLoC event/state equality
- Existing admin app dependencies (BaseService, AuditService, AuthService)

## Validation Rules

### Database Level
- ✅ No self-reference (`CHECK (source_product_id != suggested_product_id)`)
- ✅ No duplicates (`UNIQUE` constraint)
- ✅ Foreign key integrity
- ✅ Type validation (`CHECK` constraint)

### Service Level
- ✅ Self-reference prevention
- ✅ Duplicate detection before insert
- ✅ Product availability validation
- ✅ Type validation against allowed values

### UI Level
- ✅ Real-time duplicate warnings
- ✅ Product availability indicators
- ✅ Confirmation dialogs for destructive actions

## Performance

- **Indexed Queries**: Optimized queries on `source_product_id` and `is_active`
- **Lazy Loading**: Product search loads on demand
- **Batch Updates**: Efficient reordering with batch operations
- **Optimistic UI**: Fast feedback with rollback capability
- **Caching**: Available products cached during session

## Audit Trail

All operations are logged with:
- Action type (CREATE, UPDATE, DELETE)
- Staff member performing action
- Detailed description
- Entity type and ID
- Old/new values for updates
- Timestamp

Example audit log entry:
```
"Created product suggestion: 'Rump Steak' → 'Wagyu Burger' (frequently_bought_together)"
```

## Error Handling

- **Service Layer**: BaseService provides retry logic and consistent error handling
- **BLoC Layer**: Error states with user-friendly messages
- **UI Layer**: Graceful degradation and clear error communication
- **Audit Service**: Errors logged without blocking operations

## Future Extensibility

This architecture supports:
- **AI Recommendations**: Add new suggestion types
- **Bundles**: Extend with bundle-specific logic
- **Analytics**: Track suggestion performance
- **Multi-App**: Service layer reusable across apps
- **Advanced Rules**: Business logic for automatic suggestions

## Testing

Recommended test coverage:
- Unit tests for service methods
- BLoC tests for all events/states
- Widget tests for UI components
- Integration tests for complete flows

## Security

- **Authentication**: All operations require authenticated user
- **Authorization**: Can be extended with role-based permissions
- **Input Validation**: All inputs validated at multiple layers
- **SQL Injection**: Protected by Supabase client library
