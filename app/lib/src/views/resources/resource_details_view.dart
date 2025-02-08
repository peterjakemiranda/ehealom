import 'package:flutter/material.dart';
import '../../models/resource.dart';
import '../../services/resource_service.dart';
import '../../widgets/app_scaffold.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class ResourceDetailsView extends StatefulWidget {
  static const routeName = '/resources/details';

  final String resourceId;

  const ResourceDetailsView({
    required Key key,
    required this.resourceId,
  }) : super(key: key);

  @override
  State<ResourceDetailsView> createState() => _ResourceDetailsViewState();
}

class _ResourceDetailsViewState extends State<ResourceDetailsView> {
  final _resourceService = ResourceService();
  Resource? _resource;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadResource();
  }

  @override
  void didUpdateWidget(ResourceDetailsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resourceId != widget.resourceId) {
      _loadResource();
    }
  }

  Future<void> _loadResource() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
      _resource = null;
    });

    try {
      debugPrint('Loading resource with ID: ${widget.resourceId}');

      final result = await _resourceService.fetchResource(widget.resourceId);
      
      if (!mounted) return;

      debugPrint('Resource API Response: ${jsonEncode(result)}');
      
      final resourceData = result['data'] as Map<String, dynamic>?;
      if (resourceData != null) {
        setState(() {
          _resource = Resource.fromJson(resourceData);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Resource not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading resource: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: const Text('Resource Details'),
      currentIndex: 2,
      onNavigationItemSelected: (index) {
        if (index == 2) {
          Navigator.of(context).pushReplacementNamed('/resources');
        } else {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/appointments');
              break;
          }
        }
      },
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_resource!.imageUrl != null)
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            _resource!.imageUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: _getResourceColor(
                                _resource!.categories.isNotEmpty 
                                    ? _resource!.categories.first['title'].toLowerCase()
                                    : 'general'
                              ),
                              child: Icon(
                                _getResourceIcon(
                                  _resource!.categories.isNotEmpty 
                                      ? _resource!.categories.first['title'].toLowerCase()
                                      : 'general'
                                ),
                                size: 48,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _resource!.title,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                ..._resource!.categories.map((category) => Chip(
                                  label: Text(category['title']),
                                  backgroundColor: _getResourceColor(category['title'].toLowerCase()),
                                )),
                                if (_resource!.fileUrl != null)
                                  ActionChip(
                                    avatar: const Icon(Icons.download),
                                    label: const Text('Download'),
                                    onPressed: () => _downloadFile(_resource!.fileUrl!),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _resource!.content,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Future<void> _downloadFile(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open file')),
        );
      }
    }
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