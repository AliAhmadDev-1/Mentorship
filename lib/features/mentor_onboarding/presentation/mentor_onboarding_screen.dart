import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/api_models.dart';
import '../../../core/models/mentor_onboarding.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers/api_provider.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/mentor_onboarding_provider.dart';

class MentorOnboardingScreen extends ConsumerStatefulWidget {
  const MentorOnboardingScreen({super.key});

  @override
  ConsumerState<MentorOnboardingScreen> createState() =>
      _MentorOnboardingScreenState();
}

class _MentorOnboardingScreenState
    extends ConsumerState<MentorOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _headline = TextEditingController();
  final _company = TextEditingController();
  final _years = TextEditingController();
  final _bio = TextEditingController();
  final _linkedin = TextEditingController();
  final _portfolio = TextEditingController();
  final _startsAt = TextEditingController(text: '09:00:00');
  final _endsAt = TextEditingController(text: '17:00:00');
  final Map<int, TextEditingController> _prices = {
    for (final duration in const [15, 30, 45, 60])
      duration: TextEditingController(),
  };
  late final Future<_References> _references;
  bool _initialized = false;
  bool _busy = false;
  bool _agreed = false;
  bool _acceptsInquiries = true;
  String _profession = 'software_engineering';
  String _timezone = 'Asia/Karachi';
  int _interval = 30;
  int _popularDuration = 30;
  int _step = 0;
  int _furthestStep = 0;
  Set<int> _categoryIds = {};
  Set<int> _expertiseIds = {};
  Set<int> _weekdays = {1, 3, 5};
  Map<String, List<String>> _fieldErrors = const {};

  @override
  void initState() {
    super.initState();
    _references = _loadReferences();
  }

  @override
  void dispose() {
    for (final controller in [
      _headline,
      _company,
      _years,
      _bio,
      _linkedin,
      _portfolio,
      _startsAt,
      _endsAt,
      ..._prices.values,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = ref.watch(mentorOnboardingProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mentor verification'),
        actions: [
          TextButton(
            onPressed: _busy ? null : _saveAndExit,
            child: const Text('Save & sign out'),
          ),
        ],
      ),
      body: onboarding.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _LoadError(
          message: _message(error),
          onRetry: () => ref.invalidate(mentorOnboardingProvider),
        ),
        data: (draft) {
          _initialize(draft);
          if (!draft.canEdit) return _StatusView(draft: draft);
          return _buildEditor(draft);
        },
      ),
    );
  }

  Widget _buildEditor(MentorOnboardingDraft draft) {
    const titles = [
      'Professional profile',
      'Expertise',
      'Verification',
      'Services',
      'Availability',
      'Review',
    ];
    return SafeArea(
      child: Column(
        children: [
          LinearProgressIndicator(value: draft.completionPercent / 100),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    titles[_step],
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text('${draft.completionPercent}% complete'),
              ],
            ),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (draft.status == 'changes_requested')
                          _ChangesNotice(draft: draft),
                        _stepBody(draft),
                        if (_fieldErrors.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _ErrorSummary(errors: _fieldErrors),
                        ],
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            if (_step > 0)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _busy
                                      ? null
                                      : () => setState(() => _step--),
                                  icon: const Icon(Icons.arrow_back_rounded),
                                  label: const Text('Back'),
                                ),
                              ),
                            if (_step > 0) const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: PrimaryButton(
                                label: _step == 5
                                    ? 'Submit for review'
                                    : 'Save & continue',
                                isLoading: _busy,
                                onPressed:
                                    _busy ||
                                        (_step == 5 &&
                                            (!_agreed || !draft.canSubmit))
                                    ? null
                                    : _continue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepBody(MentorOnboardingDraft draft) => switch (_step) {
    0 => _professionalStep(),
    1 => _expertiseStep(),
    2 => _documentsStep(draft),
    3 => _servicesStep(draft),
    4 => _availabilityStep(),
    _ => _reviewStep(draft),
  };

  Widget _professionalStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _Intro('Tell mentees what you do and how you can help them.'),
      DropdownButtonFormField<String>(
        initialValue: _profession,
        decoration: const InputDecoration(labelText: 'Profession'),
        items: _professions.entries
            .map(
              (item) =>
                  DropdownMenuItem(value: item.key, child: Text(item.value)),
            )
            .toList(),
        onChanged: (value) => setState(() => _profession = value!),
      ),
      const SizedBox(height: 14),
      AppTextField(
        controller: _headline,
        hint: 'Professional headline',
        validator: (value) => _length(value, 'Headline', 10, 120),
      ),
      const SizedBox(height: 14),
      AppTextField(
        controller: _company,
        hint: 'Company (optional)',
        validator: (value) =>
            (value?.length ?? 0) > 120 ? 'Use 120 characters or fewer' : null,
      ),
      const SizedBox(height: 14),
      AppTextField(
        controller: _years,
        hint: 'Years of experience',
        keyboardType: TextInputType.number,
        validator: _validateYears,
      ),
      const SizedBox(height: 14),
      AppTextField(
        controller: _bio,
        hint: 'Professional bio',
        maxLines: 6,
        validator: (value) => _length(value, 'Bio', 80, 2000),
      ),
      const SizedBox(height: 14),
      AppTextField(
        controller: _linkedin,
        hint: 'LinkedIn HTTPS URL (optional)',
        keyboardType: TextInputType.url,
        validator: _httpsUrl,
      ),
      const SizedBox(height: 14),
      AppTextField(
        controller: _portfolio,
        hint: 'Portfolio HTTPS URL (optional)',
        keyboardType: TextInputType.url,
        validator: _httpsUrl,
      ),
    ],
  );

  Widget _expertiseStep() => FutureBuilder<_References>(
    future: _references,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) return _Intro(_message(snapshot.error!));
      final refs = snapshot.requireData;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Intro(
            'Choose at least one active category and one specialty.',
          ),
          Text('Categories', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: refs.categories
                .map(
                  (item) => FilterChip(
                    label: Text(item.name),
                    selected: _categoryIds.contains(item.id),
                    onSelected: (selected) => setState(
                      () => selected
                          ? _categoryIds.add(item.id)
                          : _categoryIds.remove(item.id),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          Text('Expertise', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: refs.expertise
                .map(
                  (item) => FilterChip(
                    label: Text(item.name),
                    selected: _expertiseIds.contains(item.id),
                    onSelected: (selected) => setState(
                      () => selected
                          ? _expertiseIds.add(item.id)
                          : _expertiseIds.remove(item.id),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      );
    },
  );

  Widget _documentsStep(MentorOnboardingDraft draft) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _Intro(
        'Upload at least one professional proof document. PDF, JPEG, or PNG; maximum 10 MB.',
      ),
      for (final type in const [
        'identity',
        'employment',
        'certificate',
        'education',
        'portfolio',
        'other',
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _DocumentTile(
            type: type,
            document: _documentFor(draft, type),
            busy: _busy,
            onUpload: () => _pickDocument(type),
            onDelete: (document) => _deleteDocument(document),
          ),
        ),
    ],
  );

  Widget _servicesStep(MentorOnboardingDraft draft) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _Intro(
        'Set prices for the session lengths you want to offer. Leave a price blank to disable it.',
      ),
      for (final duration in const [15, 30, 45, 60])
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                SizedBox(width: 72, child: Text('$duration min')),
                Expanded(
                  child: AppTextField(
                    controller: _prices[duration]!,
                    hint: 'Price USD',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _price,
                  ),
                ),
                IconButton(
                  tooltip: 'Mark as popular',
                  onPressed: () => setState(() => _popularDuration = duration),
                  icon: Icon(
                    duration == _popularDuration
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                  ),
                ),
              ],
            ),
          ),
        ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Accept direct inquiries'),
        value: _acceptsInquiries,
        onChanged: (value) => setState(() => _acceptsInquiries = value),
      ),
    ],
  );

  Widget _availabilityStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _Intro(
        'Choose your recurring availability using your local timezone.',
      ),
      DropdownButtonFormField<String>(
        initialValue: _timezone,
        decoration: const InputDecoration(labelText: 'Timezone'),
        items:
            const [
                  'Asia/Karachi',
                  'UTC',
                  'America/New_York',
                  'Europe/London',
                  'Asia/Dubai',
                ]
                .map((zone) => DropdownMenuItem(value: zone, child: Text(zone)))
                .toList(),
        onChanged: (value) => setState(() => _timezone = value!),
      ),
      const SizedBox(height: 14),
      Wrap(
        spacing: 8,
        children: List.generate(7, (index) {
          final day = index + 1;
          return FilterChip(
            label: Text(_dayNames[index]),
            selected: _weekdays.contains(day),
            onSelected: (selected) => setState(
              () => selected ? _weekdays.add(day) : _weekdays.remove(day),
            ),
          );
        }),
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: AppTextField(
              controller: _startsAt,
              hint: 'Starts (HH:MM:SS)',
              validator: _time,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppTextField(
              controller: _endsAt,
              hint: 'Ends (HH:MM:SS)',
              validator: _time,
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      DropdownButtonFormField<int>(
        initialValue: _interval,
        decoration: const InputDecoration(labelText: 'Session interval'),
        items: const [15, 30, 45, 60]
            .map(
              (minutes) => DropdownMenuItem(
                value: minutes,
                child: Text('$minutes minutes'),
              ),
            )
            .toList(),
        onChanged: (value) => setState(() => _interval = value!),
      ),
    ],
  );

  Widget _reviewStep(MentorOnboardingDraft draft) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _Intro(
        'Review your application before sending it for verification.',
      ),
      GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReviewRow(label: 'Profile', value: _headline.text),
            _ReviewRow(
              label: 'Categories',
              value: '${_categoryIds.length} selected',
            ),
            _ReviewRow(
              label: 'Expertise',
              value: '${_expertiseIds.length} selected',
            ),
            _ReviewRow(
              label: 'Ready documents',
              value: '${draft.documents.where((item) => item.isReady).length}',
            ),
            _ReviewRow(
              label: 'Packages',
              value: '${_packagePayload().length} active',
            ),
            _ReviewRow(label: 'Available days', value: '${_weekdays.length}'),
          ],
        ),
      ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: _agreed,
        onChanged: (value) => setState(() => _agreed = value ?? false),
        title: const Text(
          'I confirm that the information provided is accurate.',
        ),
        subtitle: const Text('Mentor terms version: mentor-terms-2026-08'),
      ),
    ],
  );

  Future<void> _continue() async {
    if (_step == 0 || _step == 3 || _step == 4) {
      if (!_formKey.currentState!.validate()) return;
    }
    if (_step == 1 && (_categoryIds.isEmpty || _expertiseIds.isEmpty)) {
      _show('Select at least one category and one expertise.');
      return;
    }
    if (_step == 4 && _weekdays.isEmpty) {
      _show('Select at least one available day.');
      return;
    }
    setState(() {
      _busy = true;
      _fieldErrors = const {};
    });
    try {
      if (_step == 5) {
        await ref.read(mentorOnboardingProvider.notifier).submit();
      } else {
        await ref
            .read(mentorOnboardingProvider.notifier)
            .save(_payloadForStep());
        if (mounted) {
          setState(() {
            _step++;
            if (_step > _furthestStep) _furthestStep = _step;
          });
        }
      }
    } catch (error) {
      if (!mounted) return;
      if (error is ApiException) {
        setState(() => _fieldErrors = error.fieldErrors);
      }
      _show(_message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveAndExit() async {
    if ((_step == 0 || _step == 3 || _step == 4) &&
        !_formKey.currentState!.validate()) {
      return;
    }
    if (_step == 1 && (_categoryIds.isEmpty || _expertiseIds.isEmpty)) {
      _show('Select at least one category and one expertise.');
      return;
    }
    if (_step == 4 && _weekdays.isEmpty) {
      _show('Select at least one available day.');
      return;
    }
    setState(() => _busy = true);
    try {
      if (_step < 5) {
        await ref
            .read(mentorOnboardingProvider.notifier)
            .save(_payloadForStep());
      }
      await ref.read(authProvider.notifier).signOut();
      if (mounted) context.go('/auth/login');
    } catch (error) {
      if (!mounted) return;
      if (error is ApiException) {
        setState(() => _fieldErrors = error.fieldErrors);
      }
      _show(_message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Map<String, dynamic> _payloadForStep() => switch (_step) {
    0 => {
      'current_step': _savedStepAfterCurrent(),
      'professional_profile': {
        'profession': _profession,
        'headline': _headline.text.trim(),
        'company': _nullable(_company.text),
        'years_experience': int.parse(_years.text.trim()),
        'bio': _bio.text.trim(),
        'linkedin_url': _nullable(_linkedin.text),
        'portfolio_url': _nullable(_portfolio.text),
      },
    },
    1 => {
      'current_step': _savedStepAfterCurrent(),
      'category_ids': _categoryIds.toList(),
      'expertise_ids': _expertiseIds.toList(),
    },
    2 => {'current_step': _savedStepAfterCurrent()},
    3 => {
      'current_step': _savedStepAfterCurrent(),
      'accepts_inquiries': _acceptsInquiries,
      'packages': _packagePayload(),
    },
    _ => {
      'current_step': _savedStepAfterCurrent(),
      'timezone': _timezone,
      'availability_windows': _weekdays
          .map(
            (day) => {
              'client_id': 'day-$day-${_startsAt.text.replaceAll(':', '')}',
              'weekday': day,
              'starts_at': _startsAt.text,
              'ends_at': _endsAt.text,
              'slot_interval_minutes': _interval,
              'is_active': true,
            },
          )
          .toList(),
    },
  };

  String _savedStepAfterCurrent() {
    final nextStep = (_step + 1).clamp(0, _onboardingSteps.length - 1);
    final persistedStep = nextStep > _furthestStep ? nextStep : _furthestStep;
    return _onboardingSteps[persistedStep];
  }

  List<Map<String, dynamic>> _packagePayload() => _prices.entries
      .where(
        (item) =>
            item.value.text.trim().isNotEmpty &&
            (double.tryParse(item.value.text.trim()) ?? 0) > 0,
      )
      .map(
        (item) => {
          'client_id': 'mobile-${item.key}',
          'duration_minutes': item.key,
          'price_usd': double.parse(item.value.text.trim()).toStringAsFixed(2),
          'is_popular': item.key == _popularDuration,
          'is_active': true,
        },
      )
      .toList();

  Future<void> _pickDocument(String type) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || !mounted) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      _show('Could not read that file.');
      return;
    }
    final contentType = switch (file.extension?.toLowerCase()) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      _ => 'image/jpeg',
    };
    setState(() => _busy = true);
    try {
      await ref
          .read(mentorOnboardingProvider.notifier)
          .uploadDocument(
            documentType: type,
            fileName: file.name,
            contentType: contentType,
            bytes: bytes,
          );
    } catch (error) {
      if (mounted) _show(_message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteDocument(MentorDocument document) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(mentorOnboardingProvider.notifier)
          .deleteDocument(document.id);
    } catch (error) {
      if (mounted) _show(_message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _initialize(MentorOnboardingDraft draft) {
    if (_initialized) return;
    _initialized = true;
    final profile = draft.professionalProfile;
    _profession = profile.profession ?? _profession;
    _headline.text = profile.headline ?? '';
    _company.text = profile.company ?? '';
    _years.text = profile.yearsExperience?.toString() ?? '';
    _bio.text = profile.bio ?? '';
    _linkedin.text = profile.linkedinUrl ?? '';
    _portfolio.text = profile.portfolioUrl ?? '';
    _categoryIds = draft.categoryIds.toSet();
    _expertiseIds = draft.expertiseIds.toSet();
    _timezone = draft.timezone ?? _timezone;
    _acceptsInquiries = draft.acceptsInquiries;
    if (draft.availabilityWindows.isNotEmpty) {
      final first = draft.availabilityWindows.first;
      _weekdays = draft.availabilityWindows
          .where((item) => item.isActive)
          .map((item) => item.weekday)
          .toSet();
      _startsAt.text = first.startsAt;
      _endsAt.text = first.endsAt;
      _interval = first.slotIntervalMinutes;
    }
    for (final package in draft.packages) {
      _prices[package.durationMinutes]?.text = package.isActive
          ? package.priceUsd
          : '';
      if (package.isPopular) _popularDuration = package.durationMinutes;
    }
    _step = _stepIndex(draft.currentStep);
    _furthestStep = _step;
  }

  Future<_References> _loadReferences() async {
    final api = ref.read(microMentorApiProvider);
    final categories = await api.listCategories();
    final expertise = await api.listExpertise();
    if (!categories.success) throw categories.error!;
    if (!expertise.success) throw expertise.error!;
    final categoryItems = [...?categories.data?.results]
      ..removeWhere((item) => !item.isActive)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final expertiseItems = [...?expertise.data?.results]
      ..removeWhere((item) => !item.isActive)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return _References(categories: categoryItems, expertise: expertiseItems);
  }

  MentorDocument? _documentFor(MentorOnboardingDraft draft, String type) {
    for (final document in draft.documents.reversed) {
      if (document.documentType == type && document.status != 'deleted') {
        return document;
      }
    }
    return null;
  }

  void _show(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class _References {
  const _References({required this.categories, required this.expertise});
  final List<CategoryResponse> categories;
  final List<ExpertiseResponse> expertise;
}

class _Intro extends StatelessWidget {
  const _Intro(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
  );
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.type,
    required this.document,
    required this.busy,
    required this.onUpload,
    required this.onDelete,
  });
  final String type;
  final MentorDocument? document;
  final bool busy;
  final VoidCallback onUpload;
  final ValueChanged<MentorDocument> onDelete;
  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        Icon(
          document?.isReady == true
              ? Icons.verified_rounded
              : Icons.description_outlined,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_title(type), style: Theme.of(context).textTheme.titleSmall),
              Text(
                document == null
                    ? 'Not uploaded'
                    : '${document!.fileName} · ${document!.status}',
              ),
            ],
          ),
        ),
        if (document != null)
          IconButton(
            tooltip: 'Delete document',
            onPressed: busy ? null : () => onDelete(document!),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        IconButton(
          tooltip: document == null ? 'Upload document' : 'Replace document',
          onPressed: busy ? null : onUpload,
          icon: const Icon(Icons.upload_file_rounded),
        ),
      ],
    ),
  );
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _ChangesNotice extends StatelessWidget {
  const _ChangesNotice({required this.draft});
  final MentorOnboardingDraft draft;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Changes requested',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (draft.reviewNotes != null) Text(draft.reviewNotes!),
          if (draft.fieldsRequiringChanges.isNotEmpty)
            Text(draft.fieldsRequiringChanges.join(', ')),
        ],
      ),
    ),
  );
}

class _ErrorSummary extends StatelessWidget {
  const _ErrorSummary({required this.errors});
  final Map<String, List<String>> errors;
  @override
  Widget build(BuildContext context) => GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Needs attention', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final entry in errors.entries)
          Text('${entry.key}: ${entry.value.join(', ')}'),
      ],
    ),
  );
}

class _StatusView extends ConsumerWidget {
  const _StatusView({required this.draft});
  final MentorOnboardingDraft draft;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          children: [
            Icon(
              draft.isVerified
                  ? Icons.verified_rounded
                  : draft.isRejected
                  ? Icons.cancel_outlined
                  : Icons.hourglass_top_rounded,
              size: 64,
            ),
            const SizedBox(height: 18),
            Text(
              draft.isVerified
                  ? 'You are verified'
                  : draft.isRejected
                  ? 'Application not approved'
                  : 'Application under review',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            if (draft.reviewNotes != null)
              Text(draft.reviewNotes!, textAlign: TextAlign.center),
            const SizedBox(height: 22),
            PrimaryButton(
              label: 'Refresh status',
              onPressed: () =>
                  ref.read(mentorOnboardingProvider.notifier).reload(),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Go to dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}

const _professions = {
  'software_engineering': 'Software engineering',
  'data_science': 'Data science',
  'product_management': 'Product management',
  'design': 'Design',
  'marketing': 'Marketing',
  'finance': 'Finance',
  'operations': 'Operations',
  'human_resources': 'Human resources',
  'sales': 'Sales',
  'other': 'Other',
};
const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _onboardingSteps = [
  'professional_profile',
  'expertise',
  'verification',
  'services',
  'availability',
  'review',
];
int _stepIndex(String step) =>
    const {
      'professional_profile': 0,
      'expertise': 1,
      'verification': 2,
      'services': 3,
      'availability': 4,
      'review': 5,
    }[step] ??
    0;
String _title(String value) => value[0].toUpperCase() + value.substring(1);
String? _nullable(String value) => value.trim().isEmpty ? null : value.trim();
String _message(Object error) => error is ApiException
    ? error.message
    : 'Something went wrong. Please try again.';
String? _length(String? value, String label, int min, int max) {
  final length = value?.trim().length ?? 0;
  if (length < min || length > max) {
    return '$label must be $min–$max characters';
  }
  return null;
}

String? _validateYears(String? value) {
  final years = int.tryParse(value?.trim() ?? '');
  return years == null || years < 0 || years > 60
      ? 'Enter a number from 0 to 60'
      : null;
}

String? _httpsUrl(String? value) {
  final text = value?.trim() ?? '';
  return text.isNotEmpty && !text.startsWith('https://')
      ? 'Use a secure https:// URL'
      : null;
}

String? _price(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  final amount = double.tryParse(text);
  return amount == null || amount <= 0 ? 'Enter a valid price' : null;
}

String? _time(String? value) =>
    RegExp(r'^([01]\d|2[0-3]):[0-5]\d:[0-5]\d$').hasMatch(value?.trim() ?? '')
    ? null
    : 'Use HH:MM:SS';
