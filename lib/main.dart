import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

final title = 'Startup name generator';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      home: RandomWords(),
      theme: ThemeData(primaryColor: Colors.white),
    );
  }
}

class RandomWords extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new RandomWordsState();
}

class RandomWordsState extends State<RandomWords> {
  final _suggestions = <String>[];
  final _saved = new Set<String>();
  final _biggerFont = const TextStyle(fontSize: 18.0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: <Widget>[
        new IconButton(
          icon: const Icon(Icons.list),
          onPressed: _pushSaved,
        )
      ]),
      body: _buildSuggestions(),
    );
  }

  Widget _buildSuggestions() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemBuilder: (context, i) {
        if (i.isOdd) return Divider();

        final index = i ~/ 2;
        if (index >= _suggestions.length) {
          _suggestions.addAll(generateWordPairs().take(10).where((WordPair p) {
            return !_suggestions.contains(p.asPascalCase);
          }).map((WordPair p) {
            return p.asPascalCase;
          }));
        }

        return _buildRow(_suggestions[index]);
      },
    );
  }

  Widget _buildRow(String suggestion) {
    final alreadySaved = _saved.contains(suggestion);

    return ListTile(
      title: Text(
        suggestion,
        style: _biggerFont,
      ),
      trailing: new Icon(
        alreadySaved ? Icons.favorite : Icons.favorite_border,
        color: alreadySaved ? Colors.red : null,
      ),
      onTap: () {
        setState(() {
          if (alreadySaved) {
            _saved.remove(suggestion);
          } else {
            _saved.add(suggestion);
          }
          _updatePrefs();
        });
      },
    );
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final suggestionsSaved = prefs.getStringList("suggestions_saved");
    _saved.addAll(suggestionsSaved);
    _suggestions.addAll(suggestionsSaved);
  }

  _updatePrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList("suggestions_saved", _saved.toList());
  }

  void _pushSaved() {
    Navigator.of(context).push(new MaterialPageRoute(
        builder: (BuildContext context) => new SearchSaved()));
  }
}

class SearchSaved extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new SearchSavedState();
}

class SearchSavedState extends State<SearchSaved> {
  Widget appBarTitle = new Text(
    "Search Example",
  );

  Icon icon = new Icon(
    Icons.search,
  );

  final globalKey = new GlobalKey<ScaffoldState>();
  final TextEditingController _controller = new TextEditingController();
  bool _isSearching;
  String _searchText = "";
  List searchresult = new List();
  var _saved = new List<String>();
  final _biggerFont = const TextStyle(fontSize: 18.0);

  SearchSavedState() {
    _controller.addListener(() {
      if (_controller.text.isEmpty) {
        setState(() {
          _isSearching = false;
          _searchText = "";
        });
      } else {
        setState(() {
          _isSearching = true;
          _searchText = _controller.text;
        });
      }
    });
  }

  @override
  void initState() {
    _loadSaved();
    _isSearching = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Iterable<ListTile> tiles = searchresult.map((dynamic pair) {
      return new ListTile(
        title: new Text(
          pair,
          style: _biggerFont,
        ),
      );
    });

    final List<Widget> divided = ListTile.divideTiles(
      context: context,
      tiles: tiles,
    ).toList();

    return new Scaffold(
      appBar: buildAppBar(context),
      body: new ListView(
        children: divided,
      ),
    );
  }

  _loadSaved() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      this._saved = prefs.getStringList('suggestions_saved');
      searchresult.addAll(_saved);
    });
  }

  Widget buildAppBar(BuildContext context) {
    return new AppBar(centerTitle: true, title: appBarTitle, actions: <Widget>[
      new IconButton(
        icon: icon,
        onPressed: () {
          setState(() {
            if (this.icon.icon == Icons.search) {
              this.icon = new Icon(Icons.close);
              this.appBarTitle = new TextField(
                controller: _controller,
                autofocus: true,
                decoration: new InputDecoration(
                  prefixIcon: new Icon(Icons.search),
                  hintText: "Search...",
                ),
                onChanged: searchOperation,
              );
              _handleSearchStart();
            } else {
              _handleSearchEnd();
            }
          });
        },
      ),
    ]);
  }

  void _handleSearchStart() {
    setState(() {
      _isSearching = true;
    });
  }

  void _handleSearchEnd() {
    setState(() {
      this.icon = new Icon(
        Icons.search,
      );
      this.appBarTitle = new Text(
        "Search Sample",
      );
      _isSearching = false;
      _controller.clear();
    });
  }

  void searchOperation(String searchText) {
    if (searchText == null || searchText == "") {
      searchresult.addAll(_saved);
    } else {
      searchresult.clear();
      if (_isSearching != null) {
        for (int i = 0; i < _saved.length; i++) {
          String data = _saved.toList()[i];
          if (data.toLowerCase().contains(searchText.toLowerCase())) {
            searchresult.add(data);
          }
        }
      }
    }
  }
}
