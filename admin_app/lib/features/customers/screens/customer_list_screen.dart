import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/features/customers/services/customer_repository.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Column(
        children: [
          Container(
            color: AppColors.cardBg,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(icon: Icon(Icons.people, size: 18), text: 'Customers Directory'),
                Tab(icon: Icon(Icons.campaign, size: 18), text: 'Announcements'),
                Tab(icon: Icon(Icons.menu_book, size: 18), text: 'Recipe Library'),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _CustomersTab(),
                _AnnouncementsTab(),
                _RecipesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 1: CUSTOMERS DIRECTORY
// ══════════════════════════════════════════════════════════════════
class _CustomersTab extends StatefulWidget {
  @override
  State<_CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends State<_CustomersTab> {
  final _repo = CustomerRepository();
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final res = await _repo.getCustomers(searchQuery: _searchQuery);
    if (mounted) {
      setState(() {
        _customers = res;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleStatus(String id, bool currentState) async {
    await _repo.updateCustomerStatus(id, !currentState);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.cardBg,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by full name...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        _searchQuery = '';
                        _load();
                      },
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onSubmitted: (val) {
                    _searchQuery = val;
                    _load();
                  },
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          color: AppColors.surfaceBg,
          child: const Row(children: [
            Expanded(flex: 2, child: Text('NAME / CONTACT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
            SizedBox(width: 16),
            SizedBox(width: 100, child: Text('TIER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
            SizedBox(width: 16),
            SizedBox(width: 100, child: Text('PTS BALANCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
            SizedBox(width: 16),
            SizedBox(width: 100, child: Text('SPEND / MO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
            SizedBox(width: 16),
            SizedBox(width: 100, child: Text('VISITS / MO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
            SizedBox(width: 16),
            SizedBox(width: 100, child: Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
          ]),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _customers.isEmpty
                  ? Center(child: Text(_searchQuery.isEmpty ? 'No customers found in directory.' : 'No results for "$_searchQuery"'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: _customers.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (_, i) {
                        final c = _customers[i];
                        final id = c['id']?.toString() ?? '';
                        final tier = c['loyalty_tier'] ?? 'Member';
                        final isActive = c['is_active'] == true;
                        
                        Color tColor = AppColors.textSecondary;
                        if (tier == 'VIP') tColor = AppColors.accent;
                        if (tier == 'Elite') tColor = AppColors.primary;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c['full_name'] ?? '—', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(c['cell_phone'] ?? '—', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              )
                            ),
                            const SizedBox(width: 16),
                            SizedBox(width: 100, child: Row(children: [
                                if (tier == 'VIP' || tier == 'Elite') const Icon(Icons.star, size: 14, color: AppColors.accent),
                                const SizedBox(width: 4),
                                Text(tier, style: TextStyle(color: tColor, fontWeight: FontWeight.bold)),
                              ])
                            ),
                            const SizedBox(width: 16),
                            SizedBox(width: 100, child: Text('${c['points_balance'] ?? '0'} pts')),
                            const SizedBox(width: 16),
                            SizedBox(width: 100, child: Text('R ${(c['average_monthly_spend'] as num?)?.toStringAsFixed(2) ?? '0.00'}')),
                            const SizedBox(width: 16),
                            SizedBox(width: 100, child: Text('${c['visit_frequency'] ?? '0'}')),
                            const SizedBox(width: 16),
                            SizedBox(width: 100, child: 
                              InkWell(
                                onTap: () => _toggleStatus(id, isActive),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isActive ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: isActive ? AppColors.success : AppColors.error),
                                  ),
                                  child: Text(isActive ? 'Active' : 'Suspended', style: TextStyle(fontSize: 12, color: isActive ? AppColors.success : AppColors.error)),
                                ),
                              )
                            ),
                          ]),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 2: ANNOUNCEMENTS
// ══════════════════════════════════════════════════════════════════
class _AnnouncementsTab extends StatefulWidget {
  @override
  State<_AnnouncementsTab> createState() => _AnnouncementsTabState();
}

class _AnnouncementsTabState extends State<_AnnouncementsTab> {
  final _repo = CustomerRepository();
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final res = await _repo.getAnnouncements();
    if (mounted) {
      setState(() {
        _announcements = res;
        _isLoading = false;
      });
    }
  }

  void _createPush() {
    // Scaffold UI form would go here mapping specifically to target_tier inserts
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Push UI ready. Awaiting Supabase triggers.')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Push Announcements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(onPressed: _createPush, icon: const Icon(Icons.campaign), label: const Text('CREATE PUSH MESSAGE')),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _announcements.isEmpty
              ? const Center(child: Text('No active announcements targeting loyalty apps. Build one to reach customers.'))
              : ListView.builder(
                  itemCount: _announcements.length,
                  itemBuilder: (_, i) {
                    final item = _announcements[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.notifications_active, color: AppColors.primary),
                        title: Text(item['title'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(item['body'] ?? ''),
                        trailing: Text('Target: ${item['target_tier'] ?? 'All'}'),
                      ),
                    );
                  },
              ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 3: RECIPES
// ══════════════════════════════════════════════════════════════════
class _RecipesTab extends StatefulWidget {
  @override
  State<_RecipesTab> createState() => _RecipesTabState();
}

class _RecipesTabState extends State<_RecipesTab> {
  final _repo = CustomerRepository();
  List<Map<String, dynamic>> _recipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final res = await _repo.getRecipes();
    if (mounted) {
      setState(() {
        _recipes = res;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Recipe Library (Customer Facing App Feeds)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('UPLOAD RECIPE')),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _recipes.isEmpty
              ? const Center(child: Text('Add recipes here. Tag them with "Braai", "Game Meat", or "Sunday Roast" to show on customer feeds.'))
              : ListView.builder(
                  itemCount: _recipes.length,
                  itemBuilder: (_, i) {
                    final item = _recipes[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.fastfood, color: AppColors.accent),
                        title: Text(item['title'] ?? 'Unknown Recipe', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Tags: ${item['tags'] ?? 'None'}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: AppColors.error),
                          onPressed: () async {
                            await _repo.deleteRecipe(item['id']?.toString() ?? '');
                            _load();
                          },
                        ),
                      ),
                    );
                  },
              ),
          ),
        ],
      ),
    );
  }
}
