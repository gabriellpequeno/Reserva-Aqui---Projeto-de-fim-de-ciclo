import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MyRoomsPage extends StatefulWidget {
  const MyRoomsPage({super.key});

  @override
  State<MyRoomsPage> createState() => _MyRoomsPageState();
}

class _MyRoomsPageState extends State<MyRoomsPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> rooms = [
    {
      'id': '1',
      'name': 'Grand Hotel\nBudapest',
      'image': 'https://placehold.co/161x224/png',
      'amenities': ['wifi', '2 camas', 'café da manhã', 'ar condicionado'],
      'status': 'active',
    },
    {
      'id': '2',
      'name': 'Grand Hotel\nBudapest',
      'image': 'https://placehold.co/161x224/png',
      'amenities': ['wifi', '2 camas', 'café da manhã', 'ar condicionado'],
      'status': 'active',
    },
    {
      'id': '3',
      'name': 'Grand Hotel\nBudapest',
      'image': 'https://placehold.co/161x224/png',
      'amenities': ['café da manhã'],
      'status': 'inactive',
    },
  ];

  List<Map<String, dynamic>> get filteredRooms {
    if (_searchController.text.isEmpty) return rooms;
    return rooms.where((room) {
      final name = room['name'].toString().toLowerCase();
      final query = _searchController.text.toLowerCase();
      return name.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeaderAndSearch(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 16, bottom: 80, left: 16, right: 16),
                  itemCount: filteredRooms.length,
                  itemBuilder: (context, index) {
                    return _buildRoomCard(filteredRooms[index]);
                  },
                ),
              ),
            ],
          ),
          // Floating Adicionar Button
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                height: 40,
                width: 185,
                child: ElevatedButton(
                  onPressed: () {
                    context.push('/add_room');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF19D75), // Soft Orange as in prototype
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                      side: const BorderSide(color: Color(0xFFEC6725)), // Darker orange border
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Adicionar',
                    style: TextStyle(
                      color: Color(0xFF182541), // Dark Blue
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAndSearch() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF182541),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(27),
          bottomRight: Radius.circular(27),
        ),
      ),
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back Button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                  onPressed: () => context.canPop() ? context.pop() : context.go('/profile/host'),
                ),
              ),
              Column(
                children: const [
                  Text(
                    'RESERVAQUI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Meus Quartos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_none, color: Colors.white),
                  onPressed: () => context.go('/notifications'),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Search bar inside the blue header
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(23),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Pesquisar...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                border: InputBorder.none,
                suffixIcon: const Icon(Icons.search, color: Color(0xFFEC6725)), // Orange icon on right
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 224, // Exact height from prototype
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0x3F182541)),
      ),
      child: Row(
        children: [
          // Image Left
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(11),
              bottomLeft: Radius.circular(11),
            ),
            child: Image.network(
              room['image'],
              width: 161,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          // Content Right
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          room['name'],
                          style: const TextStyle(
                            color: Color(0xFF182541),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Edit button
                      GestureDetector(
                        onTap: () => context.push('/edit_room/${room['id']}'),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE8DB),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFEC6725)),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Color(0xFFEC6725),
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Amenities
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: (room['amenities'] as List<String>).map((amenity) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getIconForAmenity(amenity),
                                size: 12,
                                color: const Color(0xFF7F8697),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                amenity,
                                style: const TextStyle(
                                  color: Color(0xFF7F8697),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  // Ver mais button
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton(
                      onPressed: () => context.push('/hotel_details/${room['id']}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF182541),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      child: const Text(
                        'Ver Mais',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForAmenity(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'wifi':
        return Icons.wifi;
      case '2 camas':
      case 'camas':
        return Icons.bed;
      case 'café da manhã':
        return Icons.coffee;
      case 'ar condicionado':
        return Icons.ac_unit;
      default:
        return Icons.check_circle_outline;
    }
  }
}
