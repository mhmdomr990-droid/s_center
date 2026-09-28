import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/admin_provider.dart';
import '../../../data/providers/api_client.dart';

class SendNotificationController extends GetxController {
  final AdminProvider _provider;
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final sendToAll = true.obs;
  final candidates = <Map<String, dynamic>>[].obs;
  final selectedUser = Rxn<Map<String, dynamic>>();

  final titleCtrl = TextEditingController();
  final bodyCtrl = TextEditingController();
  final searchCtrl = TextEditingController();
  Timer? _debounce;

  SendNotificationController() : _provider = AdminProvider(Get.find<ApiClient>());

  @override
  void onClose() {
    titleCtrl.dispose();
    bodyCtrl.dispose();
    searchCtrl.dispose();
    _debounce?.cancel();
    super.onClose();
  }

  void setSendToAll(bool value) {
    sendToAll.value = value;
    selectedUser.value = null;
    if (!value) searchUsers('');
  }

  void onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () => searchUsers(value.trim()));
  }

  Future<void> searchUsers(String query) async {
    isLoading.value = true;
    try {
      final response = await _provider.users(search: query, limit: 10);
      candidates.assignAll(List<Map<String, dynamic>>.from(
          (response.data['data'] as List).map((e) => Map<String, dynamic>.from(e))));
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  void selectUser(Map<String, dynamic> user) {
    selectedUser.value = user;
    candidates.clear();
    searchCtrl.clear();
  }

  Future<void> submit() async {
    final title = titleCtrl.text.trim();
    final body = bodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty) {
      Get.snackbar('خطأ', 'أدخل العنوان ونص الإشعار',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (!sendToAll.value && selectedUser.value == null) {
      Get.snackbar('خطأ', 'اختر مستخدماً أو أرسل للجميع',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    isSubmitting.value = true;
    try {
      if (sendToAll.value) {
        await _provider.sendNotificationToAll(title: title, body: body);
      } else {
        await _provider.sendNotificationToUser(
            userId: selectedUser.value!['id'] as int, title: title, body: body);
      }
      titleCtrl.clear();
      bodyCtrl.clear();
      selectedUser.value = null;
      Get.snackbar('تم', 'تم إرسال الإشعار',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (_) {
      Get.snackbar('خطأ', 'فشل إرسال الإشعار',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isSubmitting.value = false;
    }
  }
}
