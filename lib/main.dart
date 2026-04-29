import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_apps/device_apps.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
      home: const VpnHomeScreen(),
    );
  }
}

// ==========================================
// လုံခြုံရေး Browser စာမျက်နှာအသစ် (Desktop Site အမြဲပေါ်မည်)
// ==========================================
class DesktopBrowserScreen extends StatefulWidget {
  final bool isEnglish;
  const DesktopBrowserScreen({Key? key, required this.isEnglish}) : super(key: key);

  @override
  State<DesktopBrowserScreen> createState() => _DesktopBrowserScreenState();
}

class _DesktopBrowserScreenState extends State<DesktopBrowserScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // ကွန်ပျူတာကနေ ဝင်သကဲ့သို့ အမြဲတမ်း ဟန်ဆောင်ထားမည့်စာကြောင်း (Desktop Site Force)
      ..setUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.google.com'));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEnglish ? 'Secure Browser' : 'လုံခြုံသော ဘရောက်ဇာ', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18)),
        leading: IconButton(
          icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: isDark ? Colors.white : Colors.black87),
            onPressed: () => _controller.reload(),
          )
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            ),
        ],
      ),
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
  List<Application> installedApps = [];
  List<String> bypassedApps = [];
  bool isLoadingApps = true;
  String _searchQuery = "";
  
  late bool isLocalEnglish;
  late bool isLocalDark;

  @override
  void initState() {
    super.initState();
    isLocalEnglish = widget.isEnglish;
    _loadBypassedApps();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    isLocalDark = ZVpnApp.of(context)?.isDarkMode ?? true;
  }

  Future<void> _loadBypassedApps() async {
    final prefs = await SharedPreferences.getInstance();
    bypassedApps = prefs.getStringList('bypassed_apps') ?? [];
    
    try {
      List<Application> apps = await DeviceApps.getInstalledApplications(
        includeAppIcons: true,
        includeSystemApps: true, 
        onlyAppsWithLaunchIntent: true,
      );
      apps.sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));
      installedApps = apps;
    } catch (e) {}
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

  void _showManualAddDialog() {
    TextEditingController manualController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isLocalDark ? const Color(0xFF232B40) : Colors.white,
          title: Text(isLocalEnglish ? "Add App Manually" : "App ကိုယ်တိုင်ထည့်ရန်", style: const TextStyle(fontSize: 18)),
          content: TextField(
            controller: manualController,
            decoration: InputDecoration(
              hintText: isLocalEnglish ? "e.g., com.facebook.katana" : "Package Name ထည့်ပါ",
              hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isLocalEnglish ? "Cancel" : "ပယ်ဖျက်မည်", style: const TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                String pkg = manualController.text.trim();
                if (pkg.isNotEmpty) {
                  _toggleBypassApp(pkg, true);
                  Navigator.pop(context);
                }
              },
              child: Text(isLocalEnglish ? "Add" : "ထည့်မည်", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = ZVpnApp.of(context);

    List<Application> filteredApps = installedApps.where((app) {
      return app.appName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    List<String> hiddenBypassed = bypassedApps.where((pkg) {
      return !installedApps.any((app) => app.packageName == pkg);
    }).toList();
    
    int totalItems = hiddenBypassed.length + filteredApps.length;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isLocalEnglish ? 'Settings' : 'ဆက်တင်များ', style: TextStyle(color: isLocalDark ? Colors.white : Colors.black87)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isLocalDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent),
            onPressed: _showManualAddDialog,
            tooltip: isLocalEnglish ? "Add Manually" : "ကိုယ်တိုင်ထည့်ရန်",
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          ListTile(
            leading: Icon(isLocalDark ? Icons.dark_mode : Icons.light_mode, color: Colors.blueAccent),
            title: Text(isLocalEnglish ? 'Dark Mode' : 'အမှောင်ပုံစံ'),
            trailing: Switch(
              value: isLocalDark,
              activeColor: Colors.blueAccent,
              onChanged: (val) {
                appState?.toggleTheme(val);
                setState(() => isLocalDark = val);
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language, color: Colors.blueAccent),
            title: Text(isLocalEnglish ? 'Language' : 'ဘာသာစကား'),
            subtitle: Text(isLocalEnglish ? 'English' : 'မြန်မာ'),
            trailing: Switch(
              value: isLocalEnglish,
              activeColor: Colors.blueAccent,
              onChanged: (val) {
                appState?.toggleLanguage(val);
                setState(() => isLocalEnglish = val);
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
            child: Text(
              isLocalEnglish ? 'Split Tunneling (Bypass Apps)' : 'App များကို ရှောင်ကွင်းမည်',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              isLocalEnglish 
                ? 'Selected apps will NOT use the VPN connection.' 
                : 'အောက်တွင် အမှန်ခြစ်ထားသော App များသည် VPN ကို မသုံးဘဲ ရိုးရိုးအင်တာနက်ဖြင့်သာ အလုပ်လုပ်ပါမည်။',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: isLocalDark ? const Color(0xFF232B40) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                style: TextStyle(color: isLocalDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: isLocalEnglish ? 'Search apps...' : 'App အမည်ဖြင့် ရှာဖွေရန်...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoadingApps
              ? const Center(child: CircularProgressIndicator())
              : (totalItems == 0)
                ? Center(child: Text(isLocalEnglish ? 'No apps found.' : 'App များ ရှာမတွေ့ပါ။', style: const TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: totalItems,
                    itemBuilder: (context, index) {
                      if (index < hiddenBypassed.length) {
                        String pkg = hiddenBypassed[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            child: Icon(Icons.android, color: Colors.white),
                          ),
                          title: Text(isLocalEnglish ? 'Manually Added App' : 'ကိုယ်တိုင်ထည့်ထားသော App'),
                          subtitle: Text(pkg, style: const TextStyle(fontSize: 11, color: Colors.amber)),
                          trailing: Checkbox(
                            value: true,
                            activeColor: Colors.redAccent,
                            onChanged: (val) => _toggleBypassApp(pkg, val ?? false),
                          ),
                        );
                      }
                      
                      var app = filteredApps[index - hiddenBypassed.length];
                      bool isBypassed = bypassedApps.contains(app.packageName);
                      return ListTile(
                        leading: app is ApplicationWithIcon 
                            ? Image.memory(app.icon, width: 40, height: 40) 
                            : const Icon(Icons.android, color: Colors.green),
                        title: Text(app.appName),
                        subtitle: Text(app.packageName, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        trailing: Checkbox(
                          value: isBypassed,
                          activeColor: Colors.redAccent,
                          onChanged: (val) => _toggleBypassApp(app.packageName, val ?? false),
                        ),
                      );
                    },
                  ),
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
  const VpnHomeScreen({Key? key}) : super(key: key);

  @override
  State<VpnHomeScreen> createState() => _VpnHomeScreenState();
}

class _VpnHomeScreenState extends State<VpnHomeScreen> {
  int _bottomNavIndex = 0;
  bool isOutlineSelected = true; 
  bool isConnecting = false;
  bool isConnected = false;
  
  String _actualKey = ""; 
  
  List<String> outlineKeys = [];
  List<String> v2rayKeys = [];
  String activeOutlineKey = "";
  String activeV2rayKey = "";

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
      outlineKeys = prefs.getStringList('outline_keys') ?? [];
      v2rayKeys = prefs.getStringList('v2ray_keys') ?? [];
      activeOutlineKey = prefs.getString('active_outline') ?? (outlineKeys.isNotEmpty ? outlineKeys.first : "");
      activeV2rayKey = prefs.getString('active_v2ray') ?? (v2rayKeys.isNotEmpty ? v2rayKeys.first : "");
      _updateDisplayKey();
    });
  }

  Future<void> _saveKeysToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('outline_keys', outlineKeys);
    prefs.setStringList('v2ray_keys', v2rayKeys);
    prefs.setString('active_outline', activeOutlineKey);
    prefs.setString('active_v2ray', activeV2rayKey);
  }

  void _updateDisplayKey() {
    String currentKey = isOutlineSelected ? activeOutlineKey : activeV2rayKey;
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

  void _showSavedKeysBottomSheet(bool isEnglish) {
    List<String> currentList = isOutlineSelected ? outlineKeys : v2rayKeys;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.5,
              child: Column(
                children: [
                  Text(
                    isOutlineSelected ? (isEnglish ? "Outline Servers" : "မှတ်ထားသော Outline ဆာဗာများ") : (isEnglish ? "V2Ray Servers" : "မှတ်ထားသော V2Ray ဆာဗာများ"), 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: currentList.isEmpty 
                      ? Center(child: Text(isEnglish ? "No saved servers yet." : "မှတ်ထားသော ဆာဗာ မရှိသေးပါ!", style: const TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: currentList.length,
                          itemBuilder: (context, index) {
                            String key = currentList[index];
                            bool isActive = key == _actualKey;
                            return Card(
                              color: isDark ? const Color(0xFF232B40) : Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: isActive ? Colors.blueAccent : Colors.transparent, width: 1.5)
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isActive ? Colors.blueAccent : Colors.grey.shade300,
                                  child: Text("${index + 1}", style: TextStyle(color: isActive ? Colors.white : Colors.black87)),
                                ),
                                title: Text(_extractName(key), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
                                onTap: () {
                                  setState(() {
                                    if (isOutlineSelected) activeOutlineKey = key;
                                    else activeV2rayKey = key;
                                    _updateDisplayKey();
                                    _saveKeysToStorage();
                                  });
                                  Navigator.pop(context);
                                },
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () {
                                    setModalState(() {
                                      currentList.removeAt(index);
                                    });
                                    setState(() {
                                      if (isOutlineSelected) {
                                        outlineKeys = currentList;
                                        if (activeOutlineKey == key) activeOutlineKey = currentList.isNotEmpty ? currentList.first : "";
                                      } else {
                                        v2rayKeys = currentList;
                                        if (activeV2rayKey == key) activeV2rayKey = currentList.isNotEmpty ? currentList.first : "";
                                      }
                                      _saveKeysToStorage();
                                      _updateDisplayKey();
                                    });
                                  }
                                )
                              ),
                            );
                          }
                        )
                  )
                ]
              )
            );
          }
        );
      }
    );
  }

  void _toggleConnection(bool isEnglish) async {
    if (isConnected) {
      await flutterV2ray.stopV2Ray();
      return;
    }

    String keyToUse = _actualKey.isNotEmpty ? _actualKey : _keyController.text.trim();

    if (keyToUse.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEnglish ? 'Please insert a key first!' : 'ကျေးဇူးပြု၍ Key ကို အရင်ထည့်ပါ!')),
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

        final prefs = await SharedPreferences.getInstance();
        List<String> bypassedApps = prefs.getStringList('bypassed_apps') ?? [];

        await flutterV2ray.startV2Ray(
          remark: serverRemark,
          config: jsonConfig,
          blockedApps: bypassedApps,
          proxyOnly: false,
        );
      } catch (e) {
        setState(() {
          isConnecting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().contains("ssconf error") 
            ? (isEnglish ? "Use ss:// Outline key instead of ssconf://" : "ss:// ဖြင့်စသော Key ကိုသာ ထည့်ပါ") 
            : (isEnglish ? 'Invalid Key or Connection Failed' : 'Key မှားယွင်းနေပါသည် (သို့) ချိတ်ဆက်၍မရပါ'))),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEnglish ? 'VPN Permission is required!' : 'VPN အသုံးပြုခွင့် ပေးရန် လိုအပ်ပါသည်!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = ZVpnApp.of(context);
    final isEnglish = appState?.isEnglish ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final boxColor = isDark ? const Color(0xFF232B40) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;

    String connectionStatusText = isConnected 
        ? (isEnglish ? 'Connected' : 'ချိတ်ဆက်ထားပါသည်') 
        : (isConnecting 
            ? (isEnglish ? 'Connecting...' : 'ချိတ်ဆက်နေသည်...') 
            : (isEnglish ? 'Not Connected' : 'ချိတ်ဆက်ထားခြင်းမရှိပါ'));

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
                MaterialPageRoute(builder: (context) => SettingsScreen(isEnglish: isEnglish)),
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
                  isOutlineSelected ? (isEnglish ? 'ss:// (or) Outline Key' : 'ss:// (သို့) Outline Key') : 'vmess:// (or) vless://',
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
                          if (isOutlineSelected) {
                            activeOutlineKey = trimmed;
                            if (!outlineKeys.contains(trimmed)) outlineKeys.add(trimmed);
                          } else {
                            activeV2rayKey = trimmed;
                            if (!v2rayKeys.contains(trimmed)) v2rayKeys.add(trimmed);
                          }
                        });
                        _saveKeysToStorage();
                        String name = _extractName(trimmed);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _keyController.text = name;
                          _keyController.selection = TextSelection.fromPosition(TextPosition(offset: name.length));
                        });
                      } else if (trimmed.isEmpty) {
                        setState(() {
                          _actualKey = "";
                          if (isOutlineSelected) activeOutlineKey = "";
                          else activeV2rayKey = "";
                        });
                        _saveKeysToStorage();
                      }
                    },
                    decoration: InputDecoration(
                      hintText: isEnglish ? 'Paste your Key here...' : 'ဒီနေရာမှာ Key ကို Paste ချပါ...',
                      hintStyle: TextStyle(color: hintColor, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      suffixIcon: _actualKey.isNotEmpty 
                        ? IconButton(
                            icon: Icon(Icons.cancel, color: isDark ? Colors.grey : Colors.black54),
                            onPressed: () {
                              setState(() {
                                _actualKey = "";
                                if (isOutlineSelected) activeOutlineKey = "";
                                else activeV2rayKey = "";
                                _saveKeysToStorage();
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
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.list, color: Colors.blueAccent),
                label: Text(
                  isEnglish 
                    ? "Saved Servers (${isOutlineSelected ? outlineKeys.length : v2rayKeys.length})" 
                    : "မှတ်ထားသော ဆာဗာများ (${isOutlineSelected ? outlineKeys.length : v2rayKeys.length})",
                  style: const TextStyle(color: Colors.blueAccent),
                ),
                onPressed: () => _showSavedKeysBottomSheet(isEnglish),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              connectionStatusText,
              style: TextStyle(
                color: isConnected ? Colors.greenAccent.shade400 : (isConnecting ? Colors.amber : (isDark ? Colors.grey : Colors.black54)), 
                fontSize: 18,
                fontWeight: isConnected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: isConnecting ? null : () => _toggleConnection(isEnglish),
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
                        isEnglish ? 'DISCONNECT' : 'ဖြတ်တောက်မည်',
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
                        isEnglish ? 'CONNECT' : 'ချိတ်ဆက်မည်',
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
        onTap: (index) async {
          if (index == 1) {
            final Uri url = Uri.parse('https://t.me/zvpnt');
            if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isEnglish ? 'Could not open Telegram' : 'တယ်လီဂရမ်ကို ဖွင့်၍မရပါ')),
                );
              }
            }
          } else if (index == 2) {
            // "In-App WebView" ဖြင့် Desktop Site သီးသန့် အမြဲပွင့်မည့်စာမျက်နှာသို့ သွားမည်
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DesktopBrowserScreen(isEnglish: isEnglish)),
            );
          } else {
            setState(() {
              _bottomNavIndex = index;
            });
          }
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.security),
            label: 'VPN',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.telegram), 
            label: isEnglish ? 'Telegram' : 'တယ်လီဂရမ်', 
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.language),
            label: isEnglish ? 'Browser' : 'ဘရောက်ဇာ',
          ),
        ],
      ),
    );
  }
}
