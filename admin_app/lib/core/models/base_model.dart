/// Base model class for all data models in the application
/// Provides common functionality for serialization and validation
abstract class BaseModel {
  /// Unique identifier for the model
  final String id;

  /// Timestamp when the record was created
  final DateTime? createdAt;

  /// Timestamp when the record was last updated
  final DateTime? updatedAt;

  const BaseModel({
    required this.id,
    this.createdAt,
    this.updatedAt,
  });

  /// Convert model to JSON map for database operations
  Map<String, dynamic> toJson();

  /// Validate the model data
  bool validate();

  /// Get validation errors if any
  List<String> getValidationErrors();
}