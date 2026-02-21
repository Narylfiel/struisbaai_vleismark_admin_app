import '../../../core/models/base_model.dart';

/// Category model for inventory categorization
class Category extends BaseModel {
  final String name;
  final String colorCode;
  final String? notes;
  final int sortOrder;
  final bool isActive;

  const Category({
    required super.id,
    required this.name,
    required this.colorCode,
    this.notes,
    required this.sortOrder,
    required this.isActive,
    super.createdAt,
    super.updatedAt,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color_code': colorCode,
      'notes': notes,
      'sort_order': sortOrder,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      colorCode: json['color_code'] as String,
      notes: json['notes'] as String?,
      sortOrder: json['sort_order'] as int,
      isActive: json['is_active'] as bool,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Category copyWith({
    String? id,
    String? name,
    String? colorCode,
    String? notes,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      colorCode: colorCode ?? this.colorCode,
      notes: notes ?? this.notes,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Category(id: $id, name: $name, colorCode: $colorCode, sortOrder: $sortOrder, isActive: $isActive)';
  }
}

/// Predefined category colors
class CategoryColors {
  static const String red = '#FF0000';
  static const String pink = '#FFC0CB';
  static const String brown = '#8B4513';
  static const String yellow = '#FFFF00';
  static const String orange = '#FFA500';
  static const String blue = '#0000FF';
  static const String green = '#008000';
  static const String darkBrown = '#654321';
  static const String grey = '#808080';

  static const Map<String, String> predefinedColors = {
    'Beef': red,
    'Pork': pink,
    'Lamb': brown,
    'Chicken': yellow,
    'Processed': orange,
    'Drinks': blue,
    'Spices & Condiments': green,
    'Game & Venison': darkBrown,
    'Other': grey,
  };

  static String getColorForCategory(String categoryName) {
    return predefinedColors[categoryName] ?? grey;
  }

  static List<String> get availableColors => [
        red, pink, brown, yellow, orange, blue, green, darkBrown, grey,
        '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7', '#DDA0DD',
        '#98D8C8', '#F7DC6F', '#BB8FCE', '#85C1E9', '#F8C471', '#82E0AA',
      ];
}