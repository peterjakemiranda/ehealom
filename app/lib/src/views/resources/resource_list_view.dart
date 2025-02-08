import 'package:flutter/material.dart';
import '../../models/resource.dart';
import '../../services/resource_service.dart';
import '../../widgets/app_scaffold.dart';
import 'resource_details_view.dart';
import 'dart:convert';

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
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  String? _selectedCategory;
  Map<String, dynamic> _meta = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadResources();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _resourceService.fetchCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Future<void> _loadResources({bool refresh = false}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final result = await _resourceService.fetchResources(
        category: _selectedCategory,
        search: _searchController.text.trim(),
      );

      setState(() {
        _resources = (result['data'] as List)
            .map((json) => Resource.fromJson(json))
            .toList();
        _meta = result['meta'] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading resources: $e')),
        );
      }
    }
  }

  void _onCategorySelected(String? category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadResources(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: const Text('Resources'),
      currentIndex: 2,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadResources,
              child: Column(
                children: [
                  _buildSearchField(),
                  _buildCategoryChips(),
                  Expanded(
                    child: _resources.isEmpty
                        ? const Center(child: Text('No resources found'))
                        : ListView.builder(
                            itemCount: _resources.length,
                            padding: const EdgeInsets.all(16),
                            itemBuilder: (context, index) {
                              final resource = _resources[index];
                              return _buildResourceCard(resource);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
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
                    _loadResources(refresh: true);
                  },
                )
              : null,
        ),
        onChanged: (value) {
          if (value.isEmpty) {
            _loadResources(refresh: true);
          }
        },
        onSubmitted: (_) => _loadResources(refresh: true),
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
          _onCategorySelected(selected ? category : null);
        },
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildCategoryChip(null, 'All'),
          ..._categories.map((category) => _buildCategoryChip(
            category['uuid'],
            category['title'],
          )),
        ],
      ),
    );
  }

  Widget _buildResourceCard(Resource resource) {
    final categoryTitle = resource.categories.isNotEmpty 
        ? resource.categories.first['title'].toLowerCase()
        : 'general';

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () {
          debugPrint('Navigating to resource: ${resource.uuid}');
          Navigator.pushNamed(
            context,
            ResourceDetailsView.routeName,
            arguments: resource.uuid,
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (resource.imageUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  resource.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: _getResourceColor(categoryTitle),
                    child: Icon(
                      _getResourceIcon(categoryTitle),
                      size: 32,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              )
            else
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: _getResourceColor(categoryTitle),
                  child: Icon(
                    _getResourceIcon(categoryTitle),
                    size: 32,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Chip(
                    label: Text(categoryTitle),
                    backgroundColor: _getResourceColor(categoryTitle),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    resource.content,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getResourceColor(String category) {
    switch (category.toLowerCase()) {
      case 'mental-health':
        return const Color(0xFFE8F3F1);
      case 'academic':
        return const Color(0xFFF8E8D4);
      case 'career':
        return const Color(0xFFF0F4FD);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  IconData _getResourceIcon(String category) {
    switch (category.toLowerCase()) {
      case 'mental-health':
        return Icons.psychology;
      case 'academic':
        return Icons.school;
      case 'career':
        return Icons.work;
      default:
        return Icons.article;
    }
  }
} 