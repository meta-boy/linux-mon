import 'package:flutter/material.dart';
import 'package:linux_mon/pages/battery.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import './icons.dart';
import './utils/get_server_ip.dart';
import 'package:web_socket_channel/io.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'pages/cpu.dart';
import 'pages/dashboard.dart';
import 'pages/disk.dart';
import 'pages/temperatures.dart';
import 'utils/get_server_ip.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class LinuxMon extends StatefulWidget {
  @override
  _LinuxMonState createState() => _LinuxMonState();
}

class _LinuxMonState extends State<LinuxMon> {
  static String _websocketUrl = 'ws://0.0.0.0';
  static IOWebSocketChannel channel = IOWebSocketChannel.connect(_websocketUrl);
  static Stream deviceDataStream = channel.stream.asBroadcastStream();
  String connectionStatus = '';

  static List<Widget> _pages = [
    BatteryPage(deviceDataStream),
    CpuPage(deviceDataStream),
    DashboardPage(deviceDataStream),
    DiskPage(deviceDataStream),
    TemperaturesPage(deviceDataStream),
  ];

  PageController pageController;
  int _selectedIndex = 2;

  wserror(err) async {
    print(new DateTime.now().toString() + " Connection error: $err");
    setState(() {
      connectionStatus = 'Disconnected';
    });
    await reconnect();
  }

  reconnect() async {
    if (channel != null) {
      await Future.delayed(Duration(seconds: 4));
    }
    setState(() {
      print(new DateTime.now().toString() + " Connection attempt started.");
      channel = IOWebSocketChannel.connect(_websocketUrl);
      print(new DateTime.now().toString() + " Connection attempt completed.");
      deviceDataStream = channel.stream.asBroadcastStream();
      _pages = [
        BatteryPage(deviceDataStream),
        CpuPage(deviceDataStream),
        DashboardPage(deviceDataStream),
        DiskPage(deviceDataStream),
        TemperaturesPage(deviceDataStream),
      ];
    });
    if (channel.closeCode != null) {
      setState(() {
        connectionStatus = 'Disconnected';
      });
    } else {
      setState(() {
        connectionStatus = 'Connected';
      });
    }

    deviceDataStream.listen((data) => print('got data'),
        onDone: reconnect, onError: wserror, cancelOnError: true);
  }

  void setupStream() {
    getServerIP().then((websocketIp) {
      if (websocketIp == null) {
        throw ('no servers found');
      }
      _websocketUrl = 'ws://$websocketIp:5678';
      deviceDataStream.listen((data) => print('got data'),
          onDone: reconnect, onError: wserror, cancelOnError: true);
    }).catchError((e) {
      print('could not get server');
      Future.delayed(Duration.zero, () {
        showAlertDialog(context);
      });
    });
  }

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: 2);
    setupStream();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  _onTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    pageController.jumpToPage(index);
  }

  void onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  showAlertDialog(BuildContext context) {
    // set up the button
    Widget okButton = FlatButton(
      child: Text("Rescan"),
      onPressed: () {
        setupStream();
        Navigator.pop(context);
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text("Rescan"),
      content: Text("Could find any servers!"),
      actions: [
        okButton,
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'LINUXMON',
          style: TextStyle(letterSpacing: 2, fontSize: 14),
        ),
        elevation: 0,
        backgroundColor: Color(0xff1C1C26),
        actions: [
          Center(
            child: Container(
              margin: EdgeInsets.only(right: 10.0),
              decoration: BoxDecoration(
                color: Color(0xff24242E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Image.asset('assets/connected-circle.png'),
                    SizedBox(
                      width: 5.0,
                    ),
                    Text(
                      connectionStatus.toUpperCase(),
                      style: TextStyle(color: Color(0xff869EA5), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        // height: 50.0,
        items: <Widget>[
          Icon(
            CustomIcons.ibat2,
            size: 20,
            color: Color(0xff11DFDE),
          ),
          Icon(
            CustomIcons.ichart_bar,
            size: 20,
            color: Color(0xff11DFDE),
          ),
          Icon(
            CustomIcons.ichart_alt,
            size: 20,
            color: Color(0xff11DFDE),
          ),
          Icon(
            CustomIcons.ihdd,
            size: 20,
            color: Color(0xff11DFDE),
          ),
          Icon(
            CustomIcons.itemperatire,
            size: 20,
            color: Color(0xff11DFDE),
          ),
        ],
        color: Color(0xff1C1C26),
        buttonBackgroundColor: Color(0xff1C1C26),
        backgroundColor: Color(0xff0F0F11),
        animationCurve: Curves.easeInOutCubic,
        animationDuration: Duration(milliseconds: 400),
        onTap: _onTapped,
      ),
      body: PageView(
        children: _pages,
        controller: pageController,
        onPageChanged: onPageChanged,
      ),
    );
  }
}
