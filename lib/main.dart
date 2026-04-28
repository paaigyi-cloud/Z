import 'package:flutter/material.dart';

void main() {
  runApp(const Zapp());
}

class Zapp extends StatelessWidget {
  const ZApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Z',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF161C2D), // Dark background color
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
  bool isOutlineSelected = true; // To toggle between Outline and V2Ray

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
            color: Colors.amber, // Gold color
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
            // Key Type Toggle Button
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF232B40),
                borderRadius: BorderRadius.circular(10),
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
                          borderRadius: BorderRadius.circular(10),
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
                          borderRadius: BorderRadius.circular(10),
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
            
            // Key Prefix Text
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

            // Input Text Field
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF232B40),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'ဒီနေရာမှာ Key ကို Paste ချပါ...',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            
            const SizedBox(height: 40),

            // Status Text
            const Text(
              'ချိတ်ဆက်ထားခြင်းမရှိပါ',
              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),
            
            const Spacer(),

            // Connect Button
            GestureDetector(
              onTap: () {
                // TODO: Add connect logic here
              },
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blueAccent,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt, size: 50, color: Colors.white),
                    SizedBox(height: 10),
                    Text(
                      'ချိတ်ဆက်မည်',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      
      // Bottom Navigation Bar
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
