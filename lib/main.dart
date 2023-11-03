import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
      MultiProvider(
        providers: [
          ChangeNotifierProvider<Page1Data>(
            create: (context) => Page1Data(),
          ),
          ChangeNotifierProvider<Page2Data>(
            create: (context) => Page2Data(),
          ),
          // Add other providers if needed
        ],
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

class Page2Data extends ChangeNotifier {
  Map<String, String> favoritedUrls = {};

  void updateStarState(String slug, bool isFilled, String imageUrl) {
    favoritedUrls[slug] = isFilled ? imageUrl : ''; // Save or remove the imageUrl based on star state
    notifyListeners();
  }

  List<String> getFavoritedUrls() {
    return favoritedUrls.values.where((url) => url.isNotEmpty).toList();
  }

  String getSlugForUrl(String imageUrl) {
    // Implement the logic to retrieve the slug for the given imageUrl
    // This might involve iterating through the favoritedUrls and finding a match
    // You can replace the example logic below with your actual implementation
    for (var entry in favoritedUrls.entries) {
      if (entry.value == imageUrl) {
        return entry.key;
      }
    }
    return ''; // Return an appropriate default value if no match is found
  }
}



class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> webpUrls = [];
  List<Map<String, dynamic>> data = []; // Declare data as a class variable

  @override
  void initState() {
    super.initState();
    // Call your API request method when the widget is being initialized
    fetchData();
  }

  Future<void> fetchData() async {
    final response = await http.get(Uri.parse(
        'https://api.giphy.com/v1/gifs/trending?api_key=ZjFSjY5rgEywpQ5WUsqJtKQHtAUlzCIx&limit=10'));

    if (response.statusCode == 200) {
      // Successful API call
      final apiData = json.decode(response.body)['data'];

      setState(() {
        data = List<Map<String, dynamic>>.from(apiData); // Assign apiData to data
        webpUrls = data
            .map<String>((item) {
              final originalWebpUrl = item['images']['original']['webp'].toString();
              return originalWebpUrl;
            })
            .toList();
      });
    } else {
      // Handle errors
      setState(() {
        webpUrls = ['Failed to load data. Error ${response.statusCode}'];
      });
    }
  }

  void _showImageDialog(String imageUrl, String slug) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Image.network(imageUrl),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Home Page',
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(16.0),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return GestureDetector(
                    onTap: () {
                      _showImageDialog(webpUrls[index], data[index]['slug'].toString());
                    },
                    child: Stack(
                      children: [
                        Image.network(webpUrls[index]),
                        Positioned(
                          top: 8.0,
                          right: 8.0,
                          child: StarIcon(slug: data[index]['slug'].toString(), imageUrl: webpUrls[index]),
                        ),
                      ],
                    ),
                  );
                },
                childCount: webpUrls.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class StarIcon extends StatelessWidget {
  final String slug;
  final String imageUrl;

  const StarIcon({required this.slug, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Consumer<Page2Data>(
      builder: (context, page2Data, _) {
        // Perform a null check on favoritedUrls[slug]
        final bool isStarred = page2Data.favoritedUrls[slug]?.isNotEmpty ?? false;

        return GestureDetector(
          onTap: () {
            // Toggle the state of the star icon on click
            page2Data.updateStarState(slug, !isStarred, imageUrl);
          },
          child: Icon(
            isStarred ? Icons.star : Icons.star_border,
            color: isStarred ? Colors.yellow : null,
          ),
        );
      },
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
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Image.asset(
                    'assets/logo.png', // Change to the actual path of your logo image
                    height: 100, // Adjust the height as needed
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Search',
                      labelStyle: TextStyle(color: Colors.white),
                      enabledBorder: customBorder,
                      focusedBorder: customBorder,
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
      body: Consumer<Page2Data>(
        builder: (context, page2Data, _) {
          List<String> webpUrls = page2Data.getFavoritedUrls();

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.all(16.0),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      return GestureDetector(
                        onTap: () {
                          _showImageDialog(context, webpUrls[index]);
                        },
                        child: Stack(
                          children: [
                            Image.network(webpUrls[index]),
                            Positioned(
                              top: 8.0,
                              right: 8.0,
                              child: StarIcon(slug: page2Data.getSlugForUrl(webpUrls[index]), imageUrl: webpUrls[index]),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: webpUrls.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Image.network(imageUrl),
        );
      },
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
        ));
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
