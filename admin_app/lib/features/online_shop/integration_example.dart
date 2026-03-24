/// Example integration for Product Suggestion Manager
/// Add this to your existing product management screen

/*
In your existing product list or detail screen, add a button to manage suggestions:

ElevatedButton.icon(
  onPressed: () {
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
  },
  icon: const Icon(Icons.recommend),
  label: const Text('Manage Suggestions'),
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
  ),
),

Or add it to a product context menu:

PopupMenuItem(
  value: 'manage_suggestions',
  child: Row(
    children: [
      Icon(Icons.recommend, size: 18),
      SizedBox(width: 12),
      Text('Manage Suggestions'),
    ],
  ),
),

Then in the onSelected handler:

case 'manage_suggestions':
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
  break;
*/

/// Also add the BLoC provider at the app level if needed:
/*
BlocProvider(
  create: (context) => ProductSuggestionBloc(),
  child: YourApp(),
),
*/
