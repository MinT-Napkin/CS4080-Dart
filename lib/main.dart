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
  final int _pages = 5; // Total pages
  final PageController _pageController = PageController();
  final int _limit = 20; // Pokémon per page

  int _currentPage = 0;
  bool _isLoading = false;
  List<List<Map<String, dynamic>>> _pokemonPages = List.filled(5, []);

  @override
  void initState() {
    super.initState();
    _fetchPokemon(page: 0); // Fetch first page initially
  }

  Future<void> _fetchPokemon({required int page}) async {
    if (_isLoading || _pokemonPages[page].isNotEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final int offset = page * _limit;
      final url =
          'https://pokeapi.co/api/v2/pokemon/?limit=$_limit&offset=$offset';
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
          _pokemonPages[page] = newPokemon;
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

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _fetchPokemon(page: page);
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
    if (_currentPage < _pages - 1) {
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
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _pages,
              itemBuilder: (context, index) {
                final pagePokemon = _pokemonPages[index];

                if (pagePokemon.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                      child: Center(
                        child: Text(
                          pokemon['name'].toString().toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _currentPage > 0 ? _goToPreviousPage : null,
                  icon: const Icon(Icons.arrow_back),
                ),
                Text('Page ${_currentPage + 1} / $_pages'),
                IconButton(
                  onPressed: _currentPage < _pages - 1 ? _goToNextPage : null,
                  icon: const Icon(Icons.arrow_forward),
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
