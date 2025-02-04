import 'package:flutter/material.dart';
import '../../models/resource.dart';
import '../../services/resource_service.dart';
import '../../widgets/app_scaffold.dart';
import 'resource_details_view.dart';

class ResourceListView extends StatefulWidget {
  static const routeName = '/resources';

  const ResourceListView({Key? key}) : super(key: key);

  @override
  State<ResourceListView> createState() => _ResourceListViewState();
}

class _ResourceListViewState extends State<ResourceListView> {
  final _resourceService = ResourceService();
  final _searchController = TextEditingController();
  
  List<Resource> _resources = [];
  bool _isLoading = false;
  String? _selectedCategory;
  Map<String, dynamic> _meta = {};

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    setState(() => _isLoading = true);
    try {
      final result = await _resourceService.fetchResources(
        category: _selectedCategory,
        perPage: 20,
      );
      setState(() {
        _resources = result['resources'];
        _meta = result['meta'];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load resources: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Resources',
      currentIndex: 2,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search resources...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadResources();
                        },
                      )
                    : null,
              ),
              onSubmitted: (_) => _loadResources(),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildCategoryChip(null, 'All'),
                _buildCategoryChip('academic', 'Academic'),
                _buildCategoryChip('mental-health', 'Mental Health'),
                _buildCategoryChip('career', 'Career'),
                _buildCategoryChip('general', 'General'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _resources.isEmpty
                    ? const Center(child: Text('No resources found'))
                    : ListView.builder(
                        itemCount: _resources.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final resource = _resources[index];
                          return _ResourceCard(
                            resource: resource,
                            onTap: () => _showResourceDetails(resource),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String? category, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: _selectedCategory == category,
        onSelected: (selected) {
          setState(() => _selectedCategory = selected ? category : null);
          _loadResources();
        },
      ),
    );
  }

  void _showResourceDetails(Resource resource) {
    Navigator.pushNamed(
      context,
      ResourceDetailsView.routeName,
      arguments: resource.uuid,
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final Resource resource;
  final VoidCallback onTap;

  const _ResourceCard({
    Key? key,
    required this.resource,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resource.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                resource.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Chip(
                    label: Text(resource.category),
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  ),
                  if (resource.fileUrl != null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.attachment, size: 16),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 