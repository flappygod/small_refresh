import 'package:flutter/material.dart';
import 'package:small_refresh/small_refresh.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final SmallRefreshController _refreshController = SmallRefreshController();

  int _dataCount = 0;
  List dataList = List.from({"1", "2", "3", "4", "5", "6", "7", "8", "9", "10"});

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: _buildRefresh(),
    );
  }

  ///build refresh view
  Widget _buildRefresh() {
    return SmallRefresh(
      topPadding: 0,
      bottomPadding: 0,
      firstRefresh: true,
      controller: _refreshController,
      header: DefaultSmallRefreshHeader(
        controller: _refreshController,
      ),
      footer: DefaultSmallRefreshFooter(
        controller: _refreshController,
      ),
      slivers: _buildSliver(),
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 2000));
        dataList.clear();
        _dataCount = 0;
        for (int s = 0; s < 10; s++) {
          _dataCount++;
          dataList.add(_dataCount.toString());
        }
      },
      onLoad: () async {
        await Future.delayed(const Duration(milliseconds: 2000));
        if (dataList.length < 30) {
          for (int s = 0; s < 10; s++) {
            _dataCount++;
            dataList.add(_dataCount.toString());
          }
          setState(() {});
        } else {
          _refreshController.footerEnd();
          setState(() {});
        }
      },
    );
  }

  ///build sliver
  List<Widget> _buildSliver() {
    return dataList.map((e) {
      return SliverToBoxAdapter(
        child: Container(
          height: 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey, width: 1 / MediaQuery.devicePixelRatioOf(context)),
            ),
          ),
          child: Text(
            e,
            style: const TextStyle(fontSize: 15, color: Colors.black54),
          ),
        ),
      );
    }).toList();
  }
}