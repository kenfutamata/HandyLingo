import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'edit_profile.dart';
import 'user_guide.dart';
import 'help_pages.dart';
import 'start_using.dart';
import '../main.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  Map<String, dynamic>? _userRow;
  bool _loading = true;
  bool _emailNotif = true;
  String _textSize = 'Medium';
  String _primarySL = 'Filipino';
  bool _whiteMode = true;

  String _voice = 'Male';
  double _voiceSpeed = 1.0;

  String _avatarGender = 'Male';
  double _signingSpeed = 1.0;
  bool _loop = false;

  bool _soundOn = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadLocalPrefs();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('No authenticated user');

      final row = await supabase
          .from('users')
          .select(
            'id, first_name, last_name, user_name, email, role, avatar_url, avatar_gender, preferences',
          )
          .eq('id', userId)
          .maybeSingle();
      setState(() {
        _userRow = row;
        // If server-side preferences exist, apply them to local UI state
        try {
          final prefs = row?['preferences'] as Map<String, dynamic>?;
          if (prefs != null) {
            _emailNotif = prefs['email_notif'] ?? _emailNotif;
            _textSize = prefs['text_size'] ?? _textSize;
            _primarySL = prefs['primary_sl'] ?? _primarySL;
            _whiteMode = prefs['white_mode'] ?? _whiteMode;
            _voice = prefs['voice'] ?? _voice;
            _voiceSpeed = (prefs['voice_speed'] != null)
                ? (prefs['voice_speed'] + 0.0)
                : _voiceSpeed;
            _avatarGender = prefs['avatar_gender'] ?? _avatarGender;
            _signingSpeed = (prefs['signing_speed'] != null)
                ? (prefs['signing_speed'] + 0.0)
                : _signingSpeed;
            _loop = prefs['sign_loop'] ?? _loop;
          }
        } catch (_) {}
      });
      // Apply theme provider if needed
      try {
        themeIsLight.value = _whiteMode;
      } catch (_) {}
    } catch (e) {
      // ignore and show minimal UI
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadLocalPrefs() async {
    final sp = await SharedPreferences.getInstance();
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

  Future<void> _saveLocalPrefs() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('email_notif', _emailNotif);
    await sp.setString('text_size', _textSize);
    await sp.setString('primary_sl', _primarySL);
    await sp.setBool('white_mode', _whiteMode);
    // Immediately update the app theme via global notifier (best-effort)
    try {
      themeIsLight.value = _whiteMode;
    } catch (_) {}

    await sp.setString('voice', _voice);
    await sp.setDouble('voice_speed', _voiceSpeed);

    await sp.setString('avatar_gender', _avatarGender);
    await sp.setDouble('signing_speed', _signingSpeed);
    await sp.setBool('sign_loop', _loop);

    // attempt to persist into Supabase users table under 'preferences' JSON column
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
      }
    } catch (e) {
      // ignore; preference save failure is not fatal
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
    if (!mounted) return;
    if (res == true) {
      _loadProfile();
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  Widget build(BuildContext context) {
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
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _soundOn ? Icons.volume_up : Icons.volume_off,
              color: Colors.black87,
            ),
            onPressed: () => setState(() => _soundOn = !_soundOn),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Image.asset(
              'assets/images/downloadremovebgpreview_2.png',
              width: 22,
            ),
          ),
        ],
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
                              _userRow?['email'] ?? '',
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

                  // Edit Profile button
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
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          SwitchListTile(
                            value: _emailNotif,
                            title: const Text('Email Notifications'),
                            onChanged: (v) => setState(() => _emailNotif = v),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Text Size:',
                                  style: GoogleFonts.inter(fontSize: 16),
                                ),
                              ),
                              DropdownButton<String>(
                                value: _textSize,
                                style: GoogleFonts.inter(color: Colors.black87),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Small',
                                    child: Text('Small'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Medium',
                                    child: Text('Medium'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Large',
                                    child: Text('Large'),
                                  ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _textSize = v ?? 'Medium'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Primary Sign Language:',
                                  style: GoogleFonts.inter(fontSize: 16),
                                ),
                              ),
                              DropdownButton<String>(
                                value: _primarySL,
                                style: GoogleFonts.inter(color: Colors.black87),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Filipino',
                                    child: Text('Filipino'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'International',
                                    child: Text('International'),
                                  ),
                                ],
                                onChanged: (v) => setState(
                                  () => _primarySL = v ?? 'Filipino',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SwitchListTile(
                            value: _whiteMode,
                            title: Text(
                              'White Mode (on) / Dark Mode (off)',
                              style: GoogleFonts.inter(),
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
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'Audio',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Voice:',
                                  style: GoogleFonts.inter(fontSize: 16),
                                ),
                              ),
                              DropdownButton<String>(
                                value: _voice,
                                style: GoogleFonts.inter(color: Colors.black87),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Male',
                                    child: Text('Male'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Female',
                                    child: Text('Female'),
                                  ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _voice = v ?? 'Male'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Speed:',
                                  style: GoogleFonts.inter(fontSize: 16),
                                ),
                              ),
                              DropdownButton<double>(
                                value: _voiceSpeed,
                                style: GoogleFonts.inter(color: Colors.black87),
                                items: const [
                                  DropdownMenuItem(
                                    value: 0.25,
                                    child: Text('0.25'),
                                  ),
                                  DropdownMenuItem(
                                    value: 0.5,
                                    child: Text('0.50'),
                                  ),
                                  DropdownMenuItem(
                                    value: 0.75,
                                    child: Text('0.75'),
                                  ),
                                  DropdownMenuItem(
                                    value: 1.0,
                                    child: Text('1.00'),
                                  ),
                                  DropdownMenuItem(
                                    value: 1.25,
                                    child: Text('1.25'),
                                  ),
                                  DropdownMenuItem(
                                    value: 1.5,
                                    child: Text('1.50'),
                                  ),
                                  DropdownMenuItem(
                                    value: 1.75,
                                    child: Text('1.75'),
                                  ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _voiceSpeed = v ?? 1.0),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'Sign Language',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Avatar:',
                                  style: GoogleFonts.inter(fontSize: 16),
                                ),
                              ),
                              DropdownButton<String>(
                                value: _avatarGender,
                                style: GoogleFonts.inter(color: Colors.black87),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Male',
                                    child: Text('Male'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Female',
                                    child: Text('Female'),
                                  ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _avatarGender = v ?? 'Male'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Signing Speed:',
                                  style: GoogleFonts.inter(fontSize: 16),
                                ),
                              ),
                              DropdownButton<double>(
                                value: _signingSpeed,
                                style: GoogleFonts.inter(color: Colors.black87),
                                items: const [
                                  DropdownMenuItem(
                                    value: 0.25,
                                    child: Text('0.25'),
                                  ),
                                  DropdownMenuItem(
                                    value: 0.5,
                                    child: Text('0.50'),
                                  ),
                                  DropdownMenuItem(
                                    value: 0.75,
                                    child: Text('0.75'),
                                  ),
                                  DropdownMenuItem(
                                    value: 1.0,
                                    child: Text('1.00'),
                                  ),
                                  DropdownMenuItem(
                                    value: 1.25,
                                    child: Text('1.25'),
                                  ),
                                  DropdownMenuItem(
                                    value: 1.5,
                                    child: Text('1.50'),
                                  ),
                                  DropdownMenuItem(
                                    value: 1.75,
                                    child: Text('1.75'),
                                  ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _signingSpeed = v ?? 1.0),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SwitchListTile(
                            value: _loop,
                            title: const Text('Loop'),
                            onChanged: (v) => setState(() => _loop = v),
                          ),
                        ],
                      ),
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
                      title: const Text('2.5.1 (135)'),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const StartUsingPage())),
        backgroundColor: Colors.white,
        child: const Icon(Icons.circle, color: Colors.black, size: 36),
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
                  onTap: () {}, // already on Account page
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
