import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(GardiropPlusApp());
}

class GardiropPlusApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gardırop+ (Demo)',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: HomeScreen(),
    );
  }
}

class Item {
  String id;
  String path;
  String category;
  Item({required this.id, required this.path, required this.category});
  Map<String,dynamic> toJson() => {'id': id, 'path': path, 'category': category};
  static Item fromJson(Map<String,dynamic> j) => Item(id: j['id'], path: j['path'], category: j['category']);
}

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Item> items = [];
  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  Future<Directory> appDir() async => await getApplicationDocumentsDirectory();

  Future<void> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString('items');
    if (s != null) {
      final arr = jsonDecode(s) as List;
      setState(() {
        items = arr.map((e) => Item.fromJson(e)).toList();
      });
    }
  }

  Future<void> saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    final s = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString('items', s);
  }

  Future<void> pickImage(ImageSource src) async {
    final XFile? file = await picker.pickImage(source: src, maxWidth: 1200, maxHeight: 1600, imageQuality: 85);
    if (file == null) return;
    final dir = await appDir();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final ext = file.path.split('.').last;
    final dest = File('${dir.path}/$id.$ext');
    await dest.writeAsBytes(await file.readAsBytes());
    // ask category
    final category = await showDialog<String>(
      context: context,
      builder: (_) => CategoryDialog(),
    );
    if (category == null) {
      // cleanup
      await dest.delete();
      return;
    }
    final item = Item(id: id, path: dest.path, category: category);
    setState(() {
      items.add(item);
    });
    await saveItems();
  }

  void removeItem(Item it) async {
    final f = File(it.path);
    if (await f.exists()) await f.delete();
    setState(() {
      items.removeWhere((e) => e.id == it.id);
    });
    await saveItems();
  }

  // Simple rule-based combo: pick one top/upper and one bottom/alt or any two different categories
  List<Item> generateCombo() {
    if (items.length < 2) return [];
    // prefer different categories
    for (var a in items) {
      for (var b in items) {
        if (a.id != b.id && a.category != b.category) {
          return [a, b];
        }
      }
    }
    // fallback: first two
    return items.sublist(0, 2);
  }

  @override
  Widget build(BuildContext context) {
    final combo = generateCombo();
    return Scaffold(
      appBar: AppBar(
        title: Text('Gardırop+ (Demo)'),
        actions: [
          IconButton(
            icon: Icon(Icons.image_search),
            onPressed: () {
              setState(() {});
            },
            tooltip: 'Öneri Yenile',
          ),
          IconButton(
            icon: Icon(Icons.delete_sweep),
            onPressed: () async {
              final ok = await showDialog<bool>(context: context, builder: (_) => ConfirmDialog()) ?? false;
              if (ok) {
                for (var it in items) {
                  final f = File(it.path);
                  if (await f.exists()) await f.delete();
                }
                setState(() { items.clear(); });
                await saveItems();
              }
            },
            tooltip: 'Tümünü Sil',
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 12),
          Text('Kombin Önerisi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          if (combo.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text('Henüz yeterli kıyafet yok. Fotoğraf ekleyin.'),
            )
          else
            Card(
              margin: EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Row(
                  children: combo.map((it) => Expanded(child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Image.file(File(it.path), height: 120, fit: BoxFit.cover),
                  ))).toList(),
                ),
              ),
            ),
          SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: items.map((it) => GestureDetector(
                  onLongPress: () async {
                    final action = await showModalBottomSheet<String>(context: context, builder: (_) =>
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        ListTile(title: Text('Sil'), onTap: () => Navigator.pop(context, 'delete')),
                        ListTile(title: Text('Detay'), onTap: () => Navigator.pop(context, 'detail')),
                      ]),
                    );
                    if (action == 'delete') removeItem(it);
                    else if (action == 'detail') {
                      await showDialog(context: context, builder: (_) => DetailDialog(item: it));
                    }
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(File(it.path), fit: BoxFit.cover),
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: Container(color: Colors.black54, padding: EdgeInsets.symmetric(vertical: 4), child: Text(it.category, textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 12))),
                      )
                    ],
                  ),
                )).toList(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(context: context, builder: (_) => SizedBox(height:140, child: Column(children:[
          ListTile(leading: Icon(Icons.camera_alt), title: Text('Fotoğraf Çek'), onTap: (){ Navigator.pop(context); pickImage(ImageSource.camera); }),
          ListTile(leading: Icon(Icons.photo), title: Text('Galeriden Seç'), onTap: (){ Navigator.pop(context); pickImage(ImageSource.gallery); }),
        ]))),
        child: Icon(Icons.add),
        tooltip: 'Kıyafet Ekle',
      ),
    );
  }
}

class CategoryDialog extends StatefulWidget {
  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}
class _CategoryDialogState extends State<CategoryDialog> {
  String? sel;
  final List<String> cats = ['Üst','Alt','Ayakkabı','Aksesuar','Dış Giyim','Elbise'];
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Kategori Seçiniz'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: cats.map((c) => RadioListTile<String>(title: Text(c), value: c, groupValue: sel, onChanged: (v)=>setState(()=>sel=v))).toList(),
        ),
      ),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(context,null), child: Text('İptal')),
        ElevatedButton(onPressed: ()=>Navigator.pop(context, sel), child: Text('Kaydet')),
      ],
    );
  }
}

class ConfirmDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Tümünü Sil?'),
      content: Text('Tüm kayıtlı kıyafetler silinecek. Devam edilsin mi?'),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(context,false), child: Text('Hayır')),
        ElevatedButton(onPressed: ()=>Navigator.pop(context,true), child: Text('Evet')),
      ],
    );
  }
}

class DetailDialog extends StatelessWidget {
  final Item item;
  DetailDialog({required this.item});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Ürün Detayı'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Image.file(File(item.path), height: 180, fit: BoxFit.cover),
        SizedBox(height:8),
        Text('Kategori: ${item.category}'),
        SizedBox(height:4),
        Text('ID: ${item.id}'),
      ]),
      actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: Text('Kapat'))],
    );
  }
}