import 'package:isar/isar.dart';

part 'pending_write.g.dart';


/// Isar collection for offline write queue. Synced when connection returns.
@collection
class PendingWrite {
  Id id = Isar.autoIncrement;

  late String actionType;
  late String payload;
  late DateTime createdAt;
  int retryCount = 0;
  String? lastError;
  late String status; // 'pending' | 'failed'

  PendingWrite() {
    status = 'pending';
  }
}
