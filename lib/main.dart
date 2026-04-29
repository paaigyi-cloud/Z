import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? true;
  final isEnglish = prefs.getBool('isEnglish') ?? false;
  runApp(ZVpnApp(initialDarkMode: isDarkMode, initialEnglish: isEnglish));
}

class ZVpnApp extends StatefulWidget {
  final bool initialDarkMode;
  final bool initialEnglish;
  const ZVpnApp({Key? key, required this.initialDarkMode, required this.initialEnglish}) : super(key: key);

  static _ZVpnAppState? of(BuildContext context) => context.findAncestorStateOfType<_ZVpnAppState>();

  @override
  State<ZVpnApp> createState() => _ZVpnAppState();
}

class _ZVpnAppState extends State<ZVpnApp> {
  late bool isDarkMode;
  late bool isEnglish;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.initialDarkMode;
    isEnglish = widget.initialEnglish;
  }

  void toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = value;
      prefs.setBool('isDarkMode', value);
    });
  }

  void toggleLanguage(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isEnglish = value;
      prefs.setBool('isEnglish', value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Z VPN',
      debugShowCheckedModeBanner: false,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF0F2F5),
        primaryColor: Colors.blueAccent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black87),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF161C2D),
        primaryColor: Colors.blueAccent,
      ),
      home: VpnHomeScreen(isEnglish: isEnglish),
    );
  }
}

// ==========================================
// Settings စာမျက်နှာ
// ==========================================
class SettingsScreen extends StatefulWidget {
  final bool isEnglish;
  const SettingsScreen({Key? key, required this.isEnglish}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<AppInfo> installedApps = [];
  List<String> bypassedApps = [];
  bool isLoadingApps = true;
  late FlutterV2ray flutterV2ray;

  @override
  void initState() {
    super.initState();
    flutterV2ray = FlutterV2ray(onStatusChanged: (status) {});
    _loadBypassedApps();
  }

  Future<void> _loadBypassedApps() async {
    final prefs = await SharedPreferences.getInstance();
    bypassedApps = prefs.getStringList('bypassed_apps') ?? [];
    
    // ဖုန်းထဲရှိ App များကို ဆွဲထုတ်ခြင်း
    try {
      var coreApps = await flutterV2ray.getAllApps();
      installedApps = coreApps;
    } catch (e) {
      //
    }
    setState(() {
      isLoadingApps = false;
    });
  }

  void _toggleBypassApp(String packageName, bool bypass) async {
    setState(() {
      if (bypass) {
        if (!bypassedApps.contains(packageName)) bypassedApps.add(packageName);
      } else {
        bypassedApps.remove(packageName);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('bypassed_apps', bypassedApps);
  }

  @override
  Widget build(BuildContext context) {
    final appState = ZVpnApp.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEnglish ? 'Settings' : 'ဆက်တင်များ', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          // Theme အလင်းအမှောင်
          ListTile(
            leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: Colors.blueAccent),
            title: Text(widget.isEnglish ? 'Dark Mode' : 'အမှောင်ပုံစံ'),
            trailing: Switch(
              value: appState?.isDarkMode ?? true,
              activeColor: Colors.blueAccent,
              onChanged: (val) => appState?.toggleTheme(val),
            ),
          ),
          const Divider(),
          // ဘာသာစကား (မြန်မာ / English)
          ListTile(
            leading: const Icon(Icons.language, color: Colors.blueAccent),
            title: Text(widget.isEnglish ? 'Language' : 'ဘာသာစကား'),
            subtitle: Text(widget.isEnglish ? 'English' : 'မြန်မာ'),
            trailing: Switch(
              value: appState?.isEnglish ?? false,
              activeColor: Colors.blueAccent,
              onChanged: (val) => appState?.toggleLanguage(val),
            ),
          ),
          const Divider(),
          // App များ ရှောင်ကွင်းရန် ခေါင်းစဉ်
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              widget.isEnglish ? 'Split Tunneling (Bypass Apps)' : 'App များကို ရှောင်ကွင်းမည် (Split Tunneling)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              widget.isEnglish 
                ? 'Selected apps will NOT use the VPN connection.' 
                : 'အောက်တွင် အမှန်ခြစ်ထားသော App များသည် VPN ကို အသုံးမပြုဘဲ ရိုးရိုးအင်တာနက်ဖြင့်သာ အလုပ်လုပ်ပါမည်။',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 10),
          // App စာရင်း ပြသခြင်း
          if (isLoadingApps)
            const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator()))
          else if (installedApps.isEmpty)
            Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text(widget.isEnglish ? 'No apps found.' : 'App များ ရှာမတွေ့ပါ။')))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: installedApps.length,
              itemBuilder: (context, index) {
                var app = installedApps[index];
                bool isBypassed = bypassedApps.contains(app.packageName);
                return ListTile(
                  leading: app.icon != null ? Image.memory(app.icon!, width: 40, height: 40) : const Icon(Icons.android),
                  title: Text(app.appName ?? app.packageName ?? 'Unknown App'),
                  trailing: Checkbox(
                    value: isBypassed,
                    activeColor: Colors.redAccent,
                    onChanged: (val) => _toggleBypassApp(app.packageName!, val ?? false),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ==========================================
// ပင်မ VPN စာမျက်နှာ
// ==========================================
class VpnHomeScreen extends StatefulWidget {
  final bool isEnglish;
  const VpnHomeScreen({Key? key, required this.isEnglish}) : super(key: key);

  @override
  State<VpnHomeScreen> createState() => _VpnHomeScreenState();
}

class _VpnHomeScreenState extends State<VpnHomeScreen> {
  int _bottomNavIndex = 0;
  bool isOutlineSelected = true; 
  bool isConnecting = false;
  bool isConnected = false;
  
  String _actualKey = ""; 
  String _savedOutlineKey = "";
  String _savedV2rayKey = "";

  final TextEditingController _keyController = TextEditingController();
  late FlutterV2ray flutterV2ray;

  @override
  void initState() {
    super.initState();
    _loadSavedKeys();
    flutterV2ray = FlutterV2ray(
      onStatusChanged: (status) {
        if (mounted) {
          setState(() {
            if (status.state == "CONNECTED") {
              isConnecting = false;
              isConnected = true;
            } else if (status.state == "DISCONNECTED") {
              isConnecting = false;
              isConnected = false;
            }
          });
        }
      },
    );
    _initV2Ray();
  }

  Future<void> _loadSavedKeys() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedOutlineKey = prefs.getString('outline_key') ?? "";
      _savedV2rayKey = prefs.getString('v2ray_key') ?? "";
      _updateDisplayKey();
    });
  }

  Future<void> _saveKeyToStorage(String key) async {
    final prefs = await SharedPreferences.getInstance();
    if (isOutlineSelected) {
      prefs.setString('outline_key', key);
      _savedOutlineKey = key;
    } else {
      prefs.setString('v2ray_key', key);
      _savedV2rayKey = key;
    }
  }

  void _updateDisplayKey() {
    String currentKey = isOutlineSelected ? _savedOutlineKey : _savedV2rayKey;
    _actualKey = currentKey;
    if (currentKey.isNotEmpty) {
      _keyController.text = _extractName(currentKey);
    } else {
      _keyController.text = "";
    }
  }

  Future<void> _initV2Ray() async {
    await flutterV2ray.initializeV2Ray();
  }

  String _extractName(String key) {
    try {
      if (key.contains("#")) {
        return Uri.decodeComponent(key.substring(key.indexOf("#") + 1));
      } else if (key.startsWith("vmess://")) {
        String base64Str = key.substring(8);
        base64Str = base64Str.padRight(base64Str.length + (4 - base64Str.length % 4) % 4, '=');
        String decoded = utf8.decode(base64Decode(base64Str));
        Map<String, dynamic> json = jsonDecode(decoded);
        if (json.containsKey("ps") && json["ps"].toString().isNotEmpty) {
          return json["ps"];
        }
      }
    } catch (e) {}
    
    if (key.startsWith("ss://")) return "Outline Server";
    if (key.startsWith("vless://")) return "V2Ray (VLESS) Server";
    if (key.startsWith("vmess://")) return "V2Ray (VMess) Server";
    if (key.startsWith("trojan://")) return "Trojan Server";
    return "Z-VPN Server";
  }

  void _toggleConnection() async {
    if (isConnected) {
      await flutterV2ray.stopV2Ray();
      return;
    }

    String keyToUse = _actualKey.isNotEmpty ? _actualKey : _keyController.text.trim();

    if (keyToUse.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isEnglish ? 'Please insert a key first!' : 'ကျေးဇူးပြု၍ Key ကို အရင်ထည့်ပါ!')),
      );
      return;
    }

    if (await flutterV2ray.requestPermission()) {
      setState(() {
        isConnecting = true;
      });

      try {
        String jsonConfig = keyToUse;
        String serverRemark = _keyController.text.trim();
        if (serverRemark.isEmpty) serverRemark = "Z-VPN Server";

        if (keyToUse.startsWith("ssconf://")) {
          throw Exception("ssconf error");
        }

        if (keyToUse.startsWith("vmess://") || keyToUse.startsWith("vless://") || keyToUse.startsWith("ss://") || keyToUse.startsWith("trojan://")) {
          var parsedNode = FlutterV2ray.parseFromURL(keyToUse);
          jsonConfig = parsedNode.getFullConfiguration();
        }

        // ရှောင်ကွင်းထားသော App များကို Storage မှ ပြန်ယူခြင်း
        final prefs = await SharedPreferences.getInstance();
        List<String> bypassedApps = prefs.getStringList('bypassed_apps') ?? [];

        await flutterV2ray.startV2Ray(
          remark: serverRemark,
          config: jsonConfig,
          bypassSubnets: ["0.0.0.0/8", "10.0.0.0/8", "100.64.0.0/10", "127.0.0.0/8", "169.254.0.0/16", "172.16.0.0/12", "192.0.0.0/24", "192.0.2.0/24", "192.168.0.0/16"],
          // ဤနေရာတွင် ရှောင်ကွင်းမည့် App များကို အင်ဂျင်သို့ ပေးပို့ပါသည်
          proxyOnly: false,
          bypassPackages: bypassedApps,
        );
      } catch (e) {
        setState(() {
          isConnecting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().contains("ssconf error") 
            ? (widget.isEnglish ? "Use ss:// Outline key instead of ssconf://" : "ss:// ဖြင့်စသော Key ကိုသာ ထည့်ပါ") 
            : (widget.isEnglish ? 'Invalid Key or Connection Failed' : 'Key မှားယွင်းနေပါသည် (သို့) ချိတ်ဆက်၍မရပါ'))),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isEnglish ? 'VPN Permission is required!' : 'VPN အသုံးပြုခွင့် ပေးရန် လိုအပ်ပါသည်!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final boxColor = isDark ? const Color(0xFF232B40) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;

    String connectionStatus = isConnected 
        ? (widget.isEnglish ? 'Connected' : 'ချိတ်ဆက်ထားပါသည်') 
        : (isConnecting 
            ? (widget.isEnglish ? 'Connecting...' : 'ချိတ်ဆက်နေသည်...') 
            : (widget.isEnglish ? 'Not Connected' : 'ချိတ်ဆက်ထားခြင်းမရှိပါ'));

    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.security, color: Colors.blueAccent),
        title: const Text(
          'Z VPN',
          style: TextStyle(
            color: Colors.amber,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            fontSize: 24,
            shadows: [
              Shadow(
                blurRadius: 10.0,
                color: Colors.amberAccent,
                offset: Offset(0, 0),
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: isDark ? Colors.grey : Colors.black54),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen(isEnglish: widget.isEnglish)),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: boxColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 1.5),
                boxShadow: isDark ? [] : [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5, spreadRadius: 1)],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isOutlineSelected = true;
                          _updateDisplayKey();
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isOutlineSelected ? Colors.blueAccent : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Outline Key', 
                          style: TextStyle(
                            color: isOutlineSelected ? Colors.white : (isDark ? Colors.grey : Colors.black54),
                            fontWeight: FontWeight.bold
                          )
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isOutlineSelected = false;
                          _updateDisplayKey();
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: !isOutlineSelected ? Colors.blueAccent : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'V2Ray Key',
                          style: TextStyle(
                            color: !isOutlineSelected ? Colors.white : (isDark ? Colors.grey : Colors.black54),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.vpn_key, size: 16, color: isDark ? Colors.grey : Colors.black54),
                const SizedBox(width: 8),
                Text(
                  isOutlineSelected ? 'ss:// (or) Outline Key' : 'vmess:// (or) vless://',
                  style: TextStyle(color: isDark ? Colors.grey : Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: boxColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1.0),
                boxShadow: isDark ? [] : [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5, spreadRadius: 1)],
              ),
              child: Column(
                children: [
                  Container(
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(9),
                        topRight: Radius.circular(9),
                      ),
                    ),
                  ),
                  TextField(
                    controller: _keyController,
                    maxLines: _actualKey.isNotEmpty ? 1 : 4,
                    style: TextStyle(
                      color: _actualKey.isNotEmpty ? (isDark ? Colors.amber : Colors.blue.shade800) : textColor, 
                      fontWeight: _actualKey.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                      fontSize: _actualKey.isNotEmpty ? 18 : 14,
                    ),
                    textAlign: _actualKey.isNotEmpty ? TextAlign.center : TextAlign.start,
                    onChanged: (value) {
                      String trimmed = value.trim();
                      if (trimmed.startsWith("ss://") || trimmed.startsWith("vmess://") || trimmed.startsWith("vless://") || trimmed.startsWith("trojan://")) {
                        setState(() {
                          _actualKey = trimmed;
                        });
                        _saveKeyToStorage(trimmed);
                        String name = _extractName(trimmed);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _keyController.text = name;
                          _keyController.selection = TextSelection.fromPosition(TextPosition(offset: name.length));
                        });
                      } else if (trimmed.isEmpty) {
                        setState(() {
                          _actualKey = "";
                        });
                        _saveKeyToStorage("");
                      }
                    },
                    decoration: InputDecoration(
                      hintText: widget.isEnglish ? 'Paste your Key here...' : 'ဒီနေရာမှာ Key ကို Paste ချပါ...',
                      hintStyle: TextStyle(color: hintColor, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      suffixIcon: _actualKey.isNotEmpty 
                        ? IconButton(
                            icon: Icon(Icons.cancel, color: isDark ? Colors.grey : Colors.black54),
                            onPressed: () {
                              setState(() {
                                _actualKey = "";
                                _saveKeyToStorage("");
                              });
                              _keyController.clear();
                            },
                          )
                        : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Text(
              connectionStatus,
              style: TextStyle(
                color: isConnected ? Colors.greenAccent.shade400 : (isConnecting ? Colors.amber : (isDark ? Colors.grey : Colors.black54)), 
                fontSize: 18,
                fontWeight: isConnected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: isConnecting ? null : _toggleConnection,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnected ? Colors.redAccent : (isConnecting ? Colors.grey : Colors.blueAccent),
                  boxShadow: [
                    BoxShadow(
                      color: isConnected ? Colors.redAccent.withOpacity(0.4) : (isConnecting ? Colors.transparent : Colors.blueAccent.withOpacity(0.4)),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isConnecting)
                      const CircularProgressIndicator(color: Colors.white)
                    else if (isConnected) ...[
                      const Icon(Icons.power_settings_new, size: 50, color: Colors.white),
                      const SizedBox(height: 10),
                      Text(
                        widget.isEnglish ? 'DISCONNECT' : 'ဖြတ်တောက်မည်',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else ...[
                      const Icon(Icons.bolt, size: 50, color: Colors.white),
                      const SizedBox(height: 10),
                      Text(
                        widget.isEnglish ? 'CONNECT' : 'ချိတ်ဆက်မည်',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: isDark ? const Color(0xFF161C2D) : Colors.white,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: isDark ? Colors.grey : Colors.black54,
        currentIndex: _bottomNavIndex,
        onTap: (index) {
          setState(() {
            _bottomNavIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.security),
            label: 'VPN',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.dns),
            label: widget.isEnglish ? 'Servers' : 'ဆာဗာများ',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.language),
            label: widget.isEnglish ? 'Browser' : 'ဘရောက်ဇာ',
          ),
        ],
      ),
    );
  }
}
