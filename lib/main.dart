import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const PokeApp());
}

class PokeApp extends StatelessWidget {
  const PokeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokémon Search',
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
  bool _isLoading = false;
  List<Map<String, dynamic>> _pokemonList = [];

  String? _selectedType;

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
    _fetchPokemon(); // Initial fetch
  }

  Future<void> _fetchPokemon() async {
    setState(() {
      _isLoading = true;
      _pokemonList = []; // Clear the list before fetching
    });

    try {
      String url = 'https://pokeapi.co/api/v2/pokemon/?limit=100';

      // Adjust URL based on filters
      if (_selectedType != null) {
        url = 'https://pokeapi.co/api/v2/type/${_selectedType}';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<Map<String, dynamic>> basePokemon;
        if (_selectedType != null) {
          basePokemon = (data['pokemon'] as List)
              .map((pokeData) => {
                    'name': pokeData['pokemon']['name'],
                    'url': pokeData['pokemon']['url'],
                  })
              .take(100)
              .toList();
        } else {
          basePokemon = (data['results'] as List)
              .map((poke) => {
                    'name': poke['name'],
                    'url': poke['url'],
                  })
              .toList();
        }

        // Fetch detailed Pokémon info
        final detailedPokemon = await Future.wait(
          basePokemon.map((poke) async {
            final details = await _fetchPokemonDetails(poke['url']);
            return {
              'name': poke['name'],
              ...details,
            };
          }),
        );

        setState(() {
          _pokemonList = detailedPokemon;
        });
      }
    } catch (error) {
      print('Error fetching Pokémon: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _fetchPokemonDetails(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'id': data['id'],
          'image': data['sprites']['front_default'],
          'types': (data['types'] as List)
              .map((typeData) => typeData['type']['name'])
              .toList(),
        };
      }
    } catch (error) {
      print('Error fetching Pokémon details: $error');
    }
    return {};
  }

  void _onFilterChanged() {
    _fetchPokemon(); // Fetch Pokémon with the new filter
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
          // Filter Section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DropdownButton<String>(
                  value: _selectedType,
                  hint: const Text('Type'),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value;
                    });
                    _onFilterChanged();
                  },
                  items: _types
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          // Pokémon Cards Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _pokemonList.isEmpty
                    ? const Center(child: Text('No Pokémon found.'))
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          childAspectRatio: 1,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _pokemonList.length,
                        itemBuilder: (context, index) {
                          final pokemon = _pokemonList[index];
                          return Card(
                            elevation: 2,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                pokemon['image'] != null
                                    ? Image.network(
                                        pokemon['image'],
                                        height: 50,
                                        width: 50,
                                      )
                                    : const Icon(Icons.image_not_supported),
                                Text(
                                  pokemon['name'].toString().toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text('ID: ${pokemon['id']}'),
                                Text('Type(s): ${pokemon['types'].join(', ')}'),
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
