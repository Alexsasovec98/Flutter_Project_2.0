import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';

class Page1Data extends ChangeNotifier {
  String searchText = '';
  int limitOption = 5; // Default limit option
  String ratingOption = 'G'; // Default rating option

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initPathProvider();
  runApp(
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
}

Future<void> initPathProvider() async {
  await getTemporaryDirectory();
}

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
  List<Map<String, dynamic>> data = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final response = await http.get(Uri.parse(
        'https://api.giphy.com/v1/gifs/trending?api_key=ZjFSjY5rgEywpQ5WUsqJtKQHtAUlzCIx&limit=10'));

    if (response.statusCode == 200) {
      final apiData = json.decode(response.body)['data'];

      setState(() {
        data = List<Map<String, dynamic>>.from(apiData);
        webpUrls = data
            .map<String>((item) {
              final originalWebpUrl = item['images']['original']['webp'].toString();
              return originalWebpUrl;
            })
            .toList();
      });
    } else {
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
      title: 'Home',
      body: Container(
        color: Color(0xFF1F2732),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(height: 16),
                  Image.asset(
                    'assets/logo.png',
                    height: 100,
                  ),
                  Center(
                    child: Text(
                      'GIF Finder by Alex',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Best Place to Find Your Next Favorite GIF.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Enjoy your sneak peek at the 10 most trending GIFs in the USA.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                      child: Container(
                        color: Colors.white,
                        child: Stack(
                          children: [
                            // Use CachedNetworkImage to load images with a placeholder
                            CachedNetworkImage(
                              imageUrl: webpUrls[index],
                              placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => Icon(Icons.error),
                            ),
                            Positioned(
                              top: 8.0,
                              right: 8.0,
                              child: StarIcon(slug: data[index]['slug'].toString(), imageUrl: webpUrls[index]),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: webpUrls.length,
                ),
              ),
            ),
          ],
        ),
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
          child: FittedBox(
            fit: BoxFit.contain,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.star_border,
                  color:Colors.black,
                  size: 30,
                ),
                Icon(
                  isStarred ? Icons.star : Icons.star_border,
                  color: isStarred ? Color.fromARGB(250, 238, 217, 24) : Colors.orange,
                  size: 20,
                ),
              ],           
            ),
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
  final List<String> ratingOptions = ['G', 'PG', 'PG-13', 'R'];
  Future<List<String>>? giphyDataFuture;
  TextEditingController _searchTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    Page1Data data = Provider.of<Page1Data>(context);
    _searchTextController.text = data.searchText;
    Page3Data page3Data = Provider.of<Page3Data>(context, listen: false);

    OutlineInputBorder customBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
      borderSide: BorderSide(color: Colors.white, width: 2.0),
    );

    return MainLayout(
      title: 'GIF Finder',
      body: Container(
        color: Color(0xFF1F2732),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                    controller: _searchTextController,
                    decoration: InputDecoration(
                      labelText: 'Search Term',
                      labelStyle: TextStyle(color: Colors.white),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        borderSide: BorderSide(color: Colors.white, width: 2.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        borderSide: BorderSide(color: Colors.white, width: 2.0),
                      ),
                    ),
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
                            data.updateSearchText(''); // Set search text to empty
                            _searchTextController.clear();
                            setState(() {
                              giphyDataFuture = null; // Clear the future to show no images
                            });
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
                  if (giphyDataFuture == null) {
                    return Center(child: Text('Press "Search" to find GIFs'));
                  } else if (snapshot.connectionState == ConnectionState.waiting) {
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
                        return GestureDetector(
                          onTap: () {
                            // Handle image tap
                          },
                          child: Container(
                            color: Colors.white, // Set the background color of each grid item
                            child: Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: snapshot.data![index],
                                    placeholder: (context, url) => CircularProgressIndicator(),
                                    errorWidget: (context, url, error) => Icon(Icons.error),
                                  ),
                                  // Other widgets in the stack
                                ],
                              ),
                            ),
                          ),
                        );
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

class Page2 extends StatefulWidget {
  @override
  _Page2State createState() => _Page2State();
}

// Inside the _Page2State class
class _Page2State extends State<Page2> {
  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Favorite GIF\'s',
      body: Consumer<Page2Data>(
        builder: (context, page2Data, _) {
          List<String> webpUrls = page2Data.getFavoritedUrls();
          return Container(
            color: Color(0xFF1F2732),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
                  child: Image.asset(
                    'assets/logo.png',
                    height: 100,
                  ),
                ),
                Expanded(
                  child: CustomScrollView(
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
                              return _buildImageWithLoadingSpinner(context, webpUrls[index]);
                            },
                            childCount: webpUrls.length,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageWithLoadingSpinner(BuildContext context, String imageUrl) {
    return FutureBuilder(
      future: _loadImage(imageUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingSpinner();
        } else if (snapshot.hasError) {
          return _buildErrorWidget();
        } else {
          return GestureDetector(
            onTap: () {
              _showImageDialog(context, imageUrl);
            },
            child: Container(
              color: Colors.white, // Set the background color of each grid item
              child: Stack(
                children: [
                  Image.network(imageUrl),
                  Positioned(
                    top: 8.0,
                    right: 8.0,
                    child: StarIcon(slug: Provider.of<Page2Data>(context).getSlugForUrl(imageUrl), imageUrl: imageUrl),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildLoadingSpinner() {
    return Container(
      color: Colors.white, // Set the background color
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Icon(
        Icons.error,
        color: Colors.red,
        size: 40,
      ),
    );
  }

  Future<void> _loadImage(String imageUrl) async {
    // Simulate loading time (replace this with your actual image loading logic)
    await Future.delayed(Duration(seconds: 2));
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
      title: 'Your GIF History',
      body: Consumer<Page3Data>(
        builder: (context, page3Data, _) {
          return Container(
            color: Color(0xFF1F2732),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 16),
                Image.asset(
                  'assets/logo.png',
                  height: 100,
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: page3Data.searchHistory.length,
                    itemBuilder: (context, index) {
                      var entry = page3Data.searchHistory[index];
                      return Card(
                        color: Colors.blue, // Set your desired background color
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                          title: Text('${entry.searchText} GIF\'s'),
                          children: [
                            ListTile(
                              leading: Image.asset('assets/logo.png'), // Replace with your logo image
                              title: Text('Label for the expandable menu'),
                            ),
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
              child: _buildMenuItem('GIF Finder', () => _navigateToPage(context, Page1())),
            ),
            Divider(color: Colors.black),
            Container(
              margin: EdgeInsets.only(top: 10),
              child: _buildMenuItem('Favorite GIF\'s', () => _navigateToPage(context, Page2())),
            ),
            Divider(color: Colors.black),
            Container(
              margin: EdgeInsets.only(top: 10),
              child: _buildMenuItem('Your GIF History', () => _navigateToPage(context, Page3())),
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
