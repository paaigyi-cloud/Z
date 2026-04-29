import 'package:flutter/material.dart';

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

  final TextEditingController _keyController = TextEditingController();

  void _connectVpn() async {
    String key = _keyController.text.trim();

    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ကျေးဇူးပြု၍ Key ကို အရင်ထည့်ပါ!')),
      );
      return;
    }

    setState(() {
      isConnecting = true;
    });

    // ချိတ်ဆက်နေပုံ စမ်းသပ်ရန် ၃ စက္ကန့် စောင့်ခိုင်းထားခြင်း
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      isConnecting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('VPN အင်ဂျင် မချိတ်ဆက်ရသေးပါ!')),
    );
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
            
            // Key Type Toggle Button (ဘောင်ကွတ်ထားသော ဒီဇိုင်းအသစ်)
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF232B40),
                borderRadius: BorderRadius.circular(10),
                // ဤနေရာတွင် အပြာရောင်ဘောင် ထည့်ထားပါသည်
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
                          borderRadius: BorderRadius.circular(8), // ဘောင်အထဲဝင်ရန် နည်းနည်းလျှော့ထားသည်
                        ),
                        alignment: Alignment.center,
                        child: const Text('Outline Key', style: TextStyle(fontWeight: FontWeight.bold)),
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
            
            // Input Text Field (အပေါ်လိုင်းအထူ နှင့် ဘောင်ဒီဇိုင်းအသစ်)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF232B40),
                borderRadius: BorderRadius.circular(10),
                // ဘေးပတ်ပတ်လည် ခဲရောင်ဘောင် အပါးလေး
                border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1.0),
              ),
              child: Column(
                children: [
                  // အစ်ကိုပြထားသောပုံမှ အပေါ်ဘက်ရှိ အရောင်လိုင်းလေး
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
              isConnecting ? 'ချိတ်ဆက်နေသည်...' : 'ချိတ်ဆက်ထားခြင်းမရှိပါ',
              style: TextStyle(
                color: isConnecting ? Colors.amber : Colors.grey, 
                fontSize: 18
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: isConnecting ? null : _connectVpn,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnecting ? Colors.grey : Colors.blueAccent,
                  boxShadow: [
                    BoxShadow(
                      color: isConnecting ? Colors.transparent : Colors.blueAccent.withOpacity(0.4),
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
                    else ...[
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
