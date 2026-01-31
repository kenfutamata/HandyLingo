import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic>? userRow;
  const EditProfilePage({super.key, required this.userRow});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstCtrl;
  late TextEditingController _lastCtrl;
  late TextEditingController _userCtrl;
  late TextEditingController _emailCtrl;

  File? _pickedImage;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _firstCtrl = TextEditingController(
      text: widget.userRow?['first_name'] ?? '',
    );
    _lastCtrl = TextEditingController(text: widget.userRow?['last_name'] ?? '');
    _userCtrl = TextEditingController(text: widget.userRow?['user_name'] ?? '');
    _emailCtrl = TextEditingController(text: widget.userRow?['email'] ?? '');

    // If the parent didn't provide a userRow, fetch current user data from Supabase
    if (widget.userRow == null) {
      _fetchProfileFromSupabase();
    }
  }

  Future<void> _fetchProfileFromSupabase() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      final row = await supabase
          .from('users')
          .select(
            'first_name,last_name,user_name,email',
          )
          .eq('id', userId)
          .maybeSingle();
      if (row != null) {
        if (mounted) {
          setState(() {
            _firstCtrl.text = row['first_name'] ?? '';
            _lastCtrl.text = row['last_name'] ?? '';
            _userCtrl.text = row['user_name'] ?? '';
            _emailCtrl.text = row['email'] ?? '';
            widget.userRow?.addAll(row);
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _userCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _pickedImage = File(file.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm'),
        content: const Text('Save changes to your profile?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('No authenticated user');

      final updateRow = {
        'first_name': _firstCtrl.text.trim(),
        'last_name': _lastCtrl.text.trim(),
        'user_name': _userCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        // 'avatar_gender': widget.userRow?['avatar_gender'] ?? 'Male',
      };

      // Try to upload avatar to storage if picked
      if (_pickedImage != null) {
        // upload to bucket 'avatars' with path userId.jpg
        try {
          final bytes = await _pickedImage!.readAsBytes();
          // upload the binary to Supabase storage bucket 'avatars'
          await supabase.storage
              .from('avatars')
              .uploadBinary('$userId.jpg', bytes);
          final publicUrl = supabase.storage
              .from('avatars')
              .getPublicUrl('$userId.jpg');
          updateRow['avatar_url'] = publicUrl;
        } catch (e) {
          // Non-fatal: continue without avatar
        }
      }

      await supabase.from('users').update(updateRow).eq('id', userId);
      // ignore res details; we just show success/fail
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated')));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save profile: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFF33C7E6),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.white,
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!)
                          : (widget.userRow?['avatar_url'] != null
                                ? NetworkImage(widget.userRow!['avatar_url'])
                                      as ImageProvider
                                : null),
                      child:
                          widget.userRow?['avatar_url'] == null &&
                              _pickedImage == null
                          ? Icon(
                              (widget.userRow?['avatar_gender'] ?? 'Male') ==
                                      'Female'
                                  ? Icons.female
                                  : Icons.male,
                              size: 48,
                              color: Colors.black54,
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: InkWell(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white,
                          child: const Icon(Icons.edit, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              const SizedBox(height: 20),
              TextFormField(
                controller: _firstCtrl,
                decoration: const InputDecoration(labelText: 'First name'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastCtrl,
                decoration: const InputDecoration(labelText: 'Last name'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _userCtrl,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) =>
                    v == null || !v.contains('@') ? 'Invalid email' : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF33C7E6),
                        foregroundColor: Colors.white,
                      ),
                      child: _saving
                          ? const CircularProgressIndicator()
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
