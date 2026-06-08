import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class OsmLocationPicker extends StatefulWidget {
  final double? initLat;
  final double? initLng;
  final Function(double lat, double lng) onPicked;

  const OsmLocationPicker({
    super.key,
    this.initLat,
    this.initLng,
    required this.onPicked,
  });

  @override
  State<OsmLocationPicker> createState() => _OsmLocationPickerState();
}

class _OsmLocationPickerState extends State<OsmLocationPicker> {
  late final MapController _mapController;
  LatLng? _pickedPosition;

  static const LatLng _defaultDaNang = LatLng(16.047079, 108.20623);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    if (widget.initLat != null && widget.initLng != null) {
      _pickedPosition = LatLng(widget.initLat!, widget.initLng!);
    } else {
      _pickedPosition = _defaultDaNang;
    }
  }

  @override
  void didUpdateWidget(covariant OsmLocationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    final hasChanged =
        widget.initLat != oldWidget.initLat || widget.initLng != oldWidget.initLng;

    if (!hasChanged) return;

    if (widget.initLat != null && widget.initLng != null) {
      final newPos = LatLng(widget.initLat!, widget.initLng!);

      setState(() {
        _pickedPosition = newPos;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.move(newPos, 15.0);
      });
    }
  }

  void _pickPosition(LatLng point) {
    setState(() {
      _pickedPosition = point;
    });

    widget.onPicked(point.latitude, point.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final currentPosition = _pickedPosition ?? _defaultDaNang;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Tọa độ: ${currentPosition.latitude.toStringAsFixed(5)}, '
                '${currentPosition.longitude.toStringAsFixed(5)}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ),

        Container(
          height: 300,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: currentPosition,
              initialZoom: 13.0,
              onTap: (tapPosition, point) {
                _pickPosition(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',


                userAgentPackageName: 'com.vuongdinhquochiep.minie',

                maxNativeZoom: 19,
              ),

              MarkerLayer(
                markers: [
                  Marker(
                    point: currentPosition,
                    width: 42,
                    height: 42,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 42,
                    ),
                  ),
                ],
              ),

              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}