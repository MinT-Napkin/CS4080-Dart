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
  final List<List<Map<String, dynamic>>> _pages = [];
  final PageController _pageController = PageController();
  bool _isLoading = false;
  int _currentPage = 0;
  final int _limit = 20;

  String? _selectedGeneration;
  String? _selectedType;

  final List<String> _generations = ['1', '2', '3', '4', '5', '6', '7', '8'];
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
  }

  Future<void> _fetchPokemon({int page = 0}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final int offset = page * _limit;
      final String filter = _getFilterQuery();
      final String url =
          'https://pokeapi.co/api/v2/pokemon?offset=$offset&limit=$_limit$filter';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Map<String, dynamic>> newPokemon = (data['results'] as List)
            .map((poke) => {
                  'name': poke['name'],
                  'url': poke['url'],
                })
            .toList();

        if (newPokemon.isNotEmpty) {
          setState(() {
            if (_pages.length <= page) {
              _pages.add(newPokemon);
            } else {
              _pages[page] = newPokemon;
            }
          });
        }
      }
    } catch (error) {
      print('Error fetching Pokémon: $error');
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

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });

    if (page >= _pages.length) {
      _fetchPokemon(page: page);
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: _selectedGeneration,
                  hint: const Text('Generation'),
                  onChanged: (value) {
                    setState(() {
                      _selectedGeneration = value;
                      _pages.clear();
                      _currentPage = 0;
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
                      _pages.clear();
                      _currentPage = 0;
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
          // Pokémon Cards and Navigation Arrows
          Expanded(
            child: Column(
              children: [
                Flexible(
                  child: _pages.isEmpty && _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : PageView.builder(
                          controller: _pageController,
                          onPageChanged: _onPageChanged,
                          itemBuilder: (context, index) {
                            if (index >= _pages.length) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            final List<Map<String, dynamic>> pagePokemon =
                                _pages[index];

                            return GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 5,
                                childAspectRatio: 1,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: pagePokemon.length,
                              itemBuilder: (context, idx) {
                                final pokemon = pagePokemon[idx];
                                return Card(
                                  elevation: 2,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        pokemon['name']
                                            .toString()
                                            .toUpperCase(),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
                // Navigation Arrows
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _currentPage > 0 ? _goToPreviousPage : null,
                        icon: const Icon(Icons.arrow_back),
                      ),
                      Text('Page ${_currentPage + 1}'),
                      IconButton(
                        onPressed: _currentPage < _pages.length - 1
                            ? _goToNextPage
                            : null,
                        icon: const Icon(Icons.arrow_forward),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
