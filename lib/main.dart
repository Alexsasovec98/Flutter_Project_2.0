//importing packages
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initPathProvider();
  runApp(
    //setting all the needed providers
      MultiProvider(
        providers: [
          ChangeNotifierProvider<GIFFinderData>(
            create: (context) => GIFFinderData(),
          ),
          ChangeNotifierProvider<FavoritesPageData>(
            create: (context) => FavoritesPageData(),
          ),
          ChangeNotifierProvider<HistoryPageData>(
            create: (context) => HistoryPageData(),
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
      home: HomePage(),
    );
  }
}

//This class is used to keep and timely update data in search fields for GIF Finder page
class GIFFinderData extends ChangeNotifier {
  String searchTextData = ''; // Default "search term" option
  int numerOfGifsData = 5; // Default "number of gif's" option
  String ageRestrictionData = 'G'; // Default "age restriction" option

  //timely updating data in fields
  void updateSearchText(String text) {
    searchTextData = text;
    notifyListeners();
  }

  void updateNumberOfGifsData(int limit) {
    numerOfGifsData = limit;
    notifyListeners();
  }

  void updateRatingOption(String rating) {
    ageRestrictionData = rating;
    notifyListeners();
  }
}

//This class is used to keep all needed data for Favorites Page
//If we star image on Home Page or Gif Finder Page - that image is displayed on this page with star filled.
//If unstarred - image disappears from the page and star is not filled on all the pages
class FavoritesPageData extends ChangeNotifier {
  Map<String, String> favoritedUrls = {};

  void updateStarState(String slug, bool isFilled, String imageUrl) {
    favoritedUrls[slug] = isFilled ? imageUrl : ''; // Save or remove the imageUrl based on star state
    notifyListeners();
  }

  //getting data from saved
  List<String> getFavoritedUrls() {
    return favoritedUrls.values.where((url) => url.isNotEmpty).toList();
  }

  String getSlugForUrl(String imageUrl) {
    for (var entry in favoritedUrls.entries) {
      if (entry.value == imageUrl) {
        return entry.key;
      }
    }
    return ''; //returning appropriate default value if no match is found
  }
}

//This class is used to keep all needed data for Favorites Page
class HistoryPageData extends ChangeNotifier {
  List<HistoryData> searchHistory = [];

  void updateHistory(HistoryData history) {
    searchHistory.add(history);
    notifyListeners();
  }
}

//we are getting all the data saved in GIF Finder page
class HistoryData {
  final String searchText;
  final int limitOption;  
  final String ratingOption;  
  List<String> webpUrls; 

  HistoryData({
    required this.searchText,
    required this.limitOption,
    required this.ratingOption,
    required this.webpUrls,
  });
}

//This class is used to set-up Star Icon that is used for favoriting GIF's
class StarIcon extends StatelessWidget {
  final String slug;
  final String imageUrl;

  const StarIcon({required this.slug, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesPageData>(
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

//global layout
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

//side menu
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
              margin: EdgeInsets.only(top: 30),
              child: _buildMenuItem('Home', () => _navigateToPage(context, HomePage())),
            ),
            Divider(color: Colors.black),
            Container(
              child: _buildMenuItem('GIF Finder', () => _navigateToPage(context, GIFFinderPage())),
            ),
            Divider(color: Colors.black),
            Container(
              child: _buildMenuItem('Favorite GIF\'s', () => _navigateToPage(context, FavoritesPage())),
            ),
            Divider(color: Colors.black),
            Container(
              child: _buildMenuItem('Your GIF History', () => _navigateToPage(context, HistoryPage())),
            ),
            Divider(color: Colors.black),
            Container(
              child: _buildMenuItem('Documentation', () => _navigateToPage(context, DocumentationPage())),
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

//class that sets the Home Page
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> webpUrls = [];
  List<Map<String, dynamic>> data = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  //fetching data from api
  Future<void> fetchData() async {
    final response = await http.get(Uri.parse(
        'https://api.giphy.com/v1/gifs/trending?api_key=ZjFSjY5rgEywpQ5WUsqJtKQHtAUlzCIx&limit=10'));

    if (response.statusCode == 200) {
      final apiData = json.decode(response.body)['data'];

      setState(() {
        //filling data
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

  //home page layout
  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Home',
      body: Container(
        color: Color(0xFF1F2732),
        child: CustomScrollView(
          //I had an issue with layout when I was trying to have logo on top and gridview under it
          //Google suggested to use slivers and that solved the error
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(height: 16),
                  Image.asset(
                    'assets/logo.png',
                    height: 100,
                  ),
                  //centered texts
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
            //SliverGrid is used to have grid layout for trending GIF's
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
                        //pop-up happens when gif is tapped
                        _showImageDialog(webpUrls[index], data[index]['slug'].toString());
                      },
                      child: Container(
                        color: Colors.white,
                        child: Stack(
                          children: [
                            //using CachedNetworkImage to load images
                            CachedNetworkImage(
                              imageUrl: webpUrls[index],
                              //spinner that shows progress of gif loading
                              placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => Icon(Icons.error),
                            ),
                            //star icon appearing in the top right corner that can be used to favorite/unfavorite GIF's
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

class GIFFinderPage extends StatefulWidget {
  @override
  _GIFFinderPageState createState() => _GIFFinderPageState();
}

class _GIFFinderPageState extends State<GIFFinderPage> {
  //setting data for page options
  final List<int> limitOptions = [5, 10, 15, 20];
  final List<String> ratingOptions = ['G', 'PG', 'PG-13', 'R'];
  Future<List<String>>? giphyDataFuture;
  TextEditingController _searchTextController = TextEditingController();
  var offset = 0;

  //getting needed data
  @override
  Widget build(BuildContext context) {
    GIFFinderData data = Provider.of<GIFFinderData>(context);
    _searchTextController.text = data.searchTextData;
    HistoryPageData page3Data = Provider.of<HistoryPageData>(context, listen: false);

    //border setup
    OutlineInputBorder customBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
      borderSide: BorderSide(color: Colors.white, width: 2.0),
    );

    //page layout
    return MainLayout(
      title: 'GIF Finder',
      body: Container(
        color: Color(0xFF1F2732),
        child: Column(
          //centering items
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
                  //main search text field
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
                    //updating term
                    onChanged: (value) {
                      offset = 0;
                      data.updateSearchText(value);
                    },
                  ),
                  SizedBox(height: 16),
                  //row setup for drop downs that are located horizontally and each take 50% of the width(with flex)
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
                              //getting options
                              value: data.numerOfGifsData,
                              items: limitOptions.map((int value) {
                                //listing all the items in drop-down menu
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
                              //updating the drop down chosen option
                              onChanged: (int? newValue) {
                                data.updateNumberOfGifsData(newValue!);
                              },
                              dropdownColor: Color(0xFF1F2732),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      //another drop down
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
                              value: data.ageRestrictionData,
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
                              //updating value
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
                  //setting up both buttons horizontally again
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: ElevatedButton(
                          onPressed: () {
                            // Reset button in action
                            data.updateSearchText('');
                            offset = 0;
                            _searchTextController.clear();
                            setState(() {
                              giphyDataFuture = null;
                            });
                          },
                          child: Text('Reset', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          //seatch button in action
                          onPressed: () async {
                            if (data.searchTextData.isNotEmpty) {
                              setState(() {
                                giphyDataFuture = fetchGiphyData(data.searchTextData, data.numerOfGifsData, data.ageRestrictionData);
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
            //displaying API response below
            Expanded(
              child: FutureBuilder<List<String>>(
                future: giphyDataFuture,
                builder: (context, snapshot) {
                  if (giphyDataFuture == null) 
                  {
                    return Center(child: Text('Press "Search" to find GIFs', style: TextStyle(color: Colors.white),));
                  } 
                  else if (snapshot.connectionState == ConnectionState.waiting) 
                  {
                    return Center(child: CircularProgressIndicator());
                  } 
                  else if (snapshot.hasError)
                  {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } 
                  else if (!snapshot.hasData) 
                  {
                    return Center(child: Text('No data available', style: TextStyle(color: Colors.white),));
                  } 
                  else if(snapshot.data!.isEmpty)
                  {
                    return Center(child: Text('Please Provide Search Term', style: TextStyle(color: Colors.white),));
                  }
                  else 
                  {
                    //displaying fetched images
                    return Column(
                      children: [
                        Expanded(
                          //gridview. here it worked without slivers fsr
                          child: GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 8.0,
                              mainAxisSpacing: 8.0,
                            ),
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  //will handle action
                                },
                                child: Container(
                                  color: Colors.white,
                                  child: Stack(
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl: snapshot.data![index],
                                        //spinner. using basic one here. I created custom one for another page before, but I did make that local 
                                        //for that page, since I did not think I will need that func in another page. I did not make it global
                                        //It is one small drawback, since the spinner here is located on left top corner. I cant center it since
                                        //it will center star icon as well and I dont need it
                                        placeholder: (context, url) => CircularProgressIndicator(),
                                        errorWidget: (context, url, error) => Icon(Icons.error),
                                      ),
                                      //star for favoriting items
                                      Positioned(
                                        top: 8.0,
                                        right: 8.0,
                                        child: StarIcon(slug: snapshot.data![index].toString(), imageUrl: snapshot.data![index]),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        //this checks if there are any current GIF's on the page so GetMore button is possible
                        if (snapshot.data!.isNotEmpty)
                          ElevatedButton(
                            onPressed: () async {
                              if (data.searchTextData.isNotEmpty) {
                                offset += data.numerOfGifsData;
                                setState(() {
                                  //getting data
                                  giphyDataFuture = fetchGiphyData(data.searchTextData, data.numerOfGifsData, data.ageRestrictionData, offset: offset);
                                });
                              }
                            },
                            child: Text('Get More', style: TextStyle(color: Colors.white)),
                          ),
                      ],
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

  // Fetching specific data from API
  Future<List<String>> fetchGiphyData(String searchText, int limit, String rating, {int offset=0}) async {
    var webpUrls = [];
    int localOffset = 0;
    int maximumLimit = 25;
    do {
      int nextLimit = min(maximumLimit, offset + limit - localOffset);
      final response = await http.get(Uri.parse(
      'https://api.giphy.com/v1/gifs/search?api_key=ZjFSjY5rgEywpQ5WUsqJtKQHtAUlzCIx&q=$searchText&limit=$nextLimit&rating=$rating&offset=$localOffset'));

      if (response.statusCode == 200) {
        final apiData = json.decode(response.body)['data'];

        List<String> webpUrlsTemp = List<String>.from(apiData.map<String>((item) {
          final originalWebpUrl = item['images']['original']['webp'].toString();
          return originalWebpUrl;
        }));

        for (var url in webpUrlsTemp) {
          webpUrls.add(url);
        }
      } else {
        throw Exception('Failed to load data. Error ${response.statusCode}');
      }
      localOffset += webpUrls.length;
    } while (localOffset < offset + limit);
    var list = List<String>.from(webpUrls);
    //setting provider with needed data from search
    Provider.of<HistoryPageData>(context, listen: false).updateHistory(HistoryData(
      searchText: searchText,
      limitOption: limit,
      ratingOption: rating,
      webpUrls: list,
    ));
    return Future.value(list);
  }
}

//setting up Favorites Page
class FavoritesPage extends StatefulWidget {
  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Favorite GIF\'s',
      body: Consumer<FavoritesPageData>(
        builder: (context, page2Data, _) {
          //getting data from provider
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
                    //againg using slivers for correct rendering
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
                              //using that custom GIF display logic widget that I shouldve made global
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

  //custom GIF entry builder 
  Widget _buildImageWithLoadingSpinner(BuildContext context, String imageUrl) {
    return FutureBuilder(
      future: _loadImage(imageUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          //custom spinner for loading
          return _buildLoadingSpinner();
        } else if (snapshot.hasError) {
          return _buildErrorWidget();
        } else {
          return GestureDetector(
            onTap: () {
              _showImageDialog(context, imageUrl);
            },
            //GIF + starIcon
            child: Container(
              color: Colors.white, // Set the background color of each grid item
              child: Stack(
                children: [
                  Image.network(imageUrl),
                  Positioned(
                    top: 8.0,
                    right: 8.0,
                    child: StarIcon(slug: Provider.of<FavoritesPageData>(context).getSlugForUrl(imageUrl), imageUrl: imageUrl),
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
  //popup
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

//setting up History Page
class HistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //History Page Layout
    return MainLayout(
      title: 'Your GIF History',
      body: Consumer<HistoryPageData>(
        builder: (context, page3Data, _) {
          return Container(
            color: Color(0xFF1F2732),
            child: Column(
              children: [
                SizedBox(height: 16),
                Image.asset(
                  'assets/logo.png',
                  height: 100,
                ),
                Expanded(
                  //I had a problem with displaying GIF's inside of the expandable widget, so I found out about 
                  //ListView widget existence and set up those GIF's as a horizontal scroll
                  child: ListView.builder(
                    itemCount: page3Data.searchHistory.length,
                    itemBuilder: (context, index) {
                      //getting data from provider
                      var entry = page3Data.searchHistory[index];
                      return HistoryEntryTile(entry: entry);
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

//classes that is used to make horizontal scrollable line of GIF's for each entry
class HistoryEntryTile extends StatefulWidget {
  final HistoryData entry;

  HistoryEntryTile({required this.entry});

  @override
  _HistoryEntryTileState createState() => _HistoryEntryTileState();
}

class _HistoryEntryTileState extends State<HistoryEntryTile> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          color: Colors.blue,
          child: ListTile(
            title: Text('${widget.entry.searchText} GIF\'s'),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
            ),
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
          ),
        ),
        if (isExpanded) ...[
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.entry.webpUrls.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CachedNetworkImage(
                    imageUrl: widget.entry.webpUrls[index],
                    placeholder: (context, url) => CircularProgressIndicator(),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class DocumentationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Documentation',
      body: Container(
        color: Color(0xFF1F2732),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.png',
                height: 100,
              ),
              SizedBox(height: 16),
              Text(
                'GIF Finder',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Designed and developed by Alexander Karpyuk',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Project 2 is made for IGME-340 class.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              Text(
                'Sources',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.left,
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1. GIF Finder API was used as the API source for this project',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '2. StackOverflow was used as the code help source for this project',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                     Text(
                      '3. YouTube and Resourses channel in Slack were used as the video-code help source for this project',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '4. Paint was used tp create the logo for the app',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
               SizedBox(height: 30),
              Text(
                'Processes',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.left,
              ),
              Container(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1. Decided to pursue minimalistic, eye-pleasing design with mono color that emphisized efficency and purposfulness of the app. The same goes for the font. I decided to use one of the standart fonts, since it is functional and supports official design code for the app',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '2. Some of the code path are included in comments. Want to emphasize that some of the concepts were not showcased enough/not at all in the lectures and resources - had to find a lot of information on the web about usage and mixing of specific widgets. From that happened some inconsistency in code patterns for alike looking situations. One slight difference in the layout and concept stops working. Overall - front end as always a garbage:)',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                     Text(
                      '3. I tried to have slightly different layouts throughout the pages that still resemble the same oficcial look and feel like one application. At the same time different widgets/mixes are used, such as horizontal scroll on the History Page',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '4. Interesting part was with provider and all the pages states. I had to make a system that would allow to fav/unfav from different pages resulting in the update of one page',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '5. Get More is used in a way that it updates the page showing the doubled-up amount of results. I favored it to "next/prev" functionality since I did not find it interesting code-wise and showing more results on the same page without the need to jump between outputs to be more user-friendly. I delibirately left top search part not scrollable so user always has ability to re-search. Each "Get More" call is also saved as a new entry on the history page',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

