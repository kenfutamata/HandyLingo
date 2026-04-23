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
          // Included profile_picture in the select query
          .select('first_name,last_name,user_name,email,profile_picture')
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
      };

      // Try to upload image to 'profile_picture' bucket if picked
      if (_pickedImage != null) {
        try {
          final fileName = '$userId.jpg';

          // Upload the file to Supabase storage bucket 'profile_picture'
          // upsert: true ensures it overrides the previous picture instead of failing
          await supabase.storage.from('profile_picture').upload(
                fileName,
                _pickedImage!,
                fileOptions: const FileOptions(upsert: true),
              );

          final publicUrl =
              supabase.storage.from('profile_picture').getPublicUrl(fileName);

          // Add a timestamp to bypass Flutter's aggressive image caching
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          updateRow['profile_picture'] = '$publicUrl?t=$timestamp';
        } catch (e) {
          // If the image fails to upload (e.g. Storage permissions issue), stop and show error
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image upload failed: $e'),
                backgroundColor: Colors.red,
              ),
            );
            setState(() => _saving = false);
          }
          return; // Abort the save process if image upload fails
        }
      }

      // Update the 'users' table with text fields and new image URL (if changed)
      await supabase.from('users').update(updateRow).eq('id', userId);

      // Update the local widget row so the previous screen updates too
      widget.userRow?.addAll(updateRow);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        child: SingleChildScrollView(
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
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _pickedImage != null
                            ? FileImage(_pickedImage!)
                            : (widget.userRow?['profile_picture'] != null
                                ? NetworkImage(widget.userRow!['profile_picture'])
                                    as ImageProvider
                                : null),
                        child: widget.userRow?['profile_picture'] == null &&
                                _pickedImage == null
                            ? const Icon(
                                Icons.person,
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
                            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                            child: const Icon(Icons.camera_alt, size: 18, color: Color(0xFF33C7E6)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
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
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF33C7E6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}