import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/di/injection.dart';
import 'package:talex_platform/core/location/location_catalog.dart';
import 'package:talex_platform/core/location/location_query.dart';
import 'package:talex_platform/core/widgets/searchable_select.dart';
import 'package:talex_platform/l10n/l10n.dart';

class LocationValue {
  const LocationValue({this.country, this.region, this.city});
  final String? country, region, city;
}

class LocationPicker extends StatefulWidget {
  const LocationPicker({
    super.key,
    required this.onChanged,
    this.initial = const LocationValue(),
  });

  final LocationValue initial;
  final ValueChanged<LocationValue> onChanged;

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late final LocationCatalog _catalog = getIt<LocationCatalog>();
  var _countries = const <String>[];
  var _regions = const <String>[];
  var _cities = const <String>[];
  String? _country;
  String? _region;
  String? _city;
  var _loadingCountries = true;
  var _loadingRegions = false;
  var _loadingCities = false;
  String? _error;
  var _regionToken = 0;
  var _cityToken = 0;

  String get _locale => Localizations.localeOf(context).languageCode;

  @override
  void initState() {
    super.initState();
    _country = widget.initial.country;
    _region = widget.initial.region;
    _city = widget.initial.city;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCountries());
  }

  void _emit() => widget.onChanged(
    LocationValue(country: _country, region: _region, city: _city),
  );

  Future<void> _loadCountries() async {
    setState(() {
      _loadingCountries = true;
      _error = null;
    });
    try {
      final items = await _catalog.countries(locale: _locale);
      if (!mounted) return;
      setState(() {
        _countries = items;
        _loadingCountries = false;
      });
      if (_country != null && _country!.isNotEmpty) {
        await _loadRegions(_country!, resetDependents: false);
      }
    } catch (error, stack) {
      developer.log('Failed to load countries', error: error, stackTrace: stack);
      if (!mounted) return;
      setState(() {
        _loadingCountries = false;
        _error = 'countries';
      });
    }
  }

  Future<void> _loadRegions(String country, {required bool resetDependents}) async {
    final token = ++_regionToken;
    setState(() {
      _loadingRegions = true;
      _error = null;
      if (resetDependents) {
        _region = null;
        _city = null;
        _cities = const [];
      }
      _regions = const [];
    });
    if (resetDependents) _emit();
    try {
      final items = await _catalog.subdivisions(country, locale: _locale);
      if (!mounted || token != _regionToken) return;
      setState(() {
        _regions = items;
        _loadingRegions = false;
      });
      if (_region != null && _region!.isNotEmpty) {
        await _loadCities(country, _region!, resetCity: false);
      } else if (items.isEmpty) {
        await _loadCountryCities(country);
      }
    } catch (error, stack) {
      developer.log('Failed to load subdivisions for $country', error: error, stackTrace: stack);
      if (!mounted || token != _regionToken) return;
      setState(() {
        _loadingRegions = false;
        _error = 'regions';
      });
    }
  }

  Future<void> _loadCities(
    String country,
    String region, {
    required bool resetCity,
  }) async {
    final token = ++_cityToken;
    setState(() {
      _loadingCities = true;
      _error = null;
      if (resetCity) _city = null;
      _cities = const [];
    });
    if (resetCity) _emit();
    try {
      final items = await _catalog.cities(country, region, locale: _locale);
      if (!mounted || token != _cityToken) return;
      setState(() {
        _cities = items;
        _loadingCities = false;
      });
    } catch (error, stack) {
      developer.log(
        'Failed to load cities for $country / $region',
        error: error,
        stackTrace: stack,
      );
      if (!mounted || token != _cityToken) return;
      setState(() {
        _loadingCities = false;
        _error = 'cities';
      });
    }
  }

  Future<void> _loadCountryCities(String country) async {
    final token = ++_cityToken;
    setState(() {
      _loadingCities = true;
      _cities = const [];
    });
    try {
      final items = await _catalog.citiesByCountry(country, locale: _locale);
      if (!mounted || token != _cityToken) return;
      setState(() {
        _cities = items;
        _loadingCities = false;
      });
    } catch (error, stack) {
      developer.log(
        'Failed to load country cities for $country',
        error: error,
        stackTrace: stack,
      );
      if (!mounted || token != _cityToken) return;
      setState(() => _loadingCities = false);
    }
  }

  void _onCountry(String value) {
    setState(() {
      _country = value;
      _region = null;
      _city = null;
      _regions = const [];
      _cities = const [];
    });
    _emit();
    unawaited(_loadRegions(value, resetDependents: true));
  }

  void _onRegion(String value) {
    setState(() => _region = value);
    _emit();
    if (_country != null) {
      unawaited(_loadCities(_country!, value, resetCity: true));
    }
  }

  void _onCity(String value) {
    setState(() => _city = value);
    _emit();
  }

  String _divisionLabel() {
    final l10n = context.l10n;
    final iso = _catalog.isoForCountry(_country ?? '', locale: _locale);
    return switch (divisionKindForCountry(iso)) {
      AdminDivisionKind.department => l10n.department,
      AdminDivisionKind.state => l10n.divisionState,
      AdminDivisionKind.community => l10n.divisionCommunity,
      AdminDivisionKind.region => l10n.divisionRegion,
    };
  }

  String _cityLabel() {
    final l10n = context.l10n;
    final iso = _catalog.isoForCountry(_country ?? '', locale: _locale);
    return iso == 'CO' || iso == 'MX' || iso == 'ES'
        ? l10n.cityMunicipality
        : l10n.city;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final countryReady = _country != null && _country!.isNotEmpty;
    final regionReady = _region != null && _region!.isNotEmpty;
    final skipDivision = countryReady && !_loadingRegions && _regions.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchableSelect(
          label: l10n.country,
          value: _country,
          options: _countries,
          loading: _loadingCountries,
          enabled: !_loadingCountries && _countries.isNotEmpty,
          searchHint: l10n.searchCountry,
          onSelected: _onCountry,
        ),
        SearchableSelect(
          label: _divisionLabel(),
          value: _region,
          options: _regions,
          enabled: countryReady && !_loadingRegions && _regions.isNotEmpty,
          loading: _loadingRegions,
          searchHint: l10n.searchDivision,
          emptyHint: countryReady ? null : l10n.locationSelectCountryFirst,
          onSelected: _onRegion,
        ),
        SearchableSelect(
          label: _cityLabel(),
          value: _city,
          options: _cities,
          enabled: (regionReady || skipDivision) &&
              !_loadingCities &&
              _cities.isNotEmpty,
          loading: _loadingCities,
          searchHint: l10n.searchCity,
          emptyHint: countryReady ? null : l10n.locationSelectCountryFirst,
          onSelected: _onCity,
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: AppColors.textDimmer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.locationLoadError,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (_error == 'cities' && countryReady && regionReady) {
                      unawaited(_loadCities(_country!, _region!, resetCity: false));
                    } else if (_error == 'regions' && countryReady) {
                      unawaited(_loadRegions(_country!, resetDependents: false));
                    } else {
                      unawaited(_loadCountries());
                    }
                  },
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
