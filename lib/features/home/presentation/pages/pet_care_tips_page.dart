import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

class PetCareTipsPage extends StatefulWidget {
  const PetCareTipsPage({super.key});

  @override
  State<PetCareTipsPage> createState() => _PetCareTipsPageState();
}

class _PetCareTipsPageState extends State<PetCareTipsPage> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All';

  static const List<String> _categories = [
    'All',
    'Nutrition',
    'Health',
    'Grooming',
    'Exercise',
    'Safety',
    'General',
  ];

  static const List<_PetCareTip> _tips = [
    _PetCareTip(
      title: 'Provide Fresh Water',
      description: 'Make sure your pet has access to clean, fresh drinking water throughout the day.',
      category: 'Nutrition',
      icon: Icons.water_drop_rounded,
    ),
    _PetCareTip(
      title: 'Maintain a Balanced Diet',
      description: 'Feed your pet an appropriate, balanced diet based on their age, size, and individual needs.',
      category: 'Nutrition',
      icon: Icons.restaurant_rounded,
    ),
    _PetCareTip(
      title: 'Keep Vaccinations Updated',
      description: 'Follow your veterinarian’s recommended vaccination schedule and keep your pet’s records updated.',
      category: 'Health',
      icon: Icons.vaccines_rounded,
    ),
    _PetCareTip(
      title: 'Schedule Regular Checkups',
      description: 'Routine veterinary checkups can help identify potential health problems early.',
      category: 'Health',
      icon: Icons.medical_services_rounded,
    ),
    _PetCareTip(
      title: 'Brush Your Pet Regularly',
      description: 'Regular brushing helps remove loose hair and keeps the coat clean and healthy.',
      category: 'Grooming',
      icon: Icons.brush_rounded,
    ),
    _PetCareTip(
      title: 'Keep Nails Trimmed',
      description: 'Check your pet’s nails regularly and have them trimmed safely when needed.',
      category: 'Grooming',
      icon: Icons.content_cut_rounded,
    ),
    _PetCareTip(
      title: 'Give Your Pet Daily Exercise',
      description: 'Provide age-appropriate physical activity to support your pet’s fitness and wellbeing.',
      category: 'Exercise',
      icon: Icons.directions_run_rounded,
    ),
    _PetCareTip(
      title: 'Make Your Home Safe',
      description: 'Keep medicines, chemicals, toxic foods, and other dangerous items away from your pets.',
      category: 'Safety',
      icon: Icons.home_rounded,
    ),
    _PetCareTip(
      title: 'Give Them Mental Stimulation',
      description: 'Interactive toys, training, and play can help keep your pet mentally active.',
      category: 'General',
      icon: Icons.psychology_rounded,
    ),
    _PetCareTip(
      title: 'Pay Attention to Behaviour Changes',
      description: 'Sudden changes in eating, drinking, activity, or behaviour can be worth discussing with a veterinarian.',
      category: 'General',
      icon: Icons.visibility_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  List<_PetCareTip> get _filteredTips {
    final query = _searchController.text.trim().toLowerCase();

    return _tips.where((tip) {
      final matchesCategory =
          _selectedCategory == 'All' || tip.category == _selectedCategory;

      final matchesSearch =
          query.isEmpty ||
          tip.title.toLowerCase().contains(query) ||
          tip.description.toLowerCase().contains(query) ||
          tip.category.toLowerCase().contains(query);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tips = _filteredTips;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Pet Care Tips')),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    'Take better care of your pet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.espresso,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Simple guidance for your pet’s everyday health and wellbeing.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.deepBrown.withValues(alpha: 0.72),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Search
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search pet care tips...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: _searchController.clear,
                              icon: const Icon(Icons.clear_rounded),
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    'Categories',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.espresso,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),

                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final selected = category == _selectedCategory;

                        return ChoiceChip(
                          label: Text(category),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          selectedColor: AppTheme.primary.withValues(
                            alpha: 0.18,
                          ),
                          backgroundColor: AppTheme.white,
                          labelStyle: TextStyle(
                            color: selected
                                ? AppTheme.primary
                                : AppTheme.deepBrown,
                            fontWeight: FontWeight.w700,
                          ),
                          side: BorderSide(
                            color: selected
                                ? AppTheme.primary.withValues(alpha: 0.35)
                                : AppTheme.secondary.withValues(alpha: 0.25),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 22),

                  Row(
                    children: [
                      Text(
                        'Care Tips',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.espresso,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        '${tips.length} tips',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.deepBrown.withValues(alpha: 0.65),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  if (tips.isEmpty)
                    const _EmptyTipsState()
                  else
                    ...tips.map(
                      (tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TipCard(tip: tip),
                      ),
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip});

  final _PetCareTip tip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepBrown.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(tip.icon, color: AppTheme.deepBrown, size: 25),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tip.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.espresso,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tip.category,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  tip.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.deepBrown.withValues(alpha: 0.78),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTipsState extends StatelessWidget {
  const _EmptyTipsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 42,
            color: AppTheme.deepBrown,
          ),
          const SizedBox(height: 10),
          Text(
            'No tips found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.espresso,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try another search or category.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _PetCareTip {
  const _PetCareTip({
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
  });

  final String title;
  final String description;
  final String category;
  final IconData icon;
}
