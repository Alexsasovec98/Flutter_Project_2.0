import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Page1Data extends ChangeNotifier {
  String searchText = '';
  String dropdownOption1 = "Option 1";
  String dropdownOption2 = "Option 1";

  void updateSearchText(String text) {
    searchText = text;
    notifyListeners();
  }

  void updateDropdownOption1(String option) {
    dropdownOption1 = option;
    notifyListeners();
  }

  void updateDropdownOption2(String option) {
    dropdownOption2 = option;
    notifyListeners();
  }
}

void main() => runApp(
      ChangeNotifierProvider<Page1Data>(
        create: (context) => Page1Data(),
        child: MyApp(),
      ),
    );

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Color(0xFF1D242E),
        appBarTheme: AppBarTheme(backgroundColor: Color(0xFF1D242E)),
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Home Page',
      body: Container(
        color: Color(0xFF1F2732),
        child: Center(
          child: Text(
            'Welcome to the Creative Design Example!',
            style: TextStyle(fontSize: 24, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class Page1 extends StatefulWidget {
  @override
  _Page1State createState() => _Page1State();
}

class _Page1State extends State<Page1> {
  final List<String> dropdownOptions = ["Option 1", "Option 2", "Option 3", "Option 4"];

  @override
  Widget build(BuildContext context) {
    Page1Data data = Provider.of<Page1Data>(context);

    OutlineInputBorder customBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
      borderSide: BorderSide(color: Colors.white, width: 2.0),
    );

    return MainLayout(
      title: 'Page 1',
      body: Container(
        color: Color(0xFF1F2732),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Search Term',
                      labelStyle: TextStyle(color: Colors.white),
                      enabledBorder: customBorder,
                      focusedBorder: customBorder, // Use the same border for active and inactive states
                    ),
                    initialValue: data.searchText,
                    style: TextStyle(color: Colors.white),
                    onChanged: (value) {
                      data.updateSearchText(value);
                    },
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            Text(
                              'Number of GIF\'s',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                            DropdownButton<String>(
                              isExpanded: true,
                              value: data.dropdownOption1,
                              items: dropdownOptions.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value, style: TextStyle(color: Colors.white)),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                data.updateDropdownOption1(newValue!);
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            Text(
                              'Age Restriction',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                            DropdownButton<String>(
                              isExpanded: true,
                              value: data.dropdownOption2,
                              items: dropdownOptions.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value, style: TextStyle(color: Colors.white)),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                data.updateDropdownOption2(newValue!);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: ElevatedButton(
                          onPressed: () {
                            // Reset button action
                          },
                          child: Text('Reset', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            // Search button action
                          },
                          child: Text('Search', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Page2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Page 2',
      body: Container(
        color: Color(0xFF1F2732),
        child: Center(
          child: Text(
            'Creative Design for Page 2',
            style: TextStyle(fontSize: 24, color: Colors.white),
          ),
        ),
      )
    );
  }
}

class Page3 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Page 3',
      body: Container(
        color: Color(0xFF1F2732),
        child: Center(
          child: Text(
            'Creative Design for Page 3',
            style: TextStyle(fontSize: 24, color: Colors.white),
          ),
        ),
      )
    );
  }
}

class MainLayout extends StatelessWidget {
  final String title;
  final Widget body;

  MainLayout({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(fontFamily: 'Pacifico', fontSize: 24),
        ),
      ),
      drawer: SideMenu(),
      body: body,
    );
  }
}

class SideMenu extends StatelessWidget {
  void _navigateToPage(BuildContext context, Widget page) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Color(0xFF1D242E),
        child: Column(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(top: 10),
              child: _buildMenuItem('Home', () => _navigateToPage(context, HomeScreen())),
            ),
            Divider(color: Colors.black),
            Container(
              margin: EdgeInsets.only(top: 10),
              child: _buildMenuItem('Page 1', () => _navigateToPage(context, Page1())),
            ),
            Divider(color: Colors.black),
            Container(
              margin: EdgeInsets.only(top: 10),
              child: _buildMenuItem('Page 2', () => _navigateToPage(context, Page2())),
            ),
            Divider(color: Colors.black),
            Container(
              margin: EdgeInsets.only(top: 10),
              child: _buildMenuItem('Page 3', () => _navigateToPage(context, Page3())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(String title, VoidCallback onTap) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: onTap,
    );
  }
}