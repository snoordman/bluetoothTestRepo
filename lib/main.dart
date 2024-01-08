import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Scan Device Bluetooth'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<BluetoothDevice> listDeviceResults = [];
  bool isScanning = false;
  bool isBluetoothSupported = false;
  bool isBluetoothSupported2 = false;

  @override
  void initState() {
    super.initState();
    checkBluetoothSupport();
  }

  Future<void> checkBluetoothSupport() async {
    bool isWeb = kIsWeb;

    if (isWeb) {
      setState(() {
        isBluetoothSupported = false;
        isBluetoothSupported2 = false;
      });
    } else {
      bool flutterBlueSupported = await FlutterBluePlus.isSupported;

      setState(() {
        isBluetoothSupported = true;
        isBluetoothSupported2 = flutterBlueSupported;
      });

      if (!flutterBlueSupported) {
        showSnackBar('Bluetooth not available', Colors.red);
        print("Bluetooth not supported by this device");
      }
    }
    return;
  }

  Future<void> startScan() async {
    try {
      setState(() {
        isScanning = true;
        listDeviceResults.clear(); // Clear previous results
      });

      // listen to scan results
      // Note: `onScanResults` only returns live scan results, i.e. during scanning
      // Use: `scanResults` if you want live scan results *or* the previous results
      var subscription = FlutterBluePlus.onScanResults.listen(
        (results) {
          if (results.isNotEmpty) {
            setState(() {
              listDeviceResults.add(results.last.device);
            });
          }
        },
        onError: (e) => print(e),
      );

      // Wait for Bluetooth enabled & permission granted
      // In your real app you should use `FlutterBluePlus.adapterState.listen` to handle all states
      await FlutterBluePlus.adapterState
          .where((val) => val == BluetoothAdapterState.on)
          .first;

      // Start scanning
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));

      // Stop scanning
      await FlutterBluePlus.stopScan();

      // cancel to prevent duplicate listeners
      subscription.cancel();

      setState(() {
        isScanning = false;
      });

      showSnackBar('Scan completed successfully!', Colors.green);
    } catch (e) {
      setState(() {
        isScanning = false;
      });

      showSnackBar('Error during scan: $e', Colors.red);
    }
  }

  void showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Bluetooth Support:',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              isBluetoothSupported ? 'Supported' : 'Not Supported',
              style: TextStyle(
                fontSize: 24,
                color: isBluetoothSupported ? Colors.green : Colors.red,
              ),
            ),
            Text(
              isBluetoothSupported2 ? 'Running good' : 'Running on web',
              style: TextStyle(
                fontSize: 24,
                color: isBluetoothSupported ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isBluetoothSupported ? startScan : null,
              child: Text('Start Scanning'),
            ),
            SizedBox(height: 20),
            isScanning
                ? CircularProgressIndicator()
                : Text('Scan Status: Not Scanning'),
            const SizedBox(height: 20),
            if (listDeviceResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: listDeviceResults.length,
                  itemBuilder: (context, index) {
                    BluetoothDevice device = listDeviceResults[index];
                    return ListTile(
                      title: Text(device.name ?? 'Unknown Device'),
                      subtitle: Text(device.id.toString()),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
