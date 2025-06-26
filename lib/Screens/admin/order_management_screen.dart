import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kfc_seller/Models/order.dart';
import 'package:kfc_seller/Screens/Order/order_service.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  List<Order> orders = [];
  final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '');
  final Map<String, String> userNames = {}; // userId -> userName

  String? selectedPaymentMethod;
  String? selectedStatus;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      final fetchedOrders = await OrderService.getAllOrders();

      for (var order in fetchedOrders) {
        final userId = order.userId.toHexString();
        if (!userNames.containsKey(userId)) {
          final user = await OrderService.getUserById(userId);
          if (user != null) {
            userNames[userId] = user.fullName?.isNotEmpty == true
                ? user.fullName!
                : user.name;
          } else {
            userNames[userId] = 'Không xác định';
          }
        }
      }

      setState(() {
        orders = fetchedOrders;
      });
    } catch (e) {
      debugPrint('Lỗi tải đơn hàng: $e');
    }
  }

  List<Order> get filteredOrders {
    return orders.where((order) {
      final matchMethod = selectedPaymentMethod == null || order.paymentMethod == selectedPaymentMethod;
      final matchStatus = selectedStatus == null || order.status == selectedStatus;
      return matchMethod && matchStatus;
    }).toList();
  }

  void showOrderDetailPopup(Order order) {
    final userName = userNames[order.userId.toHexString()] ?? 'Không có';

    showDialog(
      context: context,
      builder: (_) {
        final isFinalStatus = order.status == "Đã xác nhận" || order.status == "Đã hủy";

        return AlertDialog(
          title: Text('Chi tiết đơn hàng #${order.id.toHexString().substring(18)}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Thông tin người đặt', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Họ tên: $userName'),
                Text('SĐT: ${order.phone}'),
                Text('Địa chỉ: ${order.shippingAddress}'),
                Text('Phương thức thanh toán: ${order.paymentMethod}'),
                Text('Trạng thái: ${order.paymentStatus.toUpperCase()}'),
                const SizedBox(height: 12),
                const Text('Danh sách sản phẩm', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                ...order.items.map((item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Image.network(item.productImage, width: 50, height: 50, fit: BoxFit.cover),
                      title: Text(item.productName),
                      subtitle: Text('SL: ${item.quantity} | Đơn giá: ${currency.format(item.price)} VNĐ'),
                    )),
                Text('Tổng cộng: ${currency.format(order.totalAmount)} VNĐ',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
            if (!isFinalStatus) ...[
              TextButton(
                onPressed: () async {
                  await OrderService.updateOrderStatus(order.id, "Đã xác nhận");
                  Navigator.pop(context);
                  fetchOrders();
                },
                child: const Text('✅ Xác nhận', style: TextStyle(color: Colors.green)),
              ),
              TextButton(
                onPressed: () async {
                  await OrderService.updateOrderStatus(order.id, "Đã hủy");
                  Navigator.pop(context);
                  fetchOrders();
                },
                child: const Text('❌ Hủy', style: TextStyle(color: Colors.red)),
              ),
            ] else ...[
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  '❗ Trạng thái đã cố định, không thể thay đổi',
                  style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic),
                ),
              ),
            ]
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý đơn hàng', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: fetchOrders,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedPaymentMethod,
                      decoration: const InputDecoration(labelText: 'Phương thức'),
                      items: <String?>[null, 'COD', 'PayPal']
                          .map((method) => DropdownMenuItem(
                                value: method,
                                child: Text(method ?? 'Tất cả'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedPaymentMethod = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(labelText: 'Trạng thái'),
                      items: <String?>[null, 'Đã xác nhận', 'Đã hủy', 'Đang xử lý']
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status ?? 'Tất cả'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedStatus = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredOrders.isEmpty
                  ? const Center(child: Text('Không có đơn hàng'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            title: Text('Đơn hàng #${order.id.toHexString().substring(18)}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Trạng thái: ${order.status.toUpperCase()}'),
                                Text('Tổng tiền: ${currency.format(order.totalAmount)} VNĐ'),
                                Text('Thời gian: ${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)}'),
                              ],
                            ),
                            trailing: const Icon(Icons.info_outline),
                            onTap: () => showOrderDetailPopup(order),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
