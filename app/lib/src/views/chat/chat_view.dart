import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/chat_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../controllers/auth_controller.dart';

class ChatView extends StatefulWidget {
  static const routeName = '/chat';

  const ChatView({Key? key}) : super(key: key);

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _chatService = ChatService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMorePages = true;
  bool _hasCheckedUsername = false;

  @override
  void initState() {
    super.initState();
    _setupScrollListener();
    // Schedule the loading after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages();
      // Refresh user data when chat is loaded
      _refreshUserData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasCheckedUsername) {
      // Schedule the username check after the widget is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkUsername();
      });
      _hasCheckedUsername = true;
    }
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      // Load more when scrolling to the top (for older messages)
      if (_scrollController.position.pixels == _scrollController.position.minScrollExtent && 
          !_isLoadingMore &&
          _hasMorePages) {
        _loadMoreMessages();
      }
    });
  }

  Future<void> _refreshUserData() async {
    try {
      final authController = Provider.of<AuthController>(context, listen: false);
      // Call the public refreshUserData method
      await authController.refreshUserData();
      print('User data refreshed from API');
    } catch (e) {
      print('Error refreshing user data: $e');
    }
  }

  Future<void> _checkUsername() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    
    try {
      // Always refresh user data before checking username
      await _refreshUserData();
      
      // Get the current user data after refresh
      final user = authController.user;
      print('User data after refresh: $user');
      
      // Check if username exists and is not empty
      final username = user?['user']['username'];
      final name = user?['user']['name'];
      
      print('Username: $username, Name: $name');
      
      // Consider both username and name fields
      final hasValidUsername = username != null && username.toString().trim().isNotEmpty;
      final hasValidName = name != null && name.toString().trim().isNotEmpty;
      
      print('Has valid username: $hasValidUsername, Has valid name: $hasValidName');
      
      // Only show dialog if both username and name are missing or empty
      if (!hasValidUsername && !hasValidName && mounted) {
        print('Showing username dialog');
        // Keep showing dialog until user sets a username
        bool usernameSet = false;
        while (!usernameSet && mounted) {
          final newUsername = await _showUsernameDialog();
          if (newUsername != null && newUsername.trim().isNotEmpty) {
            try {
              print('Updating profile with username: $newUsername');
              
              // Debug what's being sent to the API
              final data = {
                'username': newUsername,
              };
              print('Sending data to API: $data');
              
              await authController.updateProfile(
                username: newUsername,
              );
              
              // Refresh user data again to confirm the update
              await _refreshUserData();
              
              // Check if the update was successful
              print('Update completed, checking user data again');
              print('Updated user data: ${authController.user}');
              
              // Verify the username was actually set
              final updatedUsername = authController.user?['username'];
              if (updatedUsername != null && updatedUsername.toString().trim().isNotEmpty) {
                usernameSet = true;
                print('Username set successfully: $updatedUsername');
              } else {
                print('Username not set properly, will try again');
              }
            } catch (e) {
              print('Error setting username: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to set username: $e'),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            }
          } else {
            // User pressed back or closed dialog, navigate back
            if (mounted) {
              Navigator.of(context).pop();
              break;
            }
          }
        }
      } else {
        print('Username already set, skipping dialog');
      }
    } catch (e) {
      print('Error checking username: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to check username: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<String?> _showUsernameDialog() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Prevent back button from closing dialog
        child: _UsernameDialog(),
      ),
    );
  }

  Future<void> _loadMessages() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final response = await _chatService.getMessages(page: 1);
      setState(() {
        // Since messages now come in descending order (newest first),
        // we need to reverse them to display oldest at top, newest at bottom
        final messages = List<Map<String, dynamic>>.from(response['data'] ?? []);
        _messages = messages.reversed.toList();
        _currentPage = 1;
        _hasMorePages = response['next_page_url'] != null;
      });
      // Scroll to bottom after loading initial messages
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load messages: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final response = await _chatService.getMessages(page: _currentPage + 1);
      final newMessages = List<Map<String, dynamic>>.from(response['data'] ?? []);
      
      if (mounted) {
        setState(() {
          // Since messages come in descending order (newest first),
          // we need to reverse them and add at the beginning
          _messages.insertAll(0, newMessages.reversed.toList());
          _currentPage++;
          _hasMorePages = response['next_page_url'] != null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load more messages: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text;
    _messageController.clear();

    try {
      final newMessage = await _chatService.sendMessage(message);
      
      if (mounted) {
        setState(() {
          // Add new message to the end of the list
          _messages.add(newMessage);
        });
        
        // Scroll to bottom to show the new message
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the auth controller to check user role
    final authController = Provider.of<AuthController>(context, listen: false);
    // Fix the role checking logic
    final roles = authController.user?['user']?['roles'] as List<dynamic>?;
    final isCounselor = roles?.any((role) => role['name'] == 'counselor') ?? false;
    
    // Chat is index 2 for counselors, index 3 for regular users
    final chatIndex = isCounselor ? 2 : 3;
    
    return AppScaffold(
      title: const Text('Group Chat'),
      currentIndex: chatIndex,
      body: Column(
        children: [
          if (_isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          Expanded(
            child: _isLoading && _messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    reverse: false, // Show oldest messages at top, newest at bottom
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildChatBubble(message);
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> message) {
    final authController = Provider.of<AuthController>(context, listen: false);
    final currentUserId = authController.user?['user']['id'];
    final isOwnMessage = message['user']['id'] == currentUserId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isOwnMessage) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Text(
                (message['user']['username'] ?? message['user']['name']).substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isOwnMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isOwnMessage) ...[
                  Text(
                    message['user']['username'] ?? message['user']['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isOwnMessage 
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message['message'],
                        style: TextStyle(
                          fontSize: 16,
                          color: isOwnMessage ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(DateTime.parse(message['created_at'])),
                        style: TextStyle(
                          fontSize: 12,
                          color: isOwnMessage 
                              ? Colors.white.withOpacity(0.8)
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOwnMessage) ...[
                  const SizedBox(height: 4),
                  Text(
                    message['user']['username'] ?? message['user']['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isOwnMessage) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Text(
                (message['user']['username'] ?? message['user']['name']).substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AliasDialog extends StatefulWidget {
  @override
  State<_AliasDialog> createState() => _AliasDialogState();
}

class _AliasDialogState extends State<_AliasDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Username'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Choose an alias to maintain your privacy in the group chat.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Chat Name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              Navigator.of(context).pop(_controller.text.trim());
            }
          },
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

class _UsernameDialog extends StatefulWidget {
  @override
  State<_UsernameDialog> createState() => _UsernameDialogState();
}

class _UsernameDialogState extends State<_UsernameDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose Your Chat Name'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose a username for the group chat. This will be visible to other users.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Username is required';
                }
                if (value.length < 3) {
                  return 'Username must be at least 3 characters';
                }
                return null;
              },
              autofocus: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(_controller.text.trim());
            }
          },
          child: const Text('Continue'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

String _formatTimestamp(DateTime timestamp) {
  // Convert to Manila timezone (UTC+8)
  final manilaTime = timestamp.toUtc().add(const Duration(hours: 8));
  
  // Format hour in 12-hour format with AM/PM
  final hour = manilaTime.hour > 12 ? manilaTime.hour - 12 : (manilaTime.hour == 0 ? 12 : manilaTime.hour);
  final minute = manilaTime.minute.toString().padLeft(2, '0');
  final period = manilaTime.hour >= 12 ? 'PM' : 'AM';
  
  return '$hour:$minute $period';
} 