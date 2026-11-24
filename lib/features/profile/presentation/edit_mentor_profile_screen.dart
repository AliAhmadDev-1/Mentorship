import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/api_models.dart';
import '../../../core/providers/api_provider.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../../../shared/widgets/primary_button.dart';

class EditMentorProfileScreen extends ConsumerStatefulWidget {
  const EditMentorProfileScreen({super.key, required this.mentorId});

  final String mentorId;

  @override
  ConsumerState<EditMentorProfileScreen> createState() =>
      _EditMentorProfileScreenState();
}

class _EditMentorProfileScreenState
    extends ConsumerState<EditMentorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _headline = TextEditingController();
  final _bio = TextEditingController();
  final _company = TextEditingController();
  final _years = TextEditingController();
  final _city = TextEditingController();
  final _linkedin = TextEditingController();
  final _video = TextEditingController();
  late Future<_ProfileEditorData> _loadFuture;
  final _categoryIds = <int>{};
  final _expertiseIds = <int>{};
  bool _autoConfirm = true;
  bool _initialized = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  @override
  void dispose() {
    _headline.dispose();
    _bio.dispose();
    _company.dispose();
    _years.dispose();
    _city.dispose();
    _linkedin.dispose();
    _video.dispose();
    super.dispose();
  }

  Future<_ProfileEditorData> _load() async {
    final api = ref.read(microMentorApiProvider);
    final responses = await Future.wait([
      api.getMentorProfile(widget.mentorId),
      api.listCategories(),
      api.listExpertise(),
    ]);
    final profileResponse = responses[0];
    final categoryResponse = responses[1];
    final expertiseResponse = responses[2];
    if (!profileResponse.success) throw profileResponse.error!;
    if (!categoryResponse.success) throw categoryResponse.error!;
    if (!expertiseResponse.success) throw expertiseResponse.error!;
    return _ProfileEditorData(
      profile: profileResponse.data! as MentorProfileResponse,
      categories:
          ((categoryResponse.data! as ApiListResponse<CategoryResponse>).results
              .where((item) => item.isActive)
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder))),
      expertise:
          ((expertiseResponse.data! as ApiListResponse<ExpertiseResponse>)
              .results
              .where((item) => item.isActive)
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder))),
    );
  }

  void _initialize(_ProfileEditorData data) {
    if (_initialized) return;
    _initialized = true;
    final profile = data.profile;
    _headline.text = profile.headline;
    _bio.text = profile.bio ?? '';
    _company.text = profile.company ?? '';
    _years.text = profile.yearsExperience?.toString() ?? '';
    _city.text = profile.city ?? '';
    _linkedin.text = profile.linkedinUrl ?? '';
    _video.text = profile.introVideoUrl ?? '';
    _autoConfirm = profile.autoConfirmBookings ?? true;
    _categoryIds.addAll(profile.categoryIds);
    _expertiseIds.addAll(profile.expertiseIds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit mentor profile')),
      body: FutureBuilder<_ProfileEditorData>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorStateWidget(
              title: 'Could not load profile',
              message: '${snapshot.error}',
              onRetry: () => setState(() {
                _initialized = false;
                _loadFuture = _load();
              }),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          _initialize(data);
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(
                  'Professional details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _headline,
                  hint: 'Professional headline',
                  prefixIcon: Icons.badge_outlined,
                  validator: _required,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _bio,
                  hint: 'Professional bio',
                  prefixIcon: Icons.notes_outlined,
                  maxLines: 5,
                  validator: _required,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _company,
                  hint: 'Company',
                  prefixIcon: Icons.business_outlined,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _years,
                  hint: 'Years of experience',
                  prefixIcon: Icons.timeline_outlined,
                  keyboardType: TextInputType.number,
                  validator: _yearsValidator,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _city,
                  hint: 'City',
                  prefixIcon: Icons.location_city_outlined,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _linkedin,
                  hint: 'LinkedIn URL',
                  prefixIcon: Icons.link,
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _video,
                  hint: 'Intro video URL',
                  prefixIcon: Icons.video_library_outlined,
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 22),
                _OptionsSection<CategoryResponse>(
                  title: 'Categories',
                  items: data.categories,
                  selectedIds: _categoryIds,
                  idOf: (item) => item.id,
                  labelOf: (item) => item.name,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 18),
                _OptionsSection<ExpertiseResponse>(
                  title: 'Expertise',
                  items: data.expertise,
                  selectedIds: _expertiseIds,
                  idOf: (item) => item.id,
                  labelOf: (item) => item.name,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Automatically confirm bookings'),
                  value: _autoConfirm,
                  onChanged: (value) => setState(() => _autoConfirm = value),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Save changes',
                  icon: Icons.save_outlined,
                  isLoading: _saving,
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final response = await ref
        .read(microMentorApiProvider)
        .updateMentorProfile(widget.mentorId, {
          'headline': _headline.text.trim(),
          'bio': _bio.text.trim(),
          'company': _company.text.trim(),
          if (_years.text.trim().isNotEmpty)
            'years_experience': int.parse(_years.text.trim()),
          'city': _city.text.trim(),
          'linkedin_url': _linkedin.text.trim(),
          'intro_video_url': _video.text.trim(),
          'auto_confirm_bookings': _autoConfirm,
          'category_ids': _categoryIds.join(','),
          'expertise_ids': _expertiseIds.join(','),
        });
    if (!mounted) return;
    setState(() => _saving = false);
    if (!response.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.error!.message)));
      return;
    }
    ref.invalidate(profileProvider);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    context.pop(true);
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  String? _yearsValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final years = int.tryParse(value.trim());
    return years == null || years < 0 ? 'Enter a valid number of years' : null;
  }
}

class _OptionsSection<T> extends StatelessWidget {
  const _OptionsSection({
    required this.title,
    required this.items,
    required this.selectedIds,
    required this.idOf,
    required this.labelOf,
    required this.onChanged,
  });

  final String title;
  final List<T> items;
  final Set<int> selectedIds;
  final int Function(T item) idOf;
  final String Function(T item) labelOf;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final id = idOf(item);
            return FilterChip(
              label: Text(labelOf(item)),
              selected: selectedIds.contains(id),
              onSelected: (selected) {
                selected ? selectedIds.add(id) : selectedIds.remove(id);
                onChanged();
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ProfileEditorData {
  const _ProfileEditorData({
    required this.profile,
    required this.categories,
    required this.expertise,
  });

  final MentorProfileResponse profile;
  final List<CategoryResponse> categories;
  final List<ExpertiseResponse> expertise;
}
