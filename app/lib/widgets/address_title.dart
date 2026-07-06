import 'package:flutter/material.dart';

import '../data/address_search.dart';
import '../state/address_store.dart';

/// 홈·메뉴 AppBar 좌측의 주소 선택 위젯 (배민식).
/// 현재 주소를 보여주고, 누르면 주소 검색창이 열려 바로 변경된다.
class AddressTitle extends StatelessWidget {
  const AddressTitle({super.key});

  Future<void> _pick(BuildContext context) async {
    final picked = await pickAddress(context);
    if (picked != null && picked.isNotEmpty) {
      await AddressStore.instance.update(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AddressStore.instance,
      builder: (context, _) {
        final address = AddressStore.instance.address;
        return InkWell(
          onTap: () => _pick(context),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_outlined, size: 20),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    address.isEmpty ? '주소 설정' : address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                const Icon(Icons.expand_more, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
