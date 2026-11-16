import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

// Describes whether a portfolio project is finished or still in progress.
enum _PortfolioStatus { completed, pending }

// Stores all information shown for one portfolio project.
class _PortfolioProject {
  const _PortfolioProject({
    required this.title,
    required this.client,
    required this.date,
    required this.category,
    required this.tags,
    required this.status,
    required this.description,
    required this.imageAlignment,
    this.imageBytes,
  });

  final String title;
  final String client;
  final String date;
  final String category;
  final List<String> tags;
  final _PortfolioStatus status;
  final String description;
  final Alignment imageAlignment;
  final Uint8List? imageBytes;

  _PortfolioProject copyWith({Uint8List? imageBytes}) {
    return _PortfolioProject(
      title: title,
      client: client,
      date: date,
      category: category,
      tags: tags,
      status: status,
      description: description,
      imageAlignment: imageAlignment,
      imageBytes: imageBytes ?? this.imageBytes,
    );
  }
}

// This screen stores and displays a worker's project portfolio.
class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  PortfolioPageState createState() => PortfolioPageState();
}

// The project list, filters, and photo actions are managed here.
class PortfolioPageState extends State<PortfolioPage> {
  static const _allFilter = 'All Work';
  static const _completedFilter = 'Completed';
  static const _pendingFilter = 'Pending';

  String _selectedFilter = _allFilter;
  final ImagePicker _imagePicker = ImagePicker();
  final List<_PortfolioProject> _projects = [
    const _PortfolioProject(
      title: 'Commercial Office Rewiring',
      client: 'Google SF Hub',
      date: 'Jan 2026',
      category: 'Commercial',
      tags: ['Commercial', 'Safety Compliance'],
      status: _PortfolioStatus.completed,
      description:
          'Completed commercial office rewiring, organized server-room '
          'cabling, and tested the electrical and network connections. '
          'Work was carried out following site safety and compliance '
          'requirements.',
      imageAlignment: Alignment.centerRight,
    ),
    const _PortfolioProject(
      title: 'Residential Smart Grid Set',
      client: 'Linden Homes',
      date: 'Nov 2025',
      category: 'Solar',
      tags: ['Solar', 'Smart Home'],
      status: _PortfolioStatus.completed,
      description:
          'Installed and configured a residential smart grid monitoring '
          'system. Verified the control unit, connected the sensors, and '
          'tested the system with the homeowner.',
      imageAlignment: Alignment.centerLeft,
    ),
    const _PortfolioProject(
      title: 'Apartment Lighting Upgrade',
      client: 'Greenview Properties',
      date: 'In progress',
      category: 'Electrical',
      tags: ['Electrical', 'Installation'],
      status: _PortfolioStatus.pending,
      description:
          'Upgrade apartment lighting fixtures and test the updated '
          'circuits. Final inspection and client handover are pending.',
      imageAlignment: Alignment.center,
    ),
  ];

  List<_PortfolioProject> get _visibleProjects {
    // Only show projects that match the selected filter.
    return _projects.where((project) {
      return switch (_selectedFilter) {
        _completedFilter => project.status == _PortfolioStatus.completed,
        _pendingFilter => project.status == _PortfolioStatus.pending,
        _ => true,
      };
    }).toList();
  }

  int _countFor(String filter) {
    // Count projects for the filter labels at the top of the page.
    if (filter == _allFilter) return _projects.length;
    if (filter == _completedFilter) {
      return _projects
          .where((project) => project.status == _PortfolioStatus.completed)
          .length;
    }
    return _projects
        .where((project) => project.status == _PortfolioStatus.pending)
        .length;
  }

  // Adds a new project to the portfolio from the add-project dialog.
  Future<void> _addProject() async {
    final project = await showDialog<_PortfolioProject>(
      context: context,
      builder: (_) => const _AddPortfolioProjectDialog(),
    );
    if (!mounted || project == null) return;
    _insertProject(project);
  }

  Future<bool> addCompletedJobProject({
    required String title,
    required String client,
    required String category,
    required String description,
  }) async {
    final project = await showDialog<_PortfolioProject>(
      context: context,
      builder: (_) => _AddPortfolioProjectDialog(
        initialTitle: title,
        initialClient: client,
        initialCategory: category,
        initialDescription: description,
        isCompleted: true,
      ),
    );
    if (!mounted || project == null) return false;
    _insertProject(project);
    return true;
  }

  void _insertProject(_PortfolioProject project) {
    // Put new projects first and reset the filter so the new item is visible.
    setState(() {
      _projects.insert(0, project);
      _selectedFilter = _allFilter;
    });
  }

  Future<void> _pickProjectPhoto(_PortfolioProject project) async {
    // Let the user choose a photo and store its bytes on the project.
    try {
      final selectedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1800,
      );
      if (!mounted || selectedImage == null) return;
      final imageBytes = await selectedImage.readAsBytes();
      final projectIndex = _projects.indexOf(project);
      if (!mounted || projectIndex == -1) return;
      setState(() {
        _projects[projectIndex] = project.copyWith(imageBytes: imageBytes);
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Could not select project photo: $error')),
        );
    }
  }

  void _openProject(_PortfolioProject project) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _PortfolioProjectDetailsPage(project: project),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build the filter buttons and show the projects that match the filter.
    const filters = [_allFilter, _completedFilter, _pendingFilter];
    final projects = _visibleProjects;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Work Portfolio',
                    style: TextStyle(
                      color: Color(0xFF10243B),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Visual proof of compliance and workmanship.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                  ),
                  const SizedBox(height: 15),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final filter in filters)
                          Padding(
                            padding: const EdgeInsets.only(right: 7),
                            child: _PortfolioFilterChip(
                              label: '$filter (${_countFor(filter)})',
                              selected: _selectedFilter == filter,
                              onTap: () =>
                                  setState(() => _selectedFilter = filter),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: projects.isEmpty
                  ? const Center(
                      child: Text(
                        'No projects in this section yet.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
                      itemCount: projects.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 11),
                      itemBuilder: (context, index) {
                        final project = projects[index];
                        return _PortfolioProjectCard(
                          project: project,
                          onTap: () => _openProject(project),
                          onAddPhoto: () => _pickProjectPhoto(project),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProject,
        backgroundColor: const Color(0xFF009E9A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Project'),
      ),
    );
  }
}

// Shows one filter button and the number of matching projects.
class _PortfolioFilterChip extends StatelessWidget {
  const _PortfolioFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF009E9A) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? const Color(0xFF009E9A)
                  : const Color(0xFFDCE3EB),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF34445A),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// Shows a project summary with its photo, status, and tags.
class _PortfolioProjectCard extends StatelessWidget {
  const _PortfolioProjectCard({
    required this.project,
    required this.onTap,
    required this.onAddPhoto,
  });

  final _PortfolioProject project;
  final VoidCallback onTap;
  final VoidCallback onAddPhoto;

  @override
  Widget build(BuildContext context) {
    final completed = project.status == _PortfolioStatus.completed;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE0E6EE)),
            borderRadius: BorderRadius.circular(13),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 122,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _ProjectImage(project: project, height: 122),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: FilledButton.tonalIcon(
                        onPressed: onAddPhoto,
                        icon: Icon(
                          project.imageBytes == null
                              ? Icons.add_a_photo_outlined
                              : Icons.edit_outlined,
                          size: 14,
                        ),
                        label: Text(
                          project.imageBytes == null
                              ? 'Add Photo'
                              : 'Change Photo',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.94),
                          foregroundColor: const Color(0xFF10243B),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            project.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF10243B),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _ProjectStatusBadge(completed: completed),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${project.client} · ${project.date}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 9,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: [
                        for (final tag in project.tags) _ProjectTag(label: tag),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Shows the chosen project photo or a placeholder image.
class _ProjectImage extends StatelessWidget {
  const _ProjectImage({required this.project, required this.height});

  final _PortfolioProject project;
  final double height;

  @override
  Widget build(BuildContext context) {
    final imageBytes = project.imageBytes;
    if (imageBytes != null) {
      return Image.memory(
        imageBytes,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
    return Image.asset(
      'assets/tradeproof_workers.png',
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      alignment: project.imageAlignment,
    );
  }
}

// Shows whether a project is completed or still in progress.
class _ProjectStatusBadge extends StatelessWidget {
  const _ProjectStatusBadge({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    final color = completed ? const Color(0xFF008C68) : const Color(0xFFB36B00);
    final background = completed
        ? const Color(0xFFE9FFF6)
        : const Color(0xFFFFF5E5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(
          color: completed ? const Color(0xFF9BEBC9) : const Color(0xFFFFD58B),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            completed ? 'COMPLETED' : 'PENDING',
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectTag extends StatelessWidget {
  const _ProjectTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6F9),
        border: Border.all(color: const Color(0xFFDCE4EC)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFF40536A), fontSize: 8),
      ),
    );
  }
}

// Shows the full description and photo for one project.
class _PortfolioProjectDetailsPage extends StatelessWidget {
  const _PortfolioProjectDetailsPage({required this.project});

  final _PortfolioProject project;

  @override
  Widget build(BuildContext context) {
    final completed = project.status == _PortfolioStatus.completed;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      appBar: AppBar(
        title: const Text('Project Details'),
        backgroundColor: const Color(0xFFF3F5F8),
        foregroundColor: const Color(0xFF10243B),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 205,
              width: double.infinity,
              child: _ProjectImage(project: project, height: 205),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          project.title,
                          style: const TextStyle(
                            color: Color(0xFF10243B),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ProjectStatusBadge(completed: completed),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${project.client} · ${project.date}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'PROJECT DESCRIPTION',
                    style: TextStyle(
                      color: Color(0xFF00999D),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    project.description,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'CATEGORY & SKILLS',
                    style: TextStyle(
                      color: Color(0xFF00999D),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _ProjectTag(label: project.category),
                      for (final tag in project.tags) _ProjectTag(label: tag),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        completed
                            ? Icons.verified_outlined
                            : Icons.pending_outlined,
                        color: completed
                            ? const Color(0xFF008C68)
                            : const Color(0xFFB36B00),
                        size: 18,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          completed
                              ? 'This project is marked as completed.'
                              : 'This project is still in progress.',
                          style: const TextStyle(
                            color: Color(0xFF334155),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Collects the details and optional photo for a new project.
class _AddPortfolioProjectDialog extends StatefulWidget {
  const _AddPortfolioProjectDialog({
    this.initialTitle = '',
    this.initialClient = '',
    this.initialCategory = '',
    this.initialDescription = '',
    this.isCompleted = false,
  });

  final String initialTitle;
  final String initialClient;
  final String initialCategory;
  final String initialDescription;
  final bool isCompleted;

  @override
  State<_AddPortfolioProjectDialog> createState() =>
      _AddPortfolioProjectDialogState();
}

class _AddPortfolioProjectDialogState
    extends State<_AddPortfolioProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _clientController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _imageBytes;
  bool _isPickingImage = false;

  @override
  void initState() {
    // Fill the form with job details when adding a completed dashboard job.
    super.initState();
    _titleController.text = widget.initialTitle;
    _clientController.text = widget.initialClient;
    _categoryController.text = widget.initialCategory;
    _descriptionController.text = widget.initialDescription;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _clientController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    // Check the required fields before returning the new project.
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    Navigator.of(context).pop(
      _PortfolioProject(
        title: _titleController.text.trim(),
        client: _clientController.text.trim(),
        date: widget.isCompleted
            ? '${_monthNames[now.month - 1]} ${now.year}'
            : 'In progress',
        category: _categoryController.text.trim(),
        tags: [_categoryController.text.trim()],
        status: widget.isCompleted
            ? _PortfolioStatus.completed
            : _PortfolioStatus.pending,
        description: _descriptionController.text.trim(),
        imageAlignment: Alignment.center,
        imageBytes: _imageBytes,
      ),
    );
  }

  Future<void> _pickPhoto() async {
    // Add an optional photo to the project being created.
    setState(() => _isPickingImage = true);
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1800,
      );
      if (image == null || !mounted) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() => _imageBytes = bytes);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not select project photo: $error')),
      );
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Portfolio Project'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ProjectInput(
                controller: _titleController,
                label: 'Project title',
              ),
              _ProjectInput(
                controller: _clientController,
                label: 'Client / site',
              ),
              _ProjectInput(controller: _categoryController, label: 'Category'),
              _ProjectInput(
                controller: _descriptionController,
                label: 'Description',
                maxLines: 3,
              ),
              OutlinedButton.icon(
                onPressed: _isPickingImage ? null : _pickPhoto,
                icon: _isPickingImage
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _imageBytes == null
                            ? Icons.add_a_photo_outlined
                            : Icons.edit_outlined,
                      ),
                label: Text(
                  _isPickingImage
                      ? 'Selecting photo...'
                      : _imageBytes == null
                      ? 'Add Project Photo (optional)'
                      : 'Change Project Photo',
                ),
              ),
              if (_imageBytes != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _imageBytes!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add Project')),
      ],
    );
  }
}

// Reusable text field used in the project form.
class _ProjectInput extends StatelessWidget {
  const _ProjectInput({
    required this.controller,
    required this.label,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Enter $label.' : null,
      ),
    );
  }
}
