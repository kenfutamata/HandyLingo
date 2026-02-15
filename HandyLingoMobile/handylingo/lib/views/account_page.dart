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
  String _textSize = 'Medium';
  String _primarySL = 'Filipino';
  bool _whiteMode = true;
  String _voice = 'Male';
  double _voiceSpeed = 1.0;
  String _avatarGender = 'Male';
  double _signingSpeed = 1.0;
  bool _loop = false;

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
          .select('id, first_name, last_name, user_name, email, role')
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
              _primarySL = prefs['primary_sl'] ?? _primarySL;
              _whiteMode = prefs['white_mode'] ?? _whiteMode;
              _voice = prefs['voice'] ?? _voice;
              _voiceSpeed = (prefs['voice_speed'] is num)
                  ? (prefs['voice_speed'] as num).toDouble()
                  : _voiceSpeed;
              _avatarGender = prefs['avatar_gender'] ?? _avatarGender;
              _signingSpeed = (prefs['signing_speed'] is num)
                  ? (prefs['signing_speed'] as num).toDouble()
                  : _signingSpeed;
              _loop = prefs['sign_loop'] ?? _loop;
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
        _textSize = sp.getString('text_size') ?? 'Medium';
        _primarySL = sp.getString('primary_sl') ?? 'Filipino';
        _whiteMode = sp.getBool('white_mode') ?? true;
        _voice = sp.getString('voice') ?? 'Male';
        _voiceSpeed = sp.getDouble('voice_speed') ?? 1.0;
        _avatarGender = sp.getString('avatar_gender') ?? 'Male';
        _signingSpeed = sp.getDouble('signing_speed') ?? 1.0;
        _loop = sp.getBool('sign_loop') ?? false;
      });
    }
  }

  Future<void> _saveLocalPrefs() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('email_notif', _emailNotif);
    await sp.setString('text_size', _textSize);
    await sp.setString('primary_sl', _primarySL);
    await sp.setBool('white_mode', _whiteMode);

    try {
      themeIsLight.value = _whiteMode;
    } catch (_) {}

    await sp.setString('voice', _voice);
    await sp.setDouble('voice_speed', _voiceSpeed);
    await sp.setString('avatar_gender', _avatarGender);
    await sp.setDouble('signing_speed', _signingSpeed);
    await sp.setBool('sign_loop', _loop);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        await supabase
            .from('users')
            .update({
              'preferences': {
                'email_notif': _emailNotif,
                'text_size': _textSize,
                'primary_sl': _primarySL,
                'white_mode': _whiteMode,
                'voice': _voice,
                'voice_speed': _voiceSpeed,
                'avatar_gender': _avatarGender,
                'signing_speed': _signingSpeed,
                'sign_loop': _loop,
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
                        backgroundColor: Colors.white,
                        backgroundImage: _userRow?['avatar_url'] != null
                            ? NetworkImage(_userRow!['avatar_url'])
                            : null,
                        child: _userRow?['avatar_url'] == null
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
                        SwitchListTile(
                          value: _emailNotif,
                          title: const Text('Email Notifications'),
                          onChanged: (v) => setState(() => _emailNotif = v),
                        ),
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
                                setState(() => _textSize = v ?? 'Medium'),
                          ),
                        ),
                        ListTile(
                          title: const Text('Primary Sign Language:'),
                          trailing: DropdownButton<String>(
                            value: _primarySL,
                            underline: const SizedBox(),
                            items: ['International', 'Filipino']
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(
                              () => _primarySL = v ?? 'International',
                            ),
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
                        ListTile(
                          title: const Text('Voice:'),
                          trailing: DropdownButton<String>(
                            value: _voice,
                            underline: const SizedBox(),
                            items: ['Male', 'Female']
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _voice = v ?? 'Male'),
                          ),
                        ),
                        ListTile(
                          title: const Text('Speed:'),
                          trailing: DropdownButton<double>(
                            value: _voiceSpeed,
                            underline: const SizedBox(),
                            items: [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75]
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(d.toStringAsFixed(2)),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _voiceSpeed = v ?? 1.0),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'Sign Language',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text('Avatar:'),
                          trailing: DropdownButton<String>(
                            value: _avatarGender,
                            underline: const SizedBox(),
                            items: ['Male', 'Female']
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _avatarGender = v ?? 'Male'),
                          ),
                        ),
                        ListTile(
                          title: const Text('Signing Speed:'),
                          trailing: DropdownButton<double>(
                            value: _signingSpeed,
                            underline: const SizedBox(),
                            items: [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75]
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(d.toStringAsFixed(2)),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _signingSpeed = v ?? 1.0),
                          ),
                        ),
                        SwitchListTile(
                          value: _loop,
                          title: const Text('Loop'),
                          onChanged: (v) => setState(() => _loop = v),
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
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        child: SizedBox(
          height: 86,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const StartUsingPage()),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.view_in_ar, size: 22),
                      Text(
                        'SL',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                Text(
                  'HANDYLINGO',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
                InkWell(
                  onTap: () {},
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person, size: 22),
                      Text('Account', style: GoogleFonts.inter(fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
