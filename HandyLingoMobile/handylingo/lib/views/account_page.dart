import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'edit_profile.dart';
import 'user_guide.dart';
import 'faq_page.dart';
import 'feedback_page.dart';
import 'terms_page.dart';
import 'app_version_edit_page.dart';
import 'start_using.dart';

import '../main.dart'; // This is where the Supabase client and themeIsLight are initialized

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  Map<String, dynamic>? _userRow;
  bool _loading = true;

  // Local Preference State
  bool _emailNotif = true;
  String _textSize = 'Small';
  bool _whiteMode = true;
  bool _voiceEnabled = true;
  String _avatarGender = 'Male';

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _loading = true);
    await _loadLocalPrefs();
    await _loadProfile();
    setState(() => _loading = false);
  }

  Future<void> _loadProfile() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) return;

      final row = await supabase
          .from('users')
          // IMPORTANT: Added 'profile_picture' here so the app actually downloads it
          .select('id, first_name, last_name, user_name, email, role, profile_picture')
          .eq('id', userId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _userRow = row;
          try {
            final prefs = row?['preferences'] as Map<String, dynamic>?;
            if (prefs != null) {
              _emailNotif = prefs['email_notif'] ?? _emailNotif;
              _textSize = prefs['text_size'] ?? _textSize;
              _whiteMode = prefs['white_mode'] ?? _whiteMode;
              _voiceEnabled =
                  prefs['voice_enabled'] ??
                  (prefs['voice'] is String
                      ? (prefs['voice'] as String).toLowerCase() == 'male'
                      : _voiceEnabled);
              _avatarGender = prefs['avatar_gender'] ?? _avatarGender;
            }
          } catch (e) {
            print('ERROR parsing preferences: $e');
          }
        });

        try {
          themeIsLight.value = _whiteMode;
        } catch (_) {}
      }
    } catch (e) {
      print('ERROR loading profile: $e');
    }
  }

  Future<void> _loadLocalPrefs() async {
    final sp = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _emailNotif = sp.getBool('email_notif') ?? true;
        _textSize = sp.getString('text_size') ?? 'Small';
        _whiteMode = sp.getBool('white_mode') ?? true;
        _voiceEnabled =
            sp.getBool('voice_enabled') ??
            (sp.getString('voice')?.toLowerCase() == 'female' ? false : true);
        _avatarGender = sp.getString('avatar_gender') ?? 'Male';
      });
    }
  }

  Future<void> _saveLocalPrefs() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('email_notif', _emailNotif);
    await sp.setString('text_size', _textSize);
    await sp.setBool('white_mode', _whiteMode);
    await sp.setBool('voice_enabled', _voiceEnabled);

    try {
      themeIsLight.value = _whiteMode;
    } catch (_) {}

    await sp.setString('avatar_gender', _avatarGender);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        await supabase
            .from('users')
            .update({
              'preferences': {
                'text_size': _textSize,
                'white_mode': _whiteMode,
                'voice_enabled': _voiceEnabled,
                'avatar_gender': _avatarGender,
              },
            })
            .eq('id', userId);
        await _loadProfile();
      }
    } catch (e) {
      print('Warning: Failed to persist preferences to server: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preferences saved')));
    }
  }

  void _goEditProfile() async {
    final res = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditProfilePage(userRow: _userRow)),
    );
    // When returning from edit profile (if saved), reload the updated profile_picture!
    if (res == true) _loadProfile(); 
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    final String authenticatedEmail =
        Supabase.instance.client.auth.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFEAF8FB),
        leading: IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.black87),
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const UserGuidePage())),
        ),
        title: Text(
          'HandyLingo',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ACCOUNT',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.grey.shade200, // Looks better when loading/empty
                        // Use profile_picture here
                        backgroundImage: _userRow?['profile_picture'] != null
                            ? NetworkImage(_userRow!['profile_picture'])
                            : null,
                        child: _userRow?['profile_picture'] == null
                            ? Icon(
                                (_userRow?['avatar_gender'] ?? _avatarGender) ==
                                        'Female'
                                    ? Icons.female
                                    : Icons.male,
                                size: 36,
                                color: Colors.black54,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_userRow?['first_name'] ?? ''} ${_userRow?['last_name'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _userRow?['user_name'] ?? '',
                              style: const TextStyle(color: Colors.black54),
                            ),
                            Text(
                              authenticatedEmail,
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _goEditProfile,
                        icon: const Icon(Icons.edit),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _goEditProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF33C7E6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Edit Profile'),
                    ),
                  ),

                  const SizedBox(height: 18),
                  const Text(
                    'Preferences',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text('Text Size:'),
                          trailing: DropdownButton<String>(
                            value: _textSize,
                            underline: const SizedBox(),
                            items: ['Small', 'Medium', 'Large']
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _textSize = v ?? 'Small'),
                          ),
                        ),
                        SwitchListTile(
                          value: _whiteMode,
                          title: const Text(
                            'White Mode (on) / Dark Mode (off)',
                          ),
                          onChanged: (v) {
                            setState(() => _whiteMode = v);
                            try {
                              themeIsLight.value = v;
                            } catch (_) {}
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'Audio',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          value: _voiceEnabled,
                          title: const Text('Voice'),
                          onChanged: (v) => setState(() => _voiceEnabled = v),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveLocalPrefs,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF33C7E6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Save Preferences'),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'Help',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text('Frequently asked questions'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const FaqPage()),
                          ),
                        ),
                        ListTile(
                          title: const Text('Give feedback'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const FeedbackPage(),
                            ),
                          ),
                        ),
                        ListTile(
                          title: const Text('User Guide'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const UserGuidePage(),
                            ),
                          ),
                        ),
                        ListTile(
                          title: const Text('Terms of use'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const TermsPage(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'App Version',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      title: const Text('1.0.0'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        final role = _userRow?['role'] as String? ?? 'user';
                        if (role != 'admin') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Only admins can change app version.',
                              ),
                            ),
                          );
                          return;
                        }
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AppVersionEditPage(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Log out'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            InkWell(
              onTap: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const StartUsingPage()),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SL',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.blue,
                    ),
                  ),
                  const Text(
                    'Switch',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Text(
              'HANDYLINGO',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            InkWell(
              onTap: () {},
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person, size: 22, color: Colors.blue),
                  const SizedBox(height: 4),
                  Text(
                    'Account',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}