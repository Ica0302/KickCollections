import 'package:flutter/material.dart';

import 'constants/app_colors.dart';
import 'data/shoe_catalog.dart';
import 'models/shoe.dart';
import 'services/payment_service.dart';
import 'utils/payment_helper.dart';
import 'utils/price_format.dart';
import 'widgets/cart_row.dart';
import 'widgets/empty_state.dart';
import 'widgets/order_complete.dart';
import 'widgets/payment_wait_dialog.dart';
import 'widgets/price_line.dart';
import 'widgets/product_grid.dart';
import 'widgets/top_bar.dart';
import 'widgets/bottom_bar.dart';
import 'widgets/hero_banner.dart';

class KicksCollectionApp extends StatefulWidget {
  const KicksCollectionApp({super.key});

  @override
  State<KicksCollectionApp> createState() => _KicksCollectionAppState();
}

class _KicksCollectionAppState extends State<KicksCollectionApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final Map<Shoe, int> _cart = {};
  final Set<Shoe> _favorites = {};
  final Map<String, String> _userDetails = {};
  final PaymentService _payments = PaymentService();

  int _selectedTab = 0;
  String _searchQuery = '';
  String _paymentMethod = 'Cash on Delivery';
  Shoe? _selectedShoe;
  bool _orderComplete = false;

  int get _cartCount =>
      _cart.values.fold(0, (total, quantity) => total + quantity);

  int get _cartTotal => _cart.entries.fold(
        0,
        (total, entry) => total + entry.key.price * entry.value,
      );

  int get _checkoutTotal => _cartTotal + 50;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      title: 'KicksCollection',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: paper,
        colorScheme: ColorScheme.fromSeed(seedColor: brandBlue),
        fontFamily: 'Roboto',
      ),
      home: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              TopBar(
                showActions: _selectedShoe != null,
                onProfileTap: _showAccountForm,
                onFavoritesTap: () => _selectTab(2),
                onCartTap: () => _selectTab(3),
              ),
              Expanded(
                child: _orderComplete
                    ? OrderComplete(
                        paymentMethod: _paymentMethod,
                        onContinue: _continueShopping,
                      )
                    : _buildCurrentPage(),
              ),
              BottomBar(
                selectedIndex: _selectedTab,
                cartCount: _cartCount,
                onTap: _selectTab,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPage() {
    if (_selectedShoe != null) {
      return _buildProductDetails(_selectedShoe!);
    }

    switch (_selectedTab) {
      case 1:
        return _buildListing(favoritesOnly: false);
      case 2:
        return _buildListing(favoritesOnly: true);
      case 3:
        return _buildCartPage();
      default:
        return _buildHomePage();
    }
  }

  Widget _buildHomePage() {
    final visibleShoes = shoeCatalog.where((shoe) {
      final searchableText = '${shoe.name} ${shoe.brand}'.toLowerCase();
      return searchableText.contains(_searchQuery.toLowerCase());
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
      children: [
        TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Search sneakers, brands, styles...',
            prefixIcon: const Icon(Icons.search, size: 21),
            filled: true,
            fillColor: const Color(0xFFE0E1E2),
            contentPadding: const EdgeInsets.symmetric(vertical: 7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 18),
        HeroBanner(onTap: () => _selectTab(1)),
        const SizedBox(height: 17),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .18),
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'All Collections',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
            const Spacer(),
            Text(
              '${visibleShoes.length} items',
              style: const TextStyle(
                color: muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (visibleShoes.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('No sneakers found.')),
          ),
        ProductGrid(
          shoes: visibleShoes,
          favorites: _favorites,
          onOpen: _openShoe,
          onFavorite: _toggleFavorite,
          onAddToCart: _addToCart,
        ),
      ],
    );
  }

  Widget _buildListing({required bool favoritesOnly}) {
    final shoes = favoritesOnly
        ? shoeCatalog.where(_favorites.contains).toList()
        : shoeCatalog;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          favoritesOnly ? 'Favorites' : 'Sneakers',
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        if (favoritesOnly && shoes.isEmpty)
          const EmptyState(
            icon: Icons.favorite_border,
            title: 'no favorites yet',
            subtitle: 'click heart icon to add to favorites.',
          ),
        ProductGrid(
          shoes: shoes,
          favorites: _favorites,
          onOpen: _openShoe,
          onFavorite: _toggleFavorite,
          onAddToCart: _addToCart,
        ),
      ],
    );
  }

  Widget _buildProductDetails(Shoe shoe) {
    int selectedSize = 42;
    int quantity = 1;
    int selectedImage = 0;
    final galleryImages =
        shoe.galleryImages.isEmpty ? <String>[shoe.image] : shoe.galleryImages;
    final galleryLabels = galleryImages.length == 4
        ? const ['MAIN', 'SIDE', 'REAR', 'PROFILE']
        : const ['SIDE', 'FRONT', 'BACK'];
    Color selectedColor = shoe.color;
    final availableColors = <Color>[shoe.color];

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F4EB),
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 4,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: SizedBox(
                height: 340,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        children: [
                          Expanded(
                            child: Image.asset(
                              galleryImages[selectedImage],
                              fit: BoxFit.contain,
                              width: double.infinity,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children:
                                List.generate(galleryImages.length, (index) {
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => setLocalState(
                                    () => selectedImage = index,
                                  ),
                                  child: Container(
                                    height: 52,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: selectedImage == index
                                            ? brandBlue
                                            : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: Image.asset(
                                            galleryImages[index],
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                        Text(
                                          galleryLabels[index],
                                          style: const TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w700,
                                            color: muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${shoe.brand}\n${shoe.name}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 19,
                              height: 1.12,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '₱ ${formatPrice(shoe.price)}.00',
                            style: const TextStyle(
                              color: Color(0xFFFF2028),
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Colors',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: availableColors.map((color) {
                              final isSelected = selectedColor == color;
                              return GestureDetector(
                                onTap: () => setLocalState(
                                  () => selectedColor = color,
                                ),
                                child: Container(
                                  width: 23,
                                  height: 23,
                                  margin: const EdgeInsets.only(right: 9),
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: isSelected
                                        ? Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          )
                                        : null,
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color:
                                                  color.withValues(alpha: .5),
                                              blurRadius: 0,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 7),
                          const Text(
                            'Size',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 3),
                          Wrap(
                            spacing: 3,
                            runSpacing: 3,
                            children: List.generate(5, (index) {
                              final size = 41 + index;
                              return ChoiceChip(
                                label: Text(
                                  '$size',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                selected: selectedSize == size,
                                onSelected: (_) => setLocalState(
                                  () => selectedSize = size,
                                ),
                                selectedColor: const Color(0xFFF4C9CC),
                                backgroundColor: const Color(0xFFF4C9CC),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                labelPadding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              );
                            }),
                          ),
                          const SizedBox(height: 7),
                          const Text(
                            'Quantity',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => setLocalState(
                                    () => quantity++,
                                  ),
                                  child: const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 2),
                                    child: Text(
                                      '+',
                                      style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  '$quantity',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                InkWell(
                                  onTap: quantity > 1
                                      ? () => setLocalState(
                                            () => quantity--,
                                          )
                                      : null,
                                  child: const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 2),
                                    child: Text(
                                      '−',
                                      style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: () {
                                    _addToCart(shoe, quantity: quantity);
                                    _selectTab(3);
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFB3D9C1),
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 7,
                                    ),
                                    minimumSize: const Size(0, 34),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'Buy',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 3),
                                      Icon(
                                        Icons.shopping_basket_outlined,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () =>
                                      _addToCart(shoe, quantity: quantity),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFB3D9C1),
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 7,
                                    ),
                                    minimumSize: const Size(0, 34),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'Add to Cart',
                                          maxLines: 2,
                                          style: TextStyle(
                                            fontSize: 10,
                                            height: 1,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 2),
                                      Icon(
                                        Icons.shopping_cart_outlined,
                                        size: 15,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Description:',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Text(
                shoe.description,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.3,
                  color: Color(0xFF222222),
                ),
              ),
            ),
            if (shoe.details.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Product Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: shoe.details
                      .map(
                        (detail) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('•  '),
                              Expanded(child: Text(detail)),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCartPage() {
    if (_cart.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(18),
        children: const [
          Text(
            'Shopping cart',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 36),
          EmptyState(
            icon: Icons.shopping_bag_outlined,
            title: 'no items in cart',
            subtitle: 'Your cart is empty.',
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      children: [
        const Text(
          'Shopping cart',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        ..._cart.entries.map((entry) {
          return CartRow(
            shoe: entry.key,
            quantity: entry.value,
            onMinus: () => _changeQuantity(entry.key, -1),
            onPlus: () => _changeQuantity(entry.key, 1),
          );
        }),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              PriceLine(
                label: 'Subtotal',
                value: '₱ ${formatPrice(_cartTotal)}',
              ),
              const SizedBox(height: 9),
              const PriceLine(label: 'Delivery fee', value: '₱50'),
              const Divider(height: 22),
              PriceLine(
                label: 'Kabuuan',
                value: '₱ ${formatPrice(_checkoutTotal)}',
                bold: true,
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.only(top: 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Ilagay ang delivery at payment details sa susunod na hakbang.',
                    style: TextStyle(fontSize: 11, color: muted),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: lime,
                    foregroundColor: ink,
                  ),
                  onPressed: _showCheckoutForm,
                  child: const Text(
                    'Checkout',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _selectTab(int index) {
    setState(() {
      _selectedTab = index;
      _selectedShoe = null;
    });
  }

  void _openShoe(Shoe shoe) {
    setState(() => _selectedShoe = shoe);
  }

  void _toggleFavorite(Shoe shoe) {
    setState(() {
      if (!_favorites.add(shoe)) {
        _favorites.remove(shoe);
      }
    });
  }

  void _addToCart(Shoe shoe, {int quantity = 1}) {
    setState(() {
      _cart[shoe] = (_cart[shoe] ?? 0) + quantity;
    });

    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('${shoe.name} add cart'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'See Details',
          onPressed: () => _selectTab(3),
        ),
      ),
    );
  }

  void _changeQuantity(Shoe shoe, int change) {
    setState(() {
      final updatedQuantity = (_cart[shoe] ?? 0) + change;
      if (updatedQuantity <= 0) {
        _cart.remove(shoe);
      } else {
        _cart[shoe] = updatedQuantity;
      }
    });
  }

  Future<void> _showCheckoutForm() async {
    const methods = [
      'Cash on Delivery',
      'GCash',
      'Maya',
      'Debit/Credit Card',
    ];
    final nameController =
        TextEditingController(text: _userDetails['name'] ?? '');
    final emailController =
        TextEditingController(text: _userDetails['email'] ?? '');
    final phoneController =
        TextEditingController(text: _userDetails['phone'] ?? '');
    final addressController =
        TextEditingController(text: _userDetails['address'] ?? '');
    final formKey = GlobalKey<FormState>();
    var selectedPayment = _paymentMethod;

    final submitted = await showDialog<bool>(
      context: _navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Checkout details'),
          content: SizedBox(
            width: 440,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * .65,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order total: ₱ ${formatPrice(_checkoutTotal)}',
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Buong pangalan',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Ilagay ang pangalan.'
                                : null,
                      ),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) => value == null ||
                                !RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                                    .hasMatch(value.trim())
                            ? 'Maglagay ng valid na email.'
                            : null,
                      ),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Mobile number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Ilagay ang mobile number.'
                                : null,
                      ),
                      TextFormField(
                        controller: addressController,
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Delivery address',
                          prefixIcon: Icon(Icons.location_on_outlined),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Ilagay ang delivery address.'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      const Text('Paraan ng bayad',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      RadioGroup<String>(
                        groupValue: selectedPayment,
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => selectedPayment = value);
                          }
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: methods
                              .map((method) => RadioListTile<String>(
                                    value: method,
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    secondary: Icon(paymentIcon(method)),
                                    title: Text(method),
                                  ))
                              .toList(),
                        ),
                      ),
                      const Text(
                        'Online payments are processed securely by Xendit.',
                        style: TextStyle(fontSize: 11, color: muted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Place order'),
            ),
          ],
        ),
      ),
    );

    if (submitted == true && mounted) {
      setState(() {
        _userDetails
          ..['name'] = nameController.text.trim()
          ..['email'] = emailController.text.trim()
          ..['phone'] = phoneController.text.trim()
          ..['address'] = addressController.text.trim();
        _paymentMethod = selectedPayment;
      });
      await _placeOrder();
    }
  }

  Future<void> _placeOrder() async {
    try {
      final result = await _payments.createCheckout(
        cart: Map<Shoe, int>.of(_cart),
        paymentMethod: _paymentMethod,
        customer: Map<String, String>.of(_userDetails),
      );

      var completed = !result.requiresOnlinePayment; // COD is done here
      if (result.requiresOnlinePayment) {
        final opened = await _payments.openInvoice(result.invoiceUrl!);
        if (!opened) {
          throw const PaymentException('Could not open the payment page.');
        }
        final status = await _waitForPayment(result.orderId);
        if (status == 'paid') {
          completed = true;
        } else {
          _showPaymentMessage(
            status == null
                ? 'Payment cancelled. Your cart is still saved.'
                : 'Payment $status. Please try again.',
          );
        }
      }

      if (completed && mounted) {
        setState(() {
          _cart.clear();
          _orderComplete = true;
          _selectedTab = 0;
        });
      }
    } on PaymentException catch (error) {
      _showPaymentMessage(error.message);
    } catch (_) {
      _showPaymentMessage('Something went wrong. Please try again.');
    }
  }

  Future<String?> _waitForPayment(String orderId) {
    return showDialog<String>(
      context: _navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (_) => PaymentWaitDialog(
        statusStream: _payments.watchOrderStatus(orderId),
      ),
    );
  }

  void _showPaymentMessage(String message) {
    _scaffoldMessengerKey.currentState
        ?.showSnackBar(SnackBar(content: Text(message)));
  }

  void _continueShopping() {
    setState(() => _orderComplete = false);
  }

  Future<void> _showAccountForm() async {
    final nameController =
        TextEditingController(text: _userDetails['name'] ?? '');
    final emailController =
        TextEditingController(text: _userDetails['email'] ?? '');
    final phoneController =
        TextEditingController(text: _userDetails['phone'] ?? '');
    final addressController =
        TextEditingController(text: _userDetails['address'] ?? '');
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: _navigatorKey.currentContext!,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Detalye ng User'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Buong pangalan',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Ilagay ang pangalan.'
                        : null,
                  ),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) => value == null ||
                            !RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                                .hasMatch(value.trim())
                        ? 'Maglagay ng valid na email.'
                        : null,
                  ),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Mobile number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Ilagay ang mobile number.'
                        : null,
                  ),
                  TextFormField(
                    controller: addressController,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Delivery address',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Ilagay ang delivery address.'
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Save details'),
          ),
        ],
      ),
    );

    if (saved == true && mounted) {
      setState(() {
        _userDetails
          ..['name'] = nameController.text.trim()
          ..['email'] = emailController.text.trim()
          ..['phone'] = phoneController.text.trim()
          ..['address'] = addressController.text.trim();
      });
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Na-save ang detalye ng user.')),
      );
    }
  }
}
