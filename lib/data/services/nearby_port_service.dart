// lib/data/services/nearby_port_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../models/port_overview_model.dart';
import 'auth_service.dart';

class NearbyPortService {
  // /api + /ports + /overview (ajusta si tu AppConstants es distinto)
  final String _overviewUrl =
      AppConstants.baseUrl + AppConstants.portsEndpoint + '/overview';

  final AuthService _authService;

  NearbyPortService(this._authService);

  Future<PortOverviewResponse> getPortOverview({
    PortOperationalStatus? state,
    int? page,
    int? size,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();

      final queryParams = <String, String>{};
      if (state != null) {
        queryParams['state'] = portStatusToString(state);
      }
      if (page != null) {
        queryParams['page'] = page.toString();
      }
      if (size != null) {
        queryParams['size'] = size.toString();
      }

      final uri = Uri.parse(_overviewUrl).replace(queryParameters: queryParams);

      final resp = await http.get(uri, headers: headers);

      if (resp.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(resp.body);
        return PortOverviewResponse.fromJson(data);
      } else {
        // logueas el error si quieres
        return _getFallbackOverview();
      }
    } catch (e) {
      // network error, etc.
      return _getFallbackOverview();
    }
  }

  PortOverviewResponse _getFallbackOverview() {
    final now = DateTime.now();

    return PortOverviewResponse(
      content: [
        PortOverviewItem(
          portId: 'SGSIN',
          name: 'Port of Singapore',
          country: 'SG',
          lat: 1.29027,
          lon: 103.851959,
          status: PortOperationalStatus.OPEN,
          traffic: 720,
          updatedAt: now,
          contactPhone: '+65 1234 5678',
          contactEmail: 'info@singapore-port.sg',
          website: 'https://www.mpa.gov.sg/',
        ),
        PortOverviewItem(
          portId: 'MYTPP',
          name: 'Port of Tanjung Pelepas',
          country: 'MY',
          lat: 1.365,
          lon: 103.535,
          status: PortOperationalStatus.RESTRICTED,
          reason: 'Mantenimiento en muelle oeste',
          traffic: 410,
          updatedAt: now,
          contactPhone: '+60 7-555-0100',
          contactEmail: 'ops@ptp.com.my',
          website: 'https://www.ptp.com.my/',
        ),
        PortOverviewItem(
          portId: 'IDBTH',
          name: 'Port of Batam',
          country: 'ID',
          lat: 1.1301,
          lon: 104.0529,
          status: PortOperationalStatus.CLOSED,
          reason: 'Condiciones meteorológicas adversas',
          traffic: 0,
          updatedAt: now,
          contactPhone: '+62 778 111222',
          contactEmail: 'harbor@batamport.id',
          website: 'https://batam.go.id/',
        ),
      ],
      totalElements: 3,
      lastSyncedAt: now,
    );
  }
}
