import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SogandApp());
}

class ShopProduct {
  ShopProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.basePrice,
    required this.stock,
    required this.colorPrices,
  });

  final String id;
  String name, description, imageUrl, category;
  int basePrice, stock;
  Map<String, int> colorPrices;

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'description': description,
    'imageUrl': imageUrl, 'category': category,
    'basePrice': basePrice, 'stock': stock,
    'colorPrices': colorPrices,
  };

  factory ShopProduct.fromJson(Map<String, dynamic> j) => ShopProduct(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    description: j['description'] as String? ?? '',
    imageUrl: j['imageUrl'] as String? ?? '',
    category: j['category'] as String? ?? 'عمومی',
    basePrice: (j['basePrice'] as num?)?.toInt() ?? 0,
    stock: (j['stock'] as num?)?.toInt() ?? 0,
    colorPrices: Map<String, int>.from(
      (j['colorPrices'] as Map? ?? {}).map(
        (k, v) => MapEntry(k.toString(), (v as num).toInt()),
      ),
    ),
  );
}

class SogandApp extends StatefulWidget {
  const SogandApp({super.key});
  @override
  State<SogandApp> createState() => _SogandAppState();
}

class _SogandAppState extends State<SogandApp> {
  int tab = 0;
  bool dark = false;
  Color accent = const Color(0xFFB45C83);
  String background = 'گرم و روشن';
  String cardNumber = '';
  final List<ShopProduct> products = [];
  final List<String> orders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('products');
    if (raw != null) {
      products.addAll((jsonDecode(raw) as List).map(
        (e) => ShopProduct.fromJson(Map<String, dynamic>.from(e))));
    } else {
      products.add(ShopProduct(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: 'نمونه محصول',
        description: 'توضیحات محصول را کامل کنید.',
        imageUrl: '',
        category: 'پوشاک',
        basePrice: 450000,
        stock: 8,
        colorPrices: {'مشکی': 450000, 'سفید': 470000},
      ));
    }
    cardNumber = p.getString('cardNumber') ?? '';
    dark = p.getBool('dark') ?? false;
    background = p.getString('background') ?? 'گرم و روشن';
    if (mounted) setState(() {});
    await _save();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('products',
      jsonEncode(products.map((e) => e.toJson()).toList()));
    await p.setString('cardNumber', cardNumber);
    await p.setBool('dark', dark);
    await p.setString('background', background);
  }

  void _editProduct([ShopProduct? product]) {
    showDialog(context: context, builder: (_) => ProductDialog(
      product: product,
      onSave: (p) {
        setState(() {
          final i = products.indexWhere((x) => x.id == p.id);
          if (i < 0) {
            products.insert(0, p);
          } else {
            products[i] = p;
          }
        });
        _save();
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: dark ? Brightness.dark : Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Online Shop Sogand',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor:
          dark ? const Color(0xFF17151A) : const Color(0xFFFFF8FA),
      ),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Online Shop Sogand',
                  style: TextStyle(fontWeight: FontWeight.w800)),
                Text('پنل مدیریت فروشگاه',
                  style: TextStyle(fontSize: 12)),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () => setState(() => dark = !dark),
                icon: Icon(dark ? Icons.light_mode : Icons.dark_mode),
              ),
            ],
          ),
          body: IndexedStack(index: tab, children: [
            _dashboard(), _products(), _orders(), _settings(),
          ]),
          floatingActionButton: tab == 1
            ? FloatingActionButton.extended(
                onPressed: () => _editProduct(),
                icon: const Icon(Icons.add),
                label: const Text('افزودن محصول'))
            : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (v) => setState(() => tab = v),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined), label: 'خانه'),
              NavigationDestination(
                icon: Icon(Icons.checkroom_outlined), label: 'محصولات'),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined), label: 'سفارش‌ها'),
              NavigationDestination(
                icon: Icon(Icons.tune), label: 'تنظیمات'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dashboard() => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent, accent.withOpacity(.68)]),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('به فروشگاه سوگند خوش آمدید',
              style: TextStyle(color: Colors.white,
                fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('مدیریت محصولات، قیمت‌ها و سفارش‌ها در یک جا',
              style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: _stat('تعداد محصولات',
          '${products.length}', Icons.inventory_2_outlined)),
        const SizedBox(width: 12),
        Expanded(child: _stat('سفارش‌ها',
          '${orders.length}', Icons.shopping_bag_outlined)),
      ]),
      const SizedBox(height: 18),
      _sectionTitle('دسترسی سریع'),
      ListTile(
        leading: const Icon(Icons.add_box_outlined),
        title: const Text('افزودن محصول جدید'),
        subtitle: const Text('عکس، توضیحات، رنگ و قیمت'),
        trailing: const Icon(Icons.chevron_left),
        onTap: () {
          setState(() => tab = 1);
          _editProduct();
        },
      ),
      ListTile(
        leading: const Icon(Icons.payments_outlined),
        title: const Text('روش‌های پرداخت'),
        subtitle: const Text('تنظیمات پرداخت'),
        trailing: const Icon(Icons.chevron_left),
        onTap: () => setState(() => tab = 3),
      ),
      const SizedBox(height: 12),
      const Text(
        'نسخه فعلی پنل سازنده است. اطلاعات این نسخه روی همین دستگاه ذخیره می‌شود.',
        style: TextStyle(fontSize: 12, color: Colors.grey)),
    ],
  );

  Widget _stat(String label, String value, IconData icon) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Icon(icon, color: accent, size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(
          fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ]),
    ),
  );

  Widget _sectionTitle(String s) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(s, style: const TextStyle(
      fontSize: 17, fontWeight: FontWeight.bold)),
  );

  Widget _products() => products.isEmpty
    ? const Center(child: Text('هنوز محصولی ثبت نشده است.'))
    : ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: products.length,
      itemBuilder: (_, i) {
        final p = products[i];
        return Card(
          child: ListTile(
            leading: _productImage(p.imageUrl),
            title: Text(p.name),
            subtitle: Text(
              '${p.category} • موجودی: ${p.stock}\n${_money(p.basePrice)} تومان'),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') _editProduct(p);
                if (v == 'delete') {
                  setState(() => products.removeAt(i));
                  _save();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('ویرایش')),
                PopupMenuItem(value: 'delete', child: Text('حذف')),
              ],
            ),
            onTap: () => _editProduct(p),
          ),
        );
      },
    );

  Widget _productImage(String url) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: url.isEmpty
      ? Container(
          width: 58, height: 58,
          color: accent.withOpacity(.12),
          child: Icon(Icons.checkroom, color: accent))
      : Image.network(
          url, width: 58, height: 58, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 58, height: 58,
            color: accent.withOpacity(.12),
            child: Icon(Icons.broken_image, color: accent))),
  );

  Widget _orders() => const Center(
    child: Text('هنوز سفارشی ثبت نشده است.'));

  Widget _settings() => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      _sectionTitle('ظاهر فروشگاه'),
      SwitchListTile(
        title: const Text('حالت تاریک'),
        value: dark,
        onChanged: (v) {
          setState(() => dark = v);
          _save();
        },
      ),
      ListTile(
        title: const Text('پس‌زمینه'),
        subtitle: Text(background),
        trailing: DropdownButton<String>(
          value: background,
          items: const ['گرم و روشن', 'یاسی', 'مینیمال'].map((e) =>
            DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() => background = v);
              _save();
            }
          },
        ),
      ),
      const Divider(),
      _sectionTitle('پرداخت'),
      const Text('درگاه آنلاین هنوز متصل نشده است.'),
      const SizedBox(height: 10),
      TextFormField(
        initialValue: cardNumber,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'شماره کارت فروشنده',
          border: OutlineInputBorder()),
        onChanged: (v) {
          cardNumber = v;
          _save();
        },
      ),
      const SizedBox(height: 10),
      const Text(
        'برای فعال‌سازی درگاه، باید از ارائه‌دهنده پرداخت پذیرندگی رسمی دریافت شود.',
        style: TextStyle(fontSize: 12, color: Colors.grey)),
    ],
  );

  String _money(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},');
}

class ProductDialog extends StatefulWidget {
  const ProductDialog({super.key, this.product, required this.onSave});
  final ShopProduct? product;
  final ValueChanged<ShopProduct> onSave;

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  final form = GlobalKey<FormState>();

  late final name = TextEditingController(
    text: widget.product?.name ?? '');
  late final description = TextEditingController(
    text: widget.product?.description ?? '');
  late final image = TextEditingController(
    text: widget.product?.imageUrl ?? '');
  late final category = TextEditingController(
    text: widget.product?.category ?? 'پوشاک');
  late final price = TextEditingController(
    text: '${widget.product?.basePrice ?? ''}');
  late final stock = TextEditingController(
    text: '${widget.product?.stock ?? 0}');
  late final colors = TextEditingController(
    text: widget.product?.colorPrices.entries
      .map((e) => '${e.key}:${e.value}').join(', ')
      ?? 'مشکی:450000, سفید:470000');

  @override
  void dispose() {
    for (final c in [
      name, description, image, category, price, stock, colors
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget field(
    TextEditingController c, String label,
    {int lines = 1, TextInputType? type}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: c,
        maxLines: lines,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder()),
        validator: (v) =>
          v == null || v.trim().isEmpty ? 'این فیلد الزامی است' : null,
      ),
    );

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: AlertDialog(
      title: Text(widget.product == null
        ? 'محصول جدید' : 'ویرایش محصول'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                field(name, 'نام محصول'),
                field(description, 'توضیحات', lines: 3),
                field(image, 'آدرس اینترنتی عکس'),
                field(category, 'دسته‌بندی'),
                field(price, 'قیمت پایه (تومان)',
                  type: TextInputType.number),
                field(stock, 'موجودی',
                  type: TextInputType.number),
                field(colors,
                  'قیمت هر رنگ — نمونه: مشکی:450000, سفید:470000',
                  lines: 2),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('انصراف')),
        FilledButton(
          onPressed: () {
            if (!form.currentState!.validate()) return;
            final parsed = <String, int>{};
            for (final part in colors.text.split(',')) {
              final pair = part.trim().split(':');
              if (pair.length == 2) {
                final n = int.tryParse(pair[1].trim());
                if (n != null) parsed[pair[0].trim()] = n;
              }
            }
            widget.onSave(ShopProduct(
              id: widget.product?.id ??
                DateTime.now().microsecondsSinceEpoch.toString(),
              name: name.text.trim(),
              description: description.text.trim(),
              imageUrl: image.text.trim(),
              category: category.text.trim(),
              basePrice: int.tryParse(price.text) ?? 0,
              stock: int.tryParse(stock.text) ?? 0,
              colorPrices: parsed,
            ));
            Navigator.pop(context);
          },
          child: const Text('ذخیره')),
      ],
    ),
  );
}
