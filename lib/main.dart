import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';

void main() {
  runApp(const ZVpnApp());
}

class ZVpnApp extends StatelessWidget {
  const ZVpnApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Z VPN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF161C2D),
        primaryColor: Colors.blueAccent,
      ),
      home: const VpnHomeScreen(),
    );
  }
}

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
  String connectionStatus = 'ချိတ်ဆက်ထားခြင်းမရှိပါ';

  // တကယ့် Key အရှည်ကြီးကို နောက်ကွယ်မှာ ဖွက်ပြီး သိမ်းထားမည့်နေရာ
  String _actualKey = ""; 

  final TextEditingController _keyController = TextEditingController();
  late FlutterV2ray flutterV2ray;

  @override
  void initState() {
    super.initState();
    flutterV2ray = FlutterV2ray(
      onStatusChanged: (status) {
        if (mounted) {
          setState(() {
            if (status.state == "CONNECTED") {
              isConnecting = false;
              isConnected = true;
              connectionStatus = 'ချိတ်ဆက်ထားပါသည်';
            } else if (status.state == "DISCONNECTED") {
              isConnecting = false;
              isConnected = false;
              connectionStatus = 'ချိတ်ဆက်ထားခြင်းမရှိပါ';
            }
          });
        }
      },
    );
    _initV2Ray();
  }

  Future<void> _initV2Ray() async {
    await flutterV2ray.initializeV2Ray();
  }

  // Key ထဲမှ ဆာဗာနာမည်ကို အလိုအလျောက် ဆွဲထုတ်မည့် Function
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
    } catch (e) {
      // ဘာသာပြန်၍မရပါက Default အတိုင်းထားမည်
    }
    
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

    // ဖွက်ထားသော key ရှိလျှင် ၎င်းကိုသုံးမည်၊ မရှိလျှင် text box ထဲကစာကို သုံးမည်
    String keyToUse = _actualKey.isNotEmpty ? _actualKey : _keyController.text.trim();

    if (keyToUse.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ကျေးဇူးပြု၍ Key ကို အရင်ထည့်ပါ!')),
      );
      return;
    }

    if (await flutterV2ray.requestPermission()) {
      setState(() {
        isConnecting = true;
        connectionStatus = 'ချိတ်ဆက်နေသည်...';
      });

      try {
        String jsonConfig = keyToUse;
        String serverRemark = _keyController.text.trim();
        if (serverRemark.isEmpty) serverRemark = "Z-VPN Server";

        if (keyToUse.startsWith("ssconf://")) {
          throw Exception("ssconf:// အစား ss:// ဖြင့်စသော Outline Key ကိုသာ အသုံးပြုပါ။");
        }

        if (keyToUse.startsWith("vmess://") || keyToUse.startsWith("vless://") || keyToUse.startsWith("ss://") || keyToUse.startsWith("trojan://")) {
          var parsedNode = FlutterV2ray.parseFromURL(keyToUse);
          jsonConfig = parsedNode.getFullConfiguration();
        }

        await flutterV2ray.startV2Ray(
          remark: serverRemark, // နာမည်အဖြစ် ပြောင်းထားသော စာသားကို အင်ဂျင်သို့ ပေးပို့မည်
          config: jsonConfig,
        );
      } catch (e) {
        setState(() {
          isConnecting = false;
          connectionStatus = 'ချိတ်ဆက်မှု မအောင်မြင်ပါ';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().contains("ssconf://") ? "ss:// ဖြင့်စသော Key ကိုသာ ထည့်ပါ" : 'Key မှားယွင်းနေပါသည် (သို့) ချိတ်ဆက်၍မရပါ')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('VPN အသုံးပြုခွင့် ပေးရန် လိုအပ်ပါသည်!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
            icon: const Icon(Icons.settings, color: Colors.grey),
            onPressed: () {},
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
                color: const Color(0xFF232B40),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isOutlineSelected = true;
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
                            color: isOutlineSelected ? Colors.white : Colors.grey,
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
                            color: !isOutlineSelected ? Colors.white : Colors.grey,
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
                const Icon(Icons.vpn_key, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  isOutlineSelected ? 'ss:// (သို့) Outline Key' : 'vmess:// (သို့) vless://',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF232B40),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1.0),
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
                    maxLines: _actualKey.isNotEmpty ? 1 : 4, // Key ထည့်လိုက်ရင် (၁) ကြောင်းတည်း ဖြစ်သွားမည်
                    style: TextStyle(
                      color: _actualKey.isNotEmpty ? Colors.amber : Colors.white, 
                      fontWeight: _actualKey.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                      fontSize: _actualKey.isNotEmpty ? 18 : 14,
                    ),
                    textAlign: _actualKey.isNotEmpty ? TextAlign.center : TextAlign.start, // နာမည်ကို အလယ်တွင်ထားမည်
                    onChanged: (value) {
                      String trimmed = value.trim();
                      // Key အစစ် Paste ချလိုက်ကြောင်း စစ်ဆေးခြင်း
                      if (trimmed.startsWith("ss://") || trimmed.startsWith("vmess://") || trimmed.startsWith("vless://") || trimmed.startsWith("trojan://")) {
                        setState(() {
                          _actualKey = trimmed;
                        });
                        String name = _extractName(trimmed);
                        // Key အစား နာမည်ကို အလိုအလျောက် အစားထိုးပြသမည်
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _keyController.text = name;
                          _keyController.selection = TextSelection.fromPosition(TextPosition(offset: name.length));
                        });
                      } else if (trimmed.isEmpty) {
                        setState(() {
                          _actualKey = "";
                        });
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'ဒီနေရာမှာ Key ကို Paste ချပါ...',
                      hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      // Key ဝင်သွားပါက ဖျက်ရန် (X) ခလုတ်လေး ပေါ်လာမည်
                      suffixIcon: _actualKey.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _actualKey = "";
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
                color: isConnected ? Colors.greenAccent : (isConnecting ? Colors.amber : Colors.grey), 
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
                      const Text(
                        'ဖြတ်တောက်မည်',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else ...[
                      const Icon(Icons.bolt, size: 50, color: Colors.white),
                      const SizedBox(height: 10),
                      const Text(
                        'ချိတ်ဆက်မည်',
                        style: TextStyle(
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
        backgroundColor: const Color(0xFF161C2D),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _bottomNavIndex,
        onTap: (index) {
          setState(() {
            _bottomNavIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.security),
            label: 'VPN',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dns),
            label: 'ဆာဗာများ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.language),
            label: 'ဘရောက်ဇာ',
          ),
        ],
      ),
    );
  }
}
