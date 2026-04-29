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
  bool isOutlineSelected = false; 
  bool isConnecting = false;
  bool isConnected = false;
  String connectionStatus = 'ချိတ်ဆက်ထားခြင်းမရှိပါ';

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

  void _toggleConnection() async {
    if (isConnected) {
      await flutterV2ray.stopV2Ray();
      return;
    }

    String key = _keyController.text.trim();

    if (key.isEmpty) {
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
        // ဤနေရာတွင် လင့်ခ်များကို JSON သို့ ပြောင်းလဲပေးမည့် Code ထည့်သွင်းထားပါသည်
        String jsonConfig = key;
        String remark = "Z-VPN Server";

        if (key.startsWith("vmess://") || key.startsWith("vless://") || key.startsWith("ss://") || key.startsWith("trojan://")) {
          var parsedNode = FlutterV2ray.parseFromURL(key);
          jsonConfig = parsedNode.getFullConfiguration();
        }

        // ပြောင်းလဲပြီးသား JSON ကို အင်ဂျင်ထဲသို့ ထည့်၍ ချိတ်ဆက်ခြင်း
        await flutterV2ray.startV2Ray(
          remark: remark,
          config: jsonConfig,
        );
      } catch (e) {
        setState(() {
          isConnecting = false;
          connectionStatus = 'ချိတ်ဆက်မှု မအောင်မြင်ပါ';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Key မှားယွင်းနေပါသည် (သို့) ချိတ်ဆက်၍မရပါ')),
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
                  isOutlineSelected ? 'ss:// (သို့) ssconf://' : 'vmess:// (သို့) vless://',
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
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'ဒီနေရာမှာ Key ကို Paste ချပါ...',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
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
