import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kfc_seller/Models/order.dart';
import 'package:kfc_seller/Screens/Order/order_service.dart';
import 'package:kfc_seller/Theme/colors.dart';

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
  bool showQROrdersOnly = false; // New state for QR filter
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      final matchMethod = selectedPaymentMethod == null || 
          order.paymentMethod == selectedPaymentMethod;
      final matchStatus = selectedStatus == null || 
          order.status == selectedStatus;
      final matchQRFilter = !showQROrdersOnly || 
          order.paymentMethod == 'QR'; // QR code filter condition
      final searchQuery = _searchController.text.toLowerCase();
      final matchSearch = searchQuery.isEmpty ||
          order.id.toHexString().toLowerCase().contains(searchQuery) ||
          (userNames[order.userId.toHexString()]?.toLowerCase().contains(searchQuery) ?? false);
      
      return matchMethod && matchStatus && matchQRFilter && matchSearch;
    }).toList();
  }

  void showOrderDetailPopup(Order order) {
    final userName = userNames[order.userId.toHexString()] ?? 'Không có';

    showDialog(
      context: context,
      builder: (_) {
        final isFinalStatus = order.status == "Đã xác nhận" || order.status == "Đã hủy";

        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Chi tiết đơn hàng #${order.id.toHexString().substring(18)}',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Thông tin người đặt', 
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                Text('Họ tên: $userName', style: TextStyle(color: AppColors.textSecondary)),
                Text('SĐT: ${order.phone}', style: TextStyle(color: AppColors.textSecondary)),
                Text('Địa chỉ: ${order.shippingAddress}', style: TextStyle(color: AppColors.textSecondary)),
                Text('Phương thức thanh toán: ${order.paymentMethod}', 
                    style: TextStyle(color: AppColors.textSecondary)),
                Text('Trạng thái: ${order.paymentStatus.toUpperCase()}', 
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                Text('Danh sách sản phẩm', 
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                ...order.items.map((item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Image.network(item.productImage, width: 50, height: 50, fit: BoxFit.cover),
                      title: Text(item.productName, style: TextStyle(color: AppColors.textPrimary)),
                      subtitle: Text('SL: ${item.quantity} | Đơn giá: ${currency.format(item.price)} VNĐ',
                          style: TextStyle(color: AppColors.textSecondary)),
                    )),
                const SizedBox(height: 6),
                Text('Tổng cộng: ${currency.format(order.totalAmount)} VNĐ',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Đóng', style: TextStyle(color: AppColors.textSecondary)),
            ),
            if (!isFinalStatus) ...[
              TextButton(
                onPressed: () async {
                  await OrderService.updateOrderStatus(order.id, "Đã xác nhận");
                  Navigator.pop(context);
                  fetchOrders();
                },
                child: Text('✅ Xác nhận', style: TextStyle(color: AppColors.success)),
              ),
              TextButton(
                onPressed: () async {
                  await OrderService.updateOrderStatus(order.id, "Đã hủy");
                  Navigator.pop(context);
                  fetchOrders();
                },
                child: Text('❌ Hủy', style: TextStyle(color: AppColors.error)),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '❗ Trạng thái đã cố định, không thể thay đổi',
                  style: TextStyle(color: AppColors.error, fontStyle: FontStyle.italic),
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
        title: Text('Quản lý đơn hàng', style: TextStyle(color: AppColors.textOnPrimary)),
        backgroundColor: AppColors.primary,
        iconTheme: IconThemeData(color: AppColors.textOnPrimary),
        actions: [
          // QR filter toggle button
          IconButton(
            icon: Icon(
              showQROrdersOnly ? Icons.qr_code : Icons.qr_code_outlined,
              color: showQROrdersOnly ? AppColors.primary : AppColors.textOnPrimary,
            ),
            onPressed: () {
              setState(() {
                showQROrdersOnly = !showQROrdersOnly;
              });
            },
            tooltip: 'Chỉ hiển thị đơn QR',
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: fetchOrders,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Search bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Tìm kiếm đơn hàng',
                      prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: AppColors.textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedPaymentMethod,
                          decoration: InputDecoration(
                            labelText: 'Phương thức',
                            labelStyle: TextStyle(color: AppColors.textSecondary),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.5)),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.primary),
                            ),
                          ),
                          dropdownColor: AppColors.surface,
                          style: TextStyle(color: AppColors.textPrimary),
                          items: <String?>[null, 'COD', 'PayPal', 'QR'] // Added QR option
                              .map((method) => DropdownMenuItem(
                                    value: method,
                                    child: Text(method ?? 'Tất cả', 
                                        style: TextStyle(color: AppColors.textPrimary)),
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
                          decoration: InputDecoration(
                            labelText: 'Trạng thái',
                            labelStyle: TextStyle(color: AppColors.textSecondary),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.5)),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.primary),
                            ),
                          ),
                          dropdownColor: AppColors.surface,
                          style: TextStyle(color: AppColors.textPrimary),
                          items: <String?>[null, 'Đã xác nhận', 'Đã hủy', 'Đang xử lý']
                              .map((status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status ?? 'Tất cả', 
                                        style: TextStyle(color: AppColors.textPrimary)),
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
                ],
              ),
            ),
            if (showQROrdersOnly)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.qr_code, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Đang hiển thị đơn thanh toán QR',
                      style: TextStyle(color: AppColors.primary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: filteredOrders.isEmpty
                  ? Center(
                      child: Text('Không có đơn hàng', 
                          style: TextStyle(color: AppColors.textSecondary)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        return Card(
                          color: AppColors.surface,
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            title: Text('Đơn hàng #${order.id.toHexString().substring(18)}',
                                style: TextStyle(color: AppColors.textPrimary)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('Trạng thái: ${order.status.toUpperCase()}',
                                        style: TextStyle(color: AppColors.textSecondary)),
                                    if (order.paymentMethod == 'QR')
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Icon(Icons.qr_code, size: 16, color: AppColors.primary),
                                      ),
                                  ],
                                ),
                                Text('Tổng tiền: ${currency.format(order.totalAmount)} VNĐ',
                                    style: TextStyle(color: AppColors.textSecondary)),
                                Text('Thời gian: ${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)}',
                                    style: TextStyle(color: AppColors.textSecondary)),
                              ],
                            ),
                            trailing: Icon(Icons.info_outline, color: AppColors.primary),
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