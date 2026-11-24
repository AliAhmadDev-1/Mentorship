import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/api_models.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../../../shared/widgets/glass_card.dart';

class MentorServicesScreen extends ConsumerStatefulWidget {
  const MentorServicesScreen({super.key, required this.mentorId});

  final String mentorId;

  @override
  ConsumerState<MentorServicesScreen> createState() =>
      _MentorServicesScreenState();
}

class _MentorServicesScreenState extends ConsumerState<MentorServicesScreen> {
  late Future<List<PackageResponse>> _packagesFuture;

  @override
  void initState() {
    super.initState();
    _packagesFuture = _load();
  }

  Future<List<PackageResponse>> _load() async {
    final response = await ref
        .read(microMentorApiProvider)
        .listPackages(mentorId: widget.mentorId);
    if (!response.success) throw response.error!;
    return response.data?.results ?? const [];
  }

  void _refresh() => setState(() => _packagesFuture = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        actions: [
          IconButton(
            tooltip: 'Add service',
            onPressed: () => _editPackage(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: FutureBuilder<List<PackageResponse>>(
        future: _packagesFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorStateWidget(
              title: 'Could not load services',
              message: '${snapshot.error}',
              onRetry: _refresh,
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final packages = snapshot.data!;
          if (packages.isEmpty) {
            return const AppEmptyState(
              icon: Icons.sell_outlined,
              title: 'No services yet',
              message: 'Add a duration and price so mentees can book you.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              itemCount: packages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final package = packages[index];
                return GlassCard(
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.schedule_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${package.durationMinutes ?? 0} minute session',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '\$${package.priceUsd.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Wrap(
                              spacing: 6,
                              children: [
                                if (package.isPopular == true)
                                  const Chip(label: Text('Popular')),
                                Chip(
                                  label: Text(
                                    package.isActive == false
                                        ? 'Inactive'
                                        : 'Active',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<_PackageAction>(
                        tooltip: 'Service actions',
                        onSelected: (action) => action == _PackageAction.edit
                            ? _editPackage(package)
                            : _delete(package),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: _PackageAction.edit,
                            child: Text('Edit'),
                          ),
                          PopupMenuItem(
                            value: _PackageAction.delete,
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add service',
        onPressed: () => _editPackage(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _editPackage([PackageResponse? existing]) async {
    final duration = TextEditingController(
      text: existing?.durationMinutes?.toString() ?? '30',
    );
    final price = TextEditingController(
      text: existing?.priceUsd.toStringAsFixed(2) ?? '',
    );
    var popular = existing?.isPopular ?? false;
    var active = existing?.isActive ?? true;
    final draft = await showModalBottomSheet<_PackageDraft>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  existing == null ? 'Add service' : 'Edit service',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: duration,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duration in minutes',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: price,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Price (USD)'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mark as popular'),
                  value: popular,
                  onChanged: (value) => setSheetState(() => popular = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Available for booking'),
                  value: active,
                  onChanged: (value) => setSheetState(() => active = value),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      final minutes = int.tryParse(duration.text.trim());
                      final amount = double.tryParse(price.text.trim());
                      if (minutes == null ||
                          minutes <= 0 ||
                          amount == null ||
                          amount < 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Enter a valid duration and price'),
                          ),
                        );
                        return;
                      }
                      Navigator.pop(
                        sheetContext,
                        _PackageDraft(
                          duration: minutes,
                          price: amount,
                          popular: popular,
                          active: active,
                        ),
                      );
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    duration.dispose();
    price.dispose();
    if (draft == null || !mounted) return;
    final body = <String, dynamic>{
      if (existing == null) 'mentor_id': widget.mentorId,
      'duration_minutes': draft.duration,
      'price_usd': draft.price.toStringAsFixed(2),
      'is_popular': draft.popular,
      'is_active': draft.active,
    };
    final api = ref.read(microMentorApiProvider);
    final response = existing == null
        ? await api.createPackage(body)
        : await api.updatePackage(existing.id, body);
    if (!mounted) return;
    if (!response.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.error!.message)));
      return;
    }
    _refresh();
  }

  Future<void> _delete(PackageResponse package) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete service?'),
        content: Text(
          '${package.durationMinutes ?? 0} minute sessions will no longer be bookable.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final response = await ref
        .read(microMentorApiProvider)
        .deletePackage(package.id);
    if (!mounted) return;
    if (!response.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.error!.message)));
      return;
    }
    _refresh();
  }
}

enum _PackageAction { edit, delete }

class _PackageDraft {
  const _PackageDraft({
    required this.duration,
    required this.price,
    required this.popular,
    required this.active,
  });

  final int duration;
  final double price;
  final bool popular;
  final bool active;
}
