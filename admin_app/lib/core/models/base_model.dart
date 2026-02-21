/// Base model class for all data models in the application
/// Provides common functionality for serialization and validation
abstract class BaseModel {
  /// Unique identifier for the model
  String? id;

  /// Timestamp when the record was created
  DateTime? createdAt;

  /// Timestamp when the record was last updated
  DateTime? updatedAt;

  /// Convert model to JSON map for database operations
  Map<String, dynamic> toJson();

  /// Create model instance from JSON map
  BaseModel fromJson(Map<String, dynamic> json);

  /// Validate the model data
  bool validate();

  /// Get validation errors if any
  List<String> getValidationErrors();
}