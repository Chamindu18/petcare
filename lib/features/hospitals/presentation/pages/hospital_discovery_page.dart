import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/router/app_router.dart';
import '../../data/repositories/firebase_hospital_repository.dart';
import '../../domain/entities/hospital.dart';
import '../../domain/usecases/hospital_usecases.dart';
import '../providers/hospital_provider.dart';

class HospitalDiscoveryPage extends StatefulWidget {
  const HospitalDiscoveryPage({super.key});

  @override
  State<HospitalDiscoveryPage> createState() => _HospitalDiscoveryPageState();
}

class _HospitalDiscoveryPageState extends State<HospitalDiscoveryPage> {
  late final HospitalProvider _hospitalProvider;

  // Controls the hospital name search field.
  final TextEditingController _searchController = TextEditingController();

  // Currently selected location filter.
  String _selectedLocation = 'All locations';

  @override
  void initState() {
    super.initState();

    // Connect the UI provider to the Firebase repository.
    _hospitalProvider = HospitalProvider(
      getHospitals: GetHospitals(FirebaseHospitalRepository()),
    );

    _hospitalProvider.loadHospitals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _hospitalProvider.dispose();
    super.dispose();
  }

  // Filters hospitals using the name and selected location.
  List<Hospital> _filterHospitals(List<Hospital> hospitals) {
    final searchText = _searchController.text.trim().toLowerCase();

    return hospitals.where((hospital) {
      final matchesName =
          searchText.isEmpty ||
          hospital.name.toLowerCase().contains(searchText);

      final matchesLocation =
          _selectedLocation == 'All locations' ||
          hospital.location.toLowerCase() == _selectedLocation.toLowerCase();

      return matchesName && matchesLocation;
    }).toList();
  }

  // Creates location options from the hospitals loaded from Firebase.
  List<String> _getLocations(List<Hospital> hospitals) {
    final locations = hospitals
        .map((hospital) => hospital.location.trim())
        .where((location) => location.isNotEmpty)
        .toSet()
        .toList();

    locations.sort();

    return ['All locations', ...locations];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Find a Hospital')),
      body: ListenableBuilder(
        listenable: _hospitalProvider,
        builder: (context, _) {
          if (_hospitalProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_hospitalProvider.errorMessage != null) {
            return _ErrorState(onRetry: _hospitalProvider.loadHospitals);
          }

          if (_hospitalProvider.hospitals.isEmpty) {
            return const _EmptyState();
          }

          final hospitals = _filterHospitals(_hospitalProvider.hospitals);

          final locations = _getLocations(_hospitalProvider.hospitals);

          return Column(
            children: [
              // Search hospitals by name.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) {
                    setState(() {});
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search hospital name',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),

              // Filter hospitals by location.
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedLocation,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  items: locations
                      .map(
                        (location) => DropdownMenuItem<String>(
                          value: location,
                          child: Text(location),
                        ),
                      )
                      .toList(),
                  onChanged: (location) {
                    if (location == null) {
                      return;
                    }

                    setState(() {
                      _selectedLocation = location;
                    });
                  },
                ),
              ),

              // Display filtered hospitals.
              Expanded(
                child: hospitals.isEmpty
                    ? const _NoSearchResultsState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        itemCount: hospitals.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final hospital = hospitals[index];

                          return _HospitalCard(
                            hospitalId: hospital.hospitalId,
                            name: hospital.name,
                            location: hospital.location,
                            contact: hospital.contact,
                            hours: hospital.hours,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HospitalCard extends StatelessWidget {
  const _HospitalCard({
    required this.hospitalId,
    required this.name,
    required this.location,
    required this.contact,
    required this.hours,
  });

  final String hospitalId;
  final String name;
  final String location;
  final String contact;
  final String hours;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.secondary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.local_hospital_outlined,
                    color: AppTheme.deepBrown,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.espresso,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _InfoRow(icon: Icons.location_on_outlined, text: location),

            const SizedBox(height: 8),

            _InfoRow(icon: Icons.phone_outlined, text: contact),

            const SizedBox(height: 8),

            _InfoRow(icon: Icons.access_time_outlined, text: hours),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // Open O15 and pass the selected hospital ID.
                  Navigator.pushNamed(
                    context,
                    AppRouter.hospitalDetails,
                    arguments: hospitalId,
                  );
                },
                child: const Text('View Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.deepBrown),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppTheme.espresso),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_hospital_outlined,
              size: 56,
              color: AppTheme.deepBrown,
            ),
            SizedBox(height: 16),
            Text(
              'No hospitals available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.espresso,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'There are no active hospitals to display right now.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoSearchResultsState extends StatelessWidget {
  const _NoSearchResultsState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: AppTheme.deepBrown),
            SizedBox(height: 16),
            Text(
              'No hospitals found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.espresso,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try a different hospital name or location.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppTheme.error),
            const SizedBox(height: 16),
            const Text(
              'Unable to load hospitals',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.espresso,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}
