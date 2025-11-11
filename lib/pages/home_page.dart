import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


// Modèle pour une pharmacie
class Pharmacy {
  final String id;
  final String name;
  final LatLng position;
  final String? address;
  final String? phone;
  final String? openingHours;
  final double distance;

  Pharmacy({
    required this.id,
    required this.name,
    required this.position,
    this.address,
    this.phone,
    this.openingHours,
    required this.distance,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  LatLng? userPosition;
  bool isLoading = true;
  bool isLoadingPharmacies = false;
  String? errorMessage;
  final MapController mapController = MapController();
  List<Pharmacy> pharmacies = [];
  Pharmacy? selectedPharmacy;
  double searchRadius = 3000; // Rayon de recherche en mètres (3km)
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          errorMessage = 'Service de localisation désactivé.\nActivez le GPS.';
          isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            errorMessage = 'Permission de localisation refusée.';
            isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          errorMessage =
          'Permission refusée définitivement.\nAllez dans les paramètres.';
          isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        userPosition = LatLng(position.latitude, position.longitude);
        isLoading = false;
      });

      // Charger les pharmacies automatiquement
      await _loadNearbyPharmacies();
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  // Fonction pour interroger l'API Overpass (OpenStreetMap)
  Future<void> _loadNearbyPharmacies() async {
    if (userPosition == null) return;

    setState(() {
      isLoadingPharmacies = true;
    });

    try {
      // Requête Overpass pour trouver les pharmacies
      final query = '''
[out:json][timeout:25];
(
  node["amenity"="pharmacy"](around:$searchRadius,${userPosition!.latitude},${userPosition!.longitude});
  way["amenity"="pharmacy"](around:$searchRadius,${userPosition!.latitude},${userPosition!.longitude});
  relation["amenity"="pharmacy"](around:$searchRadius,${userPosition!.latitude},${userPosition!.longitude});
);
out body;
>;
out skel qt;
''';

      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: query,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List elements = data['elements'];

        List<Pharmacy> loadedPharmacies = [];

        for (var element in elements) {
          if (element['type'] == 'node' && element['tags'] != null) {
            final tags = element['tags'];
            final lat = element['lat'];
            final lon = element['lon'];

            if (lat != null && lon != null) {
              final pharmacyPos = LatLng(lat, lon);

              // Calculer la distance
              final distance = Geolocator.distanceBetween(
                userPosition!.latitude,
                userPosition!.longitude,
                lat,
                lon,
              );

              loadedPharmacies.add(Pharmacy(
                id: element['id'].toString(),
                name: tags['name'] ?? 'Pharmacie sans nom',
                position: pharmacyPos,
                address: tags['addr:street'] ?? tags['addr:full'],
                phone: tags['phone'] ?? tags['contact:phone'],
                openingHours: tags['opening_hours'],
                distance: distance,
              ));
            }
          }
        }

        // Trier par distance (plus proche en premier)
        loadedPharmacies.sort((a, b) => a.distance.compareTo(b.distance));

        setState(() {
          pharmacies = loadedPharmacies;
          isLoadingPharmacies = false;
        });

        if (pharmacies.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Aucune pharmacie trouvée dans un rayon de ${(searchRadius/1000).toStringAsFixed(1)} km'),
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Élargir',
                onPressed: () {
                  setState(() {
                    searchRadius += 2000;
                  });
                  _loadNearbyPharmacies();
                },
              ),
            ),
          );
        } else {
          // Ouvrir automatiquement le BottomSheet
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_sheetController.isAttached) {
              _sheetController.animateTo(
                0.4, // Ouvre à 40% de la hauteur
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
              );
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(' ${pharmacies.length} pharmacie(s) trouvée(s)'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 250, left: 16, right: 16),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        isLoadingPharmacies = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de chargement: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _centerOnUserPosition() {
    if (userPosition != null) {
      mapController.move(userPosition!, 15.0);
      setState(() {
        selectedPharmacy = null;
      });
    }
  }

  void _centerOnPharmacy(Pharmacy pharmacy) {
    mapController.move(pharmacy.position, 17.0);
    setState(() {
      selectedPharmacy = pharmacy;
    });
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pharmacies à Proximité', style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold,color: Colors.teal)),
            if (pharmacies.isNotEmpty)
              Text(
                '${pharmacies.length} pharmacie(s) - Rayon ${(searchRadius/1000).toStringAsFixed(1)} km',
                style: const TextStyle(fontSize: 11),
              ),
          ],
        ),
        backgroundColor: Colors.grey[300],
        actions: [
          if (userPosition != null) ...[
            IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: _centerOnUserPosition,
              tooltip: 'Ma position',
            ),
            PopupMenuButton<double>(
              icon: const Icon(Icons.tune),
              tooltip: 'Rayon de recherche',
              onSelected: (radius) {
                setState(() {
                  searchRadius = radius;
                });
                _loadNearbyPharmacies();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 1000,
                  child: Text('1 km'),
                ),
                const PopupMenuItem(
                  value: 2000,
                  child: Text('2 km'),
                ),
                const PopupMenuItem(
                  value: 3000,
                  child: Text('3 km'),
                ),
                const PopupMenuItem(
                  value: 5000,
                  child: Text('5 km'),
                ),
                const PopupMenuItem(
                  value: 10000,
                  child: Text('10 km'),
                ),
              ],
            ),
          ],
        ],
      ),
      body: _buildBody(),
      floatingActionButton: userPosition != null
          ? FloatingActionButton(
        onPressed: isLoadingPharmacies ? null : _loadNearbyPharmacies,
        tooltip: 'Rechercher les pharmacies',
        backgroundColor: isLoadingPharmacies ? Colors.grey : null,
        child: isLoadingPharmacies
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Icon(Icons.search),
      )
          : null,
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Localisation en cours...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_off,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 20),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  setState(() {
                    isLoading = true;
                    errorMessage = null;
                  });
                  await _getUserLocation();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (userPosition == null) {
      return const Center(
        child: Text('Position introuvable'),
      );
    }

    return Stack(
      children: [
        // Carte
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: userPosition!,
            initialZoom: 15.0,
            minZoom: 3.0,
            maxZoom: 18.0,
            onTap: (_, __) {
              setState(() {
                selectedPharmacy = null;
              });
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.koko',
            ),
            // Cercle de recherche
            CircleLayer(
              circles: [
                CircleMarker(
                  point: userPosition!,
                  radius: searchRadius,
                  useRadiusInMeter: true,
                  color: Colors.blue.withOpacity(0.08),
                  borderColor: Colors.blue.withOpacity(0.3),
                  borderStrokeWidth: 2,
                ),
              ],
            ),
            // Markers
            MarkerLayer(
              markers: [
                // Position de l'utilisateur
                Marker(
                  point: userPosition!,
                  width: 100,
                  height: 100,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Vous',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Icon(
                        Icons.person_pin_circle,
                        color: Colors.blue,
                        size: 45,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Pharmacies
                ...pharmacies.asMap().entries.map((entry) {
                  final index = entry.key;
                  final pharmacy = entry.value;
                  final isSelected = selectedPharmacy?.id == pharmacy.id;

                  return Marker(
                    point: pharmacy.position,
                    width: isSelected ? 120 : 90,
                    height: isSelected ? 120 : 90,
                    child: GestureDetector(
                      onTap: () {
                        _centerOnPharmacy(pharmacy);
                      },
                      child: Column(
                        children: [
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    pharmacy.name,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    _formatDistance(pharmacy.distance),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.local_pharmacy,
                                color: isSelected ? Colors.red : Colors.green,
                                size: isSelected ? 55 : 45,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              if (index < 3 && !isSelected)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),

        // BottomSheet persistant avec la liste des pharmacies
        if (pharmacies.isNotEmpty)
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.15, // Commence petit
            minChildSize: 0.15,
            maxChildSize: 0.75,
            snap: true,
            snapSizes: const [0.15, 0.4, 0.75], // Points d'accroche
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Poignée pour glisser avec animation
                    GestureDetector(
                      onTap: () {
                        // Toggle entre mini et moyen
                        if (_sheetController.size < 0.3) {
                          _sheetController.animateTo(
                            0.4,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        } else {
                          _sheetController.animateTo(
                            0.15,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        color: Colors.transparent,
                        child: Center(
                          child: Container(
                            width: 50,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // En-tête avec effet visuel
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade50, Colors.white],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.local_pharmacy,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pharmacies trouvées',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${pharmacies.length} à proximité • Triées par distance',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isLoadingPharmacies)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${pharmacies.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Liste des pharmacies
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: pharmacies.length,
                        padding: const EdgeInsets.only(bottom: 16),
                        itemBuilder: (context, index) {
                          final pharmacy = pharmacies[index];
                          final isSelected = selectedPharmacy?.id == pharmacy.id;

                          return Container(
                            color: isSelected ? Colors.green.withOpacity(0.1) : null,
                            child: ListTile(
                              leading: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: isSelected ? Colors.red : Colors.green,
                                    child: const Icon(
                                      Icons.local_pharmacy,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  if (index < 3)
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: Colors.orange,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 1),
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              title: Text(
                                pharmacy.name,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.navigation,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDistance(pharmacy.distance),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (pharmacy.address != null) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 12,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            pharmacy.address!,
                                            style: const TextStyle(fontSize: 11),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (pharmacy.phone != null) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone,
                                          size: 12,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          pharmacy.phone!,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey[400],
                              ),
                              onTap: () => _centerOnPharmacy(pharmacy),
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

        // Indicateur de chargement
        if (isLoadingPharmacies)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Recherche en cours...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}