import 'package:flutter/material.dart';
import '../../models/resource.dart';
import '../../services/resource_service.dart';
import '../../widgets/app_scaffold.dart';
import 'package:url_launcher/url_launcher.dart';

class ResourceDetailsView extends StatefulWidget {
  static const routeName = '/resources/details';

  final String resourceId;

  const ResourceDetailsView({
    Key? key,
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

  Future<void> _loadResource() async {
    try {
      final result = await _resourceService.fetchResources(
        uuid: widget.resourceId,
      );
      
      debugPrint('Resource API Response: $result');
      
      if (result['resources'].isNotEmpty) {
        setState(() {
          _resource = result['resources'][0];
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
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Resource Details',
      currentIndex: 2,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _resource!.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Chip(
                            label: Text(_resource!.category),
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          ),
                          if (_resource!.fileUrl != null) ...[
                            const SizedBox(width: 8),
                            TextButton.icon(
                              icon: const Icon(Icons.download),
                              label: const Text('Download'),
                              onPressed: () => _downloadFile(_resource!.fileUrl!),
                            ),
                          ],
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
} 