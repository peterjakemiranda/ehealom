import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/app_scaffold.dart';

class ProfileView extends StatefulWidget {
  static const routeName = '/profile';

  const ProfileView({Key? key}) : super(key: key);

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ageController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _departmentController = TextEditingController();
  final _courseController = TextEditingController();
  final _majorController = TextEditingController();
  final _yearLevelController = TextEditingController();
  final _academicRankController = TextEditingController();
  bool _isLoading = false;
  bool _changePassword = false;
  String _selectedSex = 'male';
  String _selectedMaritalStatus = 'single';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  void _loadUserData() {
    final user = context.read<AuthController>().user;
    debugPrint('Loading user data in ProfileView: $user');
    
    if (user != null && user['user'] != null) {
      final userData = user['user'];
      setState(() {
        _nameController.text = userData['name'] ?? '';
        _emailController.text = userData['email'] ?? '';
        _usernameController.text = userData['username'] ?? '';
        _ageController.text = userData['age']?.toString() ?? '';
        _studentIdController.text = userData['student_id'] ?? '';
        _departmentController.text = userData['department'] ?? '';
        _courseController.text = userData['course'] ?? '';
        _majorController.text = userData['major'] ?? '';
        _yearLevelController.text = userData['year_level']?.toString() ?? '';
        _academicRankController.text = userData['academic_rank'] ?? '';
        _selectedSex = userData['sex'] ?? 'male';
        _selectedMaritalStatus = userData['marital_status'] ?? 'single';
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthController>().user;
    debugPrint('ProfileView - didChangeDependencies - User data: $user');
    
    if (user != null) {
      // Don't use setState here since we're in didChangeDependencies
      _nameController.text = user['name'] ?? '';
      _emailController.text = user['email'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    _studentIdController.dispose();
    _departmentController.dispose();
    _courseController.dispose();
    _majorController.dispose();
    _yearLevelController.dispose();
    _academicRankController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await context.read<AuthController>().updateProfile(
        name: _nameController.text,
        email: _emailController.text,
        username: _usernameController.text,
        currentPassword: _changePassword ? _currentPasswordController.text : null,
        newPassword: _changePassword ? _newPasswordController.text : null,
        newPasswordConfirmation: _changePassword ? _confirmPasswordController.text : null,
        age: int.tryParse(_ageController.text),
        studentId: _studentIdController.text,
        department: _departmentController.text,
        course: _courseController.text,
        major: _majorController.text,
        yearLevel: _yearLevelController.text,
        academicRank: _academicRankController.text,
        sex: _selectedSex,
        maritalStatus: _selectedMaritalStatus,
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );

      if (_changePassword) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        setState(() => _changePassword = false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch for user changes
    final user = context.watch<AuthController>().user;
    debugPrint('ProfileView build - User data: $user');

    // Update fields when user data changes
    if (user != null && user['user'] != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_nameController.text != user['user']['name'] || 
            _emailController.text != user['user']['email']) {
          setState(() {
            _nameController.text = user['user']['name'] ?? '';
            _emailController.text = user['user']['email'] ?? '';
          });
        }
      });
    }

    return AppScaffold(
      title: const Text('My Account'),
      currentIndex: -1,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter your age';
                  if (int.tryParse(value!) == null) return 'Please enter a valid age';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Sex',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                value: _selectedSex,
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (value) => setState(() => _selectedSex = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Marital Status',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.family_restroom),
                ),
                value: _selectedMaritalStatus,
                items: const [
                  DropdownMenuItem(value: 'single', child: Text('Single')),
                  DropdownMenuItem(value: 'married', child: Text('Married')),
                  DropdownMenuItem(value: 'divorced', child: Text('Divorced')),
                  DropdownMenuItem(value: 'widowed', child: Text('Widowed')),
                ],
                onChanged: (value) => setState(() => _selectedMaritalStatus = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _studentIdController,
                decoration: const InputDecoration(
                  labelText: 'Student ID',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _yearLevelController,
                decoration: const InputDecoration(
                  labelText: 'Year Level',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _courseController,
                decoration: const InputDecoration(
                  labelText: 'Course',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _majorController,
                decoration: const InputDecoration(
                  labelText: 'Major',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.subject),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _academicRankController,
                decoration: const InputDecoration(
                  labelText: 'Academic Rank',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              CheckboxListTile(
                title: const Text('Change Password'),
                value: _changePassword,
                onChanged: (bool? value) {
                  setState(() => _changePassword = value ?? false);
                },
              ),
              if (_changePassword) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _currentPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (_changePassword && (value == null || value.isEmpty)) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (_changePassword) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a new password';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (_changePassword) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your new password';
                      }
                      if (value != _newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleUpdate,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Update Profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 