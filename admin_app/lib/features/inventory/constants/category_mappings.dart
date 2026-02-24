/// Valid category name → id mappings for inventory.
/// Use for display lookups and to ensure both category (text) and category_id (uuid) are written to inventory_items.
const Map<String, String> kCategoryNameToId = {
  'Beef': '4a5aeceb-747c-4faa-a558-fea9996849f2',
  'Chicken': '662e5be3-1de6-4f33-b666-75bb06b0ccd7',
  'Drinks': '1bcc0fee-55b5-4cba-80f9-bd8e80ae4159',
  'Game & Venison': '16d0ce40-cf0c-4451-9acf-553274f209cf',
  'Lamb': '6096b4ed-e9b2-456a-8ce3-441e6138e360',
  'Other': 'c36511d5-d0ce-45f8-9fe8-e51c2ca99638',
  'Pork': '6a393b7b-0209-4901-9e72-116cd8696567',
  'Processed': '2618deaa-152a-4304-9d45-43bbe4f86b17',
  'Spices & Condiments': 'e6432b06-441b-4e23-9b90-bb1ef3ca088d',
  'Services': 'f626c608-39bb-40f4-9374-04c11d6d370d',
  'Value Added Products': '482894db-9857-4606-a1e1-f6706574a39f',
};

/// Reverse map: id → name (for display when name is not in loaded list).
Map<String, String> get kCategoryIdToName {
  return {for (final e in kCategoryNameToId.entries) e.value: e.key};
}
