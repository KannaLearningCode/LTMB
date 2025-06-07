class Constraints {
  // Collections
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String categoriesCollection = 'categories';
  static const String cartsCollection = 'carts';
  static const String ordersCollection = 'orders';
  static const String reviewsCollection = 'reviews';

  // Order Status
  static const String orderStatusPending = 'pending';
  static const String orderStatusConfirmed = 'confirmed';
  static const String orderStatusPreparing = 'preparing';
  static const String orderStatusDelivering = 'delivering';
  static const String orderStatusCompleted = 'completed';
  static const String orderStatusCancelled = 'cancelled';

  // Payment Methods
  static const String paymentMethodCash = 'cash';
  static const String paymentMethodMomo = 'momo';
  static const String paymentMethodZaloPay = 'zalopay';

  // Rating Range
  static const int minRating = 1;
  static const int maxRating = 5;
} 