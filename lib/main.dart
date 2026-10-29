import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/shoe_catalog.dart';
import 'models/shoe.dart';
import 'services/payment_service.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
      url: _supabaseUrl, publishableKey: _supabaseAnonKey);
  runApp(const KicksCollectionApp());
}

// App colors
const Color ink = Color(0xFF17191C);
const Color muted = Color(0xFF777B80);
const Color paper = Color(0xFFF1F2F2);
const Color brandBlue = Color(0xFF1468E8);
const Color lime = Color(0xFF55D500);

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
              _TopBar(
                showActions: _selectedShoe != null,
                onProfileTap: _showAccountForm,
                onFavoritesTap: () => _selectTab(2),
                onCartTap: () => _selectTab(3),
              ),
              Expanded(
                child: _orderComplete
                    ? _OrderComplete(
                        paymentMethod: _paymentMethod,
                        onContinue: _continueShopping,
                      )
                    : _buildCurrentPage(),
              ),
              _BottomBar(
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
        _HeroBanner(onTap: () => _selectTab(1)),
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
        _ProductGrid(
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
          const _EmptyState(
            icon: Icons.favorite_border,
            title: 'no favorites yet',
            subtitle: 'click heart icon to add to favorites.',
          ),
        _ProductGrid(
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
                            '₱ ${_formatPrice(shoe.price)}.00',
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
          _EmptyState(
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
          return _CartRow(
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
              _PriceLine(
                label: 'Subtotal',
                value: '₱ ${_formatPrice(_cartTotal)}',
              ),
              const SizedBox(height: 9),
              const _PriceLine(label: 'Delivery fee', value: '₱50'),
              const Divider(height: 22),
              _PriceLine(
                label: 'Kabuuan',
                value: '₱ ${_formatPrice(_checkoutTotal)}',
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
                      Text('Order total: ₱ ${_formatPrice(_checkoutTotal)}',
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
                                    secondary: Icon(_paymentIcon(method)),
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
      builder: (_) => _PaymentWaitDialog(
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

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.showActions,
    required this.onProfileTap,
    required this.onFavoritesTap,
    required this.onCartTap,
  });

  final bool showActions;
  final VoidCallback onProfileTap;
  final VoidCallback onFavoritesTap;
  final VoidCallback onCartTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 7, 10, 5),
      child: Row(
        children: [
          const Text(
            'KicksCollection',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -.8,
            ),
          ),
          const Spacer(),
          if (showActions) ...[
            IconButton(
              onPressed: onFavoritesTap,
              icon: const Icon(Icons.favorite_border, size: 25),
            ),
            IconButton(
              onPressed: onCartTap,
              icon: const Icon(Icons.shopping_cart_outlined, size: 24),
            ),
          ],
          IconButton(
            onPressed: onProfileTap,
            icon: const Icon(Icons.person, size: 24),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.selectedIndex,
    required this.cartCount,
    required this.onTap,
  });

  final int selectedIndex;
  final int cartCount;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 10),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            active: selectedIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.directions_run,
            label: 'Sneakers',
            active: selectedIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavItem(
            icon: Icons.favorite_border,
            label: 'Favorites',
            active: selectedIndex == 2,
            onTap: () => onTap(2),
          ),
          Badge(
            isLabelVisible: cartCount > 0,
            label: Text('$cartCount'),
            child: _NavItem(
              icon: Icons.shopping_bag_outlined,
              label: 'Cart',
              active: selectedIndex == 3,
              onTap: () => onTap(3),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: active ? ink : muted),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 4,
              offset: Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          'assets/shoes/discover_shoes_banner.png',
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({
    required this.shoes,
    required this.favorites,
    required this.onOpen,
    required this.onFavorite,
    required this.onAddToCart,
  });

  final List<Shoe> shoes;
  final Set<Shoe> favorites;
  final ValueChanged<Shoe> onOpen;
  final ValueChanged<Shoe> onFavorite;
  final ValueChanged<Shoe> onAddToCart;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: shoes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.08,
      ),
      itemBuilder: (context, index) {
        final shoe = shoes[index];
        return _ProductCard(
          shoe: shoe,
          favorite: favorites.contains(shoe),
          onTap: () => onOpen(shoe),
          onFavorite: () => onFavorite(shoe),
          onAdd: () => onAddToCart(shoe),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.shoe,
    required this.favorite,
    required this.onTap,
    required this.onFavorite,
    required this.onAdd,
  });

  final Shoe shoe;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFDCDDDF),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F1F2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Image.asset(shoe.image, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '₱ ${_formatPrice(shoe.price)}.00',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onAdd,
                    tooltip: 'Add to cart',
                    icon: const Icon(Icons.shopping_cart_outlined, size: 22),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 34),
                  ),
                  IconButton(
                    onPressed: onFavorite,
                    tooltip: favorite
                        ? 'Alisin sa favorites'
                        : 'Idagdag sa favorites',
                    icon: Icon(
                      favorite ? Icons.favorite : Icons.favorite_border,
                      size: 22,
                    ),
                    color: favorite ? Colors.red : ink,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 34),
                  ),
                  IconButton(
                    onPressed: onTap,
                    tooltip: 'See details',
                    icon: const Icon(Icons.shopping_bag_outlined, size: 22),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 34),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({
    required this.shoe,
    required this.quantity,
    required this.onMinus,
    required this.onPlus,
  });

  final Shoe shoe;
  final int quantity;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 84,
            height: 82,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F3),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Image.asset(shoe.image, fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shoe.brand,
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
                Text(
                  shoe.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(
                  '₱ ${_formatPrice(shoe.price)}',
                  style: const TextStyle(
                    color: brandBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onMinus,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text(
            '$quantity',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          IconButton(
            onPressed: onPlus,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: bold ? ink : muted,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            fontSize: bold ? 16 : 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
            fontSize: bold ? 17 : 14,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(icon, size: 52, color: muted),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted),
          ),
        ],
      ),
    );
  }
}

class _CompletionBackgroundPainter extends CustomPainter {
  const _CompletionBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final lightBrush = Paint()
      ..color = const Color(0xFFE9EBEC)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 12;

    final topBrush = Path()
      ..moveTo(-size.width * .08, size.height * .15)
      ..cubicTo(
        size.width * .18,
        size.height * .02,
        size.width * .30,
        size.height * .04,
        size.width * .48,
        -size.height * .04,
      );
    canvas.drawPath(topBrush, lightBrush);

    final secondBrush = Path()
      ..moveTo(-size.width * .06, size.height * .22)
      ..cubicTo(
        size.width * .18,
        size.height * .13,
        size.width * .30,
        size.height * .12,
        size.width * .49,
        size.height * .04,
      );
    canvas.drawPath(secondBrush, lightBrush);

    final greenBrush = Paint()
      ..color = const Color(0xFF64E900)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8;

    final greenPath = Path()
      ..moveTo(size.width * .68, size.height * .12)
      ..cubicTo(
        size.width * .83,
        size.height * .20,
        size.width * .90,
        size.height * .08,
        size.width * 1.08,
        size.height * .02,
      );
    canvas.drawPath(greenPath, greenBrush);

    final bottomBrush = Path()
      ..moveTo(-size.width * .10, size.height * .91)
      ..cubicTo(
        size.width * .12,
        size.height * .78,
        size.width * .19,
        size.height * .85,
        size.width * .34,
        size.height * 1.08,
      );
    canvas.drawPath(bottomBrush, lightBrush);

    final smallGreen = Path()
      ..moveTo(size.width * .73, size.height * .88)
      ..cubicTo(
        size.width * .86,
        size.height * .80,
        size.width * .91,
        size.height * .91,
        size.width * 1.04,
        size.height * .78,
      );
    canvas.drawPath(smallGreen, greenBrush);

    final speckPaint = Paint()..color = const Color(0xFF6BEA14);
    for (final point in <Offset>[
      Offset(size.width * .76, size.height * .18),
      Offset(size.width * .83, size.height * .15),
      Offset(size.width * .91, size.height * .21),
      Offset(size.width * .18, size.height * .89),
      Offset(size.width * .26, size.height * .93),
      Offset(size.width * .78, size.height * .80),
    ]) {
      canvas.drawCircle(point, 2.2, speckPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CompletionBackgroundPainter oldDelegate) =>
      false;
}

class _OrderComplete extends StatelessWidget {
  const _OrderComplete({required this.paymentMethod, required this.onContinue});

  final String paymentMethod;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFF37AFFF),
            width: 1.2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(
                painter: _CompletionBackgroundPainter(),
              ),
            ),
            Positioned(
              right: -42,
              top: 14,
              child: Transform.rotate(
                angle: -.30,
                child: Opacity(
                  opacity: .92,
                  child: Image.asset(
                    'assets/shoes/black.png',
                    width: 220,
                    height: 190,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              left: -70,
              bottom: -45,
              child: Transform.rotate(
                angle: .28,
                child: Opacity(
                  opacity: .25,
                  child: Image.asset(
                    'assets/shoes/black.png',
                    width: 245,
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 94,
                      height: 94,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF55D500),
                          width: 7,
                        ),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Color(0xFF55D500),
                        size: 65,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Order Completed',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Payment: $paymentMethod',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 185,
                      height: 7,
                      decoration: BoxDecoration(
                        color: const Color(0xFF55D500),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF55D500),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 14,
                        ),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: onContinue,
                      icon: const Text(
                        'Continue Shopping',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      label: const Icon(Icons.arrow_forward, size: 22),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _paymentIcon(String method) {
  switch (method) {
    case 'Cash on Delivery':
      return Icons.payments_outlined;
    case 'GCash':
      return Icons.account_balance_wallet_outlined;
    case 'Maya':
      return Icons.wallet_outlined;
    default:
      return Icons.credit_card_outlined;
  }
}

String _formatPrice(int price) {
  return price.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => ',',
      );
}

class _PaymentWaitDialog extends StatefulWidget {
  const _PaymentWaitDialog({required this.statusStream});

  final Stream<String> statusStream;

  @override
  State<_PaymentWaitDialog> createState() => _PaymentWaitDialogState();
}

class _PaymentWaitDialogState extends State<_PaymentWaitDialog> {
  StreamSubscription<String>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.statusStream.listen((status) {
      if (status != 'pending' && mounted) Navigator.pop(context, status);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Waiting for payment'),
      content: const Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          SizedBox(width: 16),
          Expanded(
              child: Text(
                  'Finish paying in the Xendit page, then come back here.')),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
