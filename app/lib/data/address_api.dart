import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';

/// 저장된 주소 한 건
class AddressItem {
  final int id;
  final String address;
  final bool selected;

  const AddressItem({required this.id, required this.address, required this.selected});

  factory AddressItem.fromJson(Map<String, dynamic> j) => AddressItem(
        id: (j['id'] as num).toInt(),
        address: (j['address'] as String?) ?? '',
        selected: (j['selected'] as bool?) ?? false,
      );
}

/// 회원 주소 목록 API (배민식 주소 관리)
class AddressApi {
  final http.Client _client;

  AddressApi({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers(String token) =>
      {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};

  List<AddressItem> _parse(http.Response res, String fallback) {
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      final error = body['error'];
      throw ApiException(
          error is Map && error['message'] is String ? error['message'] as String : fallback);
    }
    return (body['data'] as List<dynamic>)
        .map((e) => AddressItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AddressItem>> fetchAddresses(String token) async {
    final res = await _client.get(Uri.parse('$kApiBaseUrl/api/users/me/addresses'),
        headers: {'Authorization': 'Bearer $token'});
    return _parse(res, '주소 목록을 불러오지 못했어요');
  }

  Future<List<AddressItem>> addAddress(String token, String address) async {
    final res = await _client.post(Uri.parse('$kApiBaseUrl/api/users/me/addresses'),
        headers: _headers(token), body: jsonEncode({'address': address}));
    return _parse(res, '주소를 추가하지 못했어요');
  }

  Future<List<AddressItem>> selectAddress(String token, int addressId) async {
    final res = await _client.patch(
        Uri.parse('$kApiBaseUrl/api/users/me/addresses/$addressId/select'),
        headers: _headers(token));
    return _parse(res, '주소를 선택하지 못했어요');
  }

  Future<List<AddressItem>> deleteAddress(String token, int addressId) async {
    final res = await _client.delete(
        Uri.parse('$kApiBaseUrl/api/users/me/addresses/$addressId'),
        headers: _headers(token));
    return _parse(res, '주소를 삭제하지 못했어요');
  }
}
