import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/vietnam_units.dart';

class VietnamAddressSelector extends StatefulWidget {
  final Function(String fullAddress) onAddressChanged;
  final Function(double? lat, double? lng) onCoordinatesChanged;
  // THÊM: Cho phép truyền controller từ ngoài vào
  final TextEditingController? addressController;

  const VietnamAddressSelector({
    Key? key,
    required this.onAddressChanged,
    required this.onCoordinatesChanged,
    this.addressController,
  }) : super(key: key);

  @override
  State<VietnamAddressSelector> createState() => _VietnamAddressSelectorState();
}

class _VietnamAddressSelectorState extends State<VietnamAddressSelector> {
  List<LocationItem> provinces = [];
  List<LocationItem> districts = [];
  List<LocationItem> wards = [];

  String? selectedProvinceId;
  String? selectedDistrictId;
  String? selectedWardId;

  String provinceName = '';
  String districtName = '';
  String wardName = '';

  // Sử dụng controller được truyền vào hoặc tạo mới
  late TextEditingController _detailController;

  Timer? _debounce;
  List<dynamic> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _detailController = widget.addressController ?? TextEditingController();
    _fetchDivisions('0', 1);
  }

  // --- LOGIC MỚI: TÌM TỌA ĐỘ KHI CHỌN ĐỊA GIỚI HÀNH CHÍNH ---
  Future<void> _searchCoordinateByAddress(String query) async {
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        'q': query,
        'format': 'jsonv2',
        'limit': '1',
        'countrycodes': 'vn',
        'email': 'quochiep1610@gmail.com',
      },
    );

    try {
      final response = await http.get(
        uri,
        headers: const {
          'User-Agent': 'mini-e-fe-app/1.0 (contact: quochiep1610@gmail.com)',
          'Accept': 'application/json',
          'Accept-Language': 'vi',
        },
      );

      debugPrint('Nominatim search status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List && data.isNotEmpty) {
          final lat = double.tryParse(data[0]['lat']?.toString() ?? '');
          final lng = double.tryParse(data[0]['lon']?.toString() ?? '');

          widget.onCoordinatesChanged(lat, lng);
        }
      } else {
        debugPrint('Nominatim search bị chặn/lỗi: ${response.statusCode}');
        debugPrint(response.body);
      }
    } catch (e) {
      debugPrint('Lỗi tìm tọa độ: $e');
    }
  }
  // ------------------------------------------------------------

  Future<void> _fetchDivisions(String parentId, int level) async {
    final url = level == 1
        ? 'https://esgoo.net/api-tinhthanh/1/0.htm'
        : 'https://esgoo.net/api-tinhthanh/$level/$parentId.htm';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['error'] == 0) {
          final List data = body['data'];
          if (mounted) {
            setState(() {
              if (level == 1) provinces = data.map((e) => LocationItem.fromJson(e)).toList();
              if (level == 2) districts = data.map((e) => LocationItem.fromJson(e)).toList();
              if (level == 3) wards = data.map((e) => LocationItem.fromJson(e)).toList();
            });
          }
        }
      }
    } catch (e) {
      print('Lỗi fetch hành chính: $e');
    }
  }

  void _onDetailChanged(String query) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    setState(() {
      _suggestions = [];
      _showSuggestions = false;
    });

    _updateFullAddress();
  }

  void _updateFullAddress() {
    String detail = _detailController.text;
    List<String> parts = [detail, wardName, districtName, provinceName];
    String full = parts.where((s) => s.isNotEmpty).join(', ');
    widget.onAddressChanged(full);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: selectedProvinceId,
          decoration: const InputDecoration(labelText: 'Tỉnh / Thành phố', border: OutlineInputBorder()),
          items: provinces.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
          onChanged: (val) {
            setState(() {
              selectedProvinceId = val;
              provinceName = provinces.firstWhere((e) => e.id == val).name;
              districts = []; wards = [];
              selectedDistrictId = null; selectedWardId = null;
              districtName = ''; wardName = '';
            });
            _fetchDivisions(val!, 2);
            _updateFullAddress();

            // THÊM: Map di chuyển về Tỉnh mới chọn
            _searchCoordinateByAddress(provinceName);
          },
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          value: selectedDistrictId,
          decoration: const InputDecoration(labelText: 'Quận / Huyện', border: OutlineInputBorder()),
          items: districts.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
          onChanged: (val) {
            setState(() {
              selectedDistrictId = val;
              districtName = districts.firstWhere((e) => e.id == val).name;
              wards = []; selectedWardId = null; wardName = '';
            });
            _fetchDivisions(val!, 3);
            _updateFullAddress();

            // THÊM: Map di chuyển về Quận/Huyện mới chọn
            _searchCoordinateByAddress("$districtName, $provinceName");
          },
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          value: selectedWardId,
          decoration: const InputDecoration(labelText: 'Phường / Xã', border: OutlineInputBorder()),
          items: wards.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))).toList(),
          onChanged: (val) {
            setState(() {
              selectedWardId = val;
              wardName = wards.firstWhere((e) => e.id == val).name;
            });
            _updateFullAddress();

            // THÊM: Map di chuyển về Phường/Xã mới chọn
            _searchCoordinateByAddress("$wardName, $districtName, $provinceName");
          },
        ),
        const SizedBox(height: 12),

        Column(
          children: [
            TextFormField(
              controller: _detailController, // Dùng controller đã xử lý
              decoration: const InputDecoration(
                labelText: 'Số nhà, tên đường...',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: _onDetailChanged,
            ),
            if (_showSuggestions && _suggestions.isNotEmpty)
              Container(
                height: 150,
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                child: ListView.builder(
                  itemCount: _suggestions.length,
                  itemBuilder: (ctx, i) {
                    final item = _suggestions[i];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.location_on, size: 16),
                      title: Text(item['display_name'] ?? ''),
                      onTap: () {
                        _detailController.text = item['display_name'].toString().split(',')[0];
                        setState(() => _showSuggestions = false);

                        if (item['lat'] != null && item['lon'] != null) {
                          widget.onCoordinatesChanged(
                              double.tryParse(item['lat']),
                              double.tryParse(item['lon'])
                          );
                        }
                        _updateFullAddress();
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }
}