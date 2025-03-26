import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';

class RegisterView extends StatefulWidget {
  static const routeName = '/register';

  const RegisterView({Key? key}) : super(key: key);

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ageController = TextEditingController();
  final _studentIdController = TextEditingController();
  String _selectedDepartment = '';
  final _courseController = TextEditingController();
  final _majorController = TextEditingController();
  final _yearLevelController = TextEditingController();
  final _academicRankController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedUserType = 'student';
  String _selectedSex = 'male';
  String _selectedMaritalStatus = 'single';

  // Base department options
  final List<Map<String, String>> _baseDepatments = [
    {'value': 'DCS', 'label': 'DCS – Department of Computer Studies'},
    {'value': 'DBM', 'label': 'DBM - Department of Business and Management'},
    {'value': 'DIT', 'label': 'DIT – Department of Industrial Technology'},
    {'value': 'DGTT', 'label': 'DGTT – Department of General Teacher Training'},
    {'value': 'CCJE', 'label': 'CCJE – College of Criminal Justice Education'},
  ];

  // School Admin option for personnel only
  final Map<String, String> _schoolAdminDept = 
    {'value': 'SA', 'label': 'School Admin'};

  List<Map<String, String>> get _departments {
    final depts = List<Map<String, String>>.from(_baseDepatments);
    if (_selectedUserType == 'personnel') {
      depts.add(_schoolAdminDept);
    }
    return depts;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    _studentIdController.dispose();
    _courseController.dispose();
    _majorController.dispose();
    _yearLevelController.dispose();
    _academicRankController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> userData = {
        'name': _nameController.text,
        'username': _usernameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'password_confirmation': _confirmPasswordController.text,
        'user_type': _selectedUserType,
        'age': int.parse(_ageController.text),
        'sex': _selectedSex,
        'marital_status': _selectedMaritalStatus,
      };

      // Add role-specific fields
      if (_selectedUserType == 'student') {
        userData.addAll({
          'student_id': _studentIdController.text,
          'year_level': _yearLevelController.text,
          'department': _selectedDepartment,
          'course': _courseController.text,
          'major': _majorController.text,
        });
      } else if (_selectedUserType == 'personnel') {
        userData.addAll({
          'academic_rank': _academicRankController.text,
          'department': _selectedDepartment,
        });
      }

      await context.read<AuthController>().register(userData);
      
      if (!mounted) return;
      
      // Navigate to home instead of showing login message
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e) {
      if (!mounted) return;
      
      // Extract only the message from the error
      String errorMsg = e.toString();
      if (errorMsg.contains('message":')) {
        errorMsg = errorMsg.split('message":')[1]
            .split('"')[1]
            .replaceAll(r'\', '');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildUserTypeSelector() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'User Type',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person_outline),
      ),
      value: _selectedUserType,
      items: const [
        DropdownMenuItem(value: 'student', child: Text('Student')),
        DropdownMenuItem(value: 'personnel', child: Text('Campus Personnel')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedUserType = value!;
          // Reset department selection when switching user type
          _selectedDepartment = '';
        });
      },
      validator: (value) => value == null ? 'Please select a user type' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                'Join our wellness community',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Please enter your name' : null,
                    ),
                    const SizedBox(height: 16),

                    // Username field
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Please enter a username' : null,
                    ),
                    const SizedBox(height: 16),

                    // Age field
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

                    // Sex dropdown
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

                    // Marital Status dropdown
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

                    // User Type selector
                    _buildUserTypeSelector(),

                    // Conditional fields based on user type
                    if (_selectedUserType == 'student') ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _studentIdController,
                        decoration: const InputDecoration(
                          labelText: 'Student ID',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your student ID';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _yearLevelController,
                        decoration: const InputDecoration(
                          labelText: 'Year Level',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.school),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your year level';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        isExpanded: true,
                        menuMaxHeight: 300,
                        value: _selectedDepartment.isEmpty ? null : _selectedDepartment,
                        items: _departments.map((department) {
                          return DropdownMenuItem(
                            value: department['value'],
                            child: Text(
                              department['label']!,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedDepartment = value!);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select your department';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _courseController,
                        decoration: const InputDecoration(
                          labelText: 'Course',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your course';
                          }
                          return null;
                        },
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
                    ] else if (_selectedUserType == 'personnel') ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _academicRankController,
                        decoration: const InputDecoration(
                          labelText: 'Academic Rank',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.work),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your academic rank';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        isExpanded: true,
                        menuMaxHeight: 300,
                        value: _selectedDepartment.isEmpty ? null : _selectedDepartment,
                        items: _departments.map((department) {
                          return DropdownMenuItem(
                            value: department['value'],
                            child: Text(
                              department['label']!,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedDepartment = value!);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select your department';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Please enter your email';
                        if (!value!.contains('@')) return 'Please enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password fields
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Please enter a password';
                        if (value!.length < 8) return 'Password must be at least 8 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Please confirm your password';
                        if (value != _passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Register button
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Register'),
                      ),
                    ),
                    
                    // Add Back to Login link
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Already have an account? Login'),
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