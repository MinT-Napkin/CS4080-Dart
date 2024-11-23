import 'package:flutter/material.dart';
import 'dart:convert'; // For JSON decoding
import 'package:http/http.dart' as http;

void main() {
  runApp(const PokeApp());
}

class PokeApp extends StatelessWidget {
  const PokeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokémon Browser',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const PokeHomePage(),
    );
  }
}

class PokeHomePage extends StatefulWidget {
  const PokeHomePage({super.key});

  @override
  State<PokeHomePage> createState() => _PokeHomePageState();
}

class _PokeHomePageState extends State<PokeHomePage> {
  final List<Map<String, dynamic>> _pokemonList = [];
  final ScrollController _scrollController = ScrollController();
  int _currentOffset = 0;
  final int _limit = 20;
  bool _isLoading = false;

  String? _selectedGeneration;
  String? _selectedType;

  final List<String> _generations = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
  ];
  final List<String> _types = [
    'normal',
    'fire',
    'water',
    'grass',
    'electric',
    'ice',
    'fighting',
    'poison',
    'ground',
    'flying',
    'psychic',
    'bug',
    'rock',
    'ghost',
    'dragon',
    'dark',
    'steel',
    'fairy',
  ];

  @override
  void initState() {
    super.initState();
    _fetchPokemon();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent &&
        !_isLoading) {
      _fetchPokemon();
    }
  }

  Future<void> _fetchPokemon() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String filter = _getFilterQuery();
      final String url =
          'https://pokeapi.co/api/v2/pokemon?offset=$_currentOffset&limit=$_limit$filter';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Map<String, dynamic>> newPokemon = (data['results'] as List)
            .map((poke) => {
                  'name': poke['name'],
                  'url': poke['url'],
                })
            .toList();

        setState(() {
          _pokemonList.addAll(newPokemon);
          _currentOffset += _limit;
        });
      }
    } catch (error) {
      // Handle errors (e.g., show a SnackBar or error message)
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getFilterQuery() {
    String filter = '';
    if (_selectedGeneration != null) {
      filter += '&generation=${_selectedGeneration}';
    }
    if (_selectedType != null) {
      filter += '&type=${_selectedType}';
    }
    return filter;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokémon Browser'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: _selectedGeneration,
                  hint: const Text('Generation'),
                  onChanged: (value) {
                    setState(() {
                      _selectedGeneration = value;
                      _pokemonList.clear();
                      _currentOffset = 0;
                      _fetchPokemon();
                    });
                  },
                  items: _generations.map((gen) {
                    return DropdownMenuItem(
                      value: gen,
                      child: Text('Gen $gen'),
                    );
                  }).toList(),
                ),
                DropdownButton<String>(
                  value: _selectedType,
                  hint: const Text('Type'),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value;
                      _pokemonList.clear();
                      _currentOffset = 0;
                      _fetchPokemon();
                    });
                  },
                  items: _types.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              controller: _scrollController,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                childAspectRatio: 1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _pokemonList.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _pokemonList.length) {
                  return const Center(child: CircularProgressIndicator());
                }
                final pokemon = _pokemonList[index];
                return Card(
                  elevation: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        pokemon['name'].toString().toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
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
  }
}
