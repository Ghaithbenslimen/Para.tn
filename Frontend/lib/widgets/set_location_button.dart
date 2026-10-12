import 'package:flutter/material.dart';
import '../services/location_service.dart';

class SetLocationButton extends StatefulWidget {
  final bool isParapharmacy;
  final Function(double latitude, double longitude, String address)?
      onLocationUpdated;
  final double? initialLatitude;
  final double? initialLongitude;

  const SetLocationButton({
    Key? key,
    required this.isParapharmacy,
    this.onLocationUpdated,
    this.initialLatitude,
    this.initialLongitude,
  }) : super(key: key);

  @override
  _SetLocationButtonState createState() => _SetLocationButtonState();
}

class _SetLocationButtonState extends State<SetLocationButton> {
  bool _isLoading = false;
  bool _showManualEntry = false;
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Initialize controllers with initial values if provided
    if (widget.initialLatitude != null) {
      _latController.text = widget.initialLatitude!.toString();
    }
    if (widget.initialLongitude != null) {
      _lngController.text = widget.initialLongitude!.toString();
    }
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  // Get current location automatically
  Future<void> _setLocationAutomatically() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final locationData = await LocationService.getCurrentLocation(context);

      if (locationData != null) {
        final latitude = locationData['latitude'] as double;
        final longitude = locationData['longitude'] as double;
        final address = locationData['address'] as String;

        // Update controllers
        _latController.text = latitude.toString();
        _lngController.text = longitude.toString();

        bool success;
        if (widget.isParapharmacy) {
          success = await LocationService.updateParapharmacyLocation(
              latitude, longitude);
        } else {
          success = await LocationService.updateUserLocation(
              latitude, longitude, address);
        }

        if (success) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location updated successfully'),
              backgroundColor: Colors.green,
            ),
          );

          if (widget.onLocationUpdated != null) {
            widget.onLocationUpdated!(latitude, longitude, address);
          }
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update location'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Set location manually
  Future<void> _setLocationManually() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final latitude = double.parse(_latController.text);
      final longitude = double.parse(_lngController.text);

      // Try to get address from coordinates
      String address = '';
      final fetchedAddress = await LocationService.getAddressFromCoordinates(
          latitude, longitude, context);
      if (fetchedAddress != null) {
        address = fetchedAddress;
      }

      bool success;
      if (widget.isParapharmacy) {
        success = await LocationService.updateParapharmacyLocation(
            latitude, longitude);
      } else {
        success = await LocationService.updateUserLocation(
            latitude, longitude, address);
      }

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        if (widget.onLocationUpdated != null) {
          widget.onLocationUpdated!(latitude, longitude, address);
        }

        setState(() {
          _showManualEntry = false;
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update location'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_showManualEntry)
          Form(
            key: _formKey,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latController,
                        decoration: InputDecoration(
                          labelText: 'Latitude',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter latitude';
                          }
                          try {
                            final lat = double.parse(value);
                            if (lat < -90 || lat > 90) {
                              return 'Latitude must be between -90 and 90';
                            }
                          } catch (e) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _lngController,
                        decoration: InputDecoration(
                          labelText: 'Longitude',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter longitude';
                          }
                          try {
                            final lng = double.parse(value);
                            if (lng < -180 || lng > 180) {
                              return 'Longitude must be between -180 and 180';
                            }
                          } catch (e) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _setLocationManually,
                        icon: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(Icons.save),
                        label: Text('Save Coordinates'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _showManualEntry = false;
                              });
                            },
                      child: Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _setLocationAutomatically,
                  icon: _isLoading
                      ? Container(
                          width: 24,
                          height: 24,
                          padding: const EdgeInsets.all(2.0),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(_isLoading
                      ? 'Getting Location...'
                      : 'Get Current Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _showManualEntry = true;
                          });
                        },
                  icon: const Icon(Icons.edit_location_alt),
                  label: Text('Enter Coordinates Manually'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.green),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
