import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Page1Data extends ChangeNotifier {
  String searchText = '';
  int limitOption = 5; // Default limit option
  String ratingOption = 'g'; // Default rating option

  void updateSearchText(String text) {
    searchText = text;
    notifyListeners();
  }

  void updateLimitOption(int limit) {
    limitOption = limit;
    notifyListeners();
  }

  void updateRatingOption(String rating) {
    ratingOption = rating;
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
          ChangeNotifierProvider<Page3Data>(
            create: (context) => Page3Data(),
          ),
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

class Page3Data extends ChangeNotifier {
  List<Page3History> searchHistory = [];

  void updateHistory(Page3History history) {
    searchHistory.add(history);
    notifyListeners();
  }
}

class Page3History {
  final String searchText;
  final int limitOption;  // Corrected variable name
  final String ratingOption;  // Corrected variable name
  List<String> webpUrls; // Updated to allow modification

  Page3History({
    required this.searchText,
    required this.limitOption,
    required this.ratingOption,
    required this.webpUrls,
  });
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
  final List<int> limitOptions = [5, 10, 15, 20];
  final List<String> ratingOptions = ['g', 'pg', 'pg-13', 'r'];
  Future<List<String>>? giphyDataFuture;

  @override
  Widget build(BuildContext context) {
    Page1Data data = Provider.of<Page1Data>(context);
    Page3Data page3Data = Provider.of<Page3Data>(context, listen: false);

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
                    'assets/logo.png',
                    height: 100,
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
                            DropdownButton<int>(
                              isExpanded: true,
                              value: data.limitOption,
                              items: limitOptions.map((int value) {
                                return DropdownMenuItem<int>(
                                  value: value,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(value.toString(), style: TextStyle(color: Colors.white)),
                                      Divider(
                                        color: Colors.white,
                                        thickness: 0.5,
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (int? newValue) {
                                data.updateLimitOption(newValue!);
                              },
                              dropdownColor: Color(0xFF1F2732),
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
                              value: data.ratingOption,
                              items: ratingOptions.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(value, style: TextStyle(color: Colors.white)),
                                      Divider(
                                        color: Colors.white,
                                        thickness: 0.5,
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                data.updateRatingOption(newValue!);
                              },
                              dropdownColor: Color(0xFF1F2732),
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
                          onPressed: () async {
                            if (data.searchText.isNotEmpty) {
                              setState(() {
                                giphyDataFuture = fetchGiphyData(data.searchText, data.limitOption, data.ratingOption);
                              });
                            }
                          },
                          child: Text('Search', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Display the API response below the existing container
            Expanded(
              child: FutureBuilder<List<String>>(
                future: giphyDataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No data available'));
                  } else {
                    // Display the fetched images
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                      ),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        return Image.network(snapshot.data![index]);
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
    
  }

  // Function to fetch Giphy data based on the provided parameters
  Future<List<String>> fetchGiphyData(String searchText, int limit, String rating) async {
  final response = await http.get(Uri.parse(
      'https://api.giphy.com/v1/gifs/search?api_key=ZjFSjY5rgEywpQ5WUsqJtKQHtAUlzCIx&q=$searchText&limit=$limit&rating=$rating'));

    if (response.statusCode == 200) {
      // Successful API call
      final apiData = json.decode(response.body)['data'];

      List<String> webpUrls = List<String>.from(apiData.map<String>((item) {
        final originalWebpUrl = item['images']['original']['webp'].toString();
        return originalWebpUrl;
      }));

      // Create a new Page3History entry with webpUrls
      final historyEntry = Page3History(
        searchText: searchText,
        limitOption: limit,
        ratingOption: rating,
        webpUrls: webpUrls,
      );

      // Add the entry to Page3Data
      Provider.of<Page3Data>(context, listen: false).updateHistory(historyEntry);

      return webpUrls;
    } else {
      // Handle errors
      throw Exception('Failed to load data. Error ${response.statusCode}');
    }
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
      body: Consumer<Page3Data>(
        builder: (context, page3Data, _) {
          return Container(
            color: Color(0xFF1F2732),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'History of Search Text and Dropdown Options',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: page3Data.searchHistory.length,
                    itemBuilder: (context, index) {
                      var entry = page3Data.searchHistory[index];
                      return ListTile(
                        title: Text('Search Text: ${entry.searchText}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Limit: ${entry.limitOption}'),
                            Text('Rating: ${entry.ratingOption}'),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
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
