import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:food_buddies/pages/ api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddItemPage extends StatefulWidget {
  final Map<String, dynamic>? item;

  AddItemPage({this.item});

  @override
  _AddItemPageState createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _itemDescController = TextEditingController();
  final _itemQuantityController = TextEditingController();
  final _itemPriceController = TextEditingController();
  final _itemDelStartTimestampController = TextEditingController();
  final _itemDelEndTimestampController = TextEditingController();
  File? _itemImage;
  final picker = ImagePicker();
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _itemNameController.text = widget.item!['item_name'] ?? '';
      _itemDescController.text = widget.item!['item_desc'] ?? '';
      _itemQuantityController.text = widget.item!['item_quantity'].toString() ?? '';
      _itemPriceController.text = widget.item!['item_price'].toString() ?? '';
      _itemDelStartTimestampController.text = _formatDateTime(widget.item!['item_del_start_timestamp']) ?? '';
      print("The start time is : " + widget.item!['item_del_start_timestamp']);
      _itemDelEndTimestampController.text = _formatDateTime(widget.item!['item_del_end_timestamp']) ?? '';
      _existingImageUrl = APIService.baseUrl + (widget.item!['item_photo'] ?? '');
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _itemDescController.dispose();
    _itemQuantityController.dispose();
    _itemPriceController.dispose();
    _itemDelStartTimestampController.dispose();
    _itemDelEndTimestampController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      if (await Permission.storage.request().isGranted) {
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
        setState(() {
          if (pickedFile != null) {
            _itemImage = File(pickedFile.path);
          } else {
            print('No image selected.');
          }
        });
      } else {
        print('Storage permission denied');
      }
    } else {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      setState(() {
        if (pickedFile != null) {
          _itemImage = File(pickedFile.path);
        } else {
          print('No image selected.');
        }
      });
    }
  }

  Future<String> getPhoneNumber() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('phoneNumber') ?? '';
  }

  Future<File?> _getImageFileFromUrl(String imageUrl) async {
    try {
      final response = await HttpClient().getUrl(Uri.parse(imageUrl));
      final imageData = await response.close();
      final bytes = await consolidateHttpClientResponseBytes(imageData);
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/${imageUrl.split('/').last}';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      print('Error fetching image: $e');
      return null;
    }
  }

  Future<void> _saveItem() async {
    if (_formKey.currentState!.validate()) {
      try {
        final APIService apiService = APIService();
        File? imageFile = _itemImage;
        if (imageFile == null && _existingImageUrl != null) {
          imageFile = await _getImageFileFromUrl(_existingImageUrl!);
        }

        if (widget.item == null || widget.item!['item_id'] == null) {
          // Create a new item
          await apiService.addItem(
            context: context,
            sellerPhone: await getPhoneNumber(),
            itemName: _itemNameController.text,
            itemDesc: _itemDescController.text,
            itemQuantity: _itemQuantityController.text,
            itemPrice: _itemPriceController.text,
            itemDelStartTimestamp: _itemDelStartTimestampController.text,
            itemDelEndTimestamp: _itemDelEndTimestampController.text,
            itemPhoto: imageFile,
          );
        } else {
          // Update existing item
          await apiService.updateItem(
            context: context,
            itemId: widget.item!['item_id'],
            itemName: _itemNameController.text,
            itemDesc: _itemDescController.text,
            itemQuantity: _itemQuantityController.text,
            itemPrice: _itemPriceController.text,
            itemDelStartTimestamp: _itemDelStartTimestampController.text,
            itemDelEndTimestamp: _itemDelEndTimestampController.text,
            itemPhoto: imageFile,
          );
        }
        if (!mounted) return;
        Navigator.pop(context);
      } catch (e) {
        print('Error saving item: $e');
      }
    }
  }

  Future<void> _selectDateTime(TextEditingController controller) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final DateTime fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          controller.text = DateFormat('yyyy-MM-dd HH:mm').format(fullDateTime);
        });
      }
    }
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) {
      return '';
    }
    final dateTime = DateFormat("yyyy-MM-ddTHH:mm:ssZ").parse(dateTimeStr, true);
    if (dateTime == null) {
      return '';
    }
    final formatter = DateFormat('EEE dd MMM hh:mma');
    return formatter.format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Add New Item' : 'Edit Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _itemNameController,
                decoration: InputDecoration(labelText: 'Item Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the item name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _itemDescController,
                decoration: InputDecoration(labelText: 'Item Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the item description';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _itemQuantityController,
                decoration: InputDecoration(labelText: 'Item Quantity'),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the item quantity';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _itemPriceController,
                decoration: InputDecoration(labelText: 'Item Price'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the item price';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _itemDelStartTimestampController,
                decoration: InputDecoration(
                  labelText: 'Delivery Start Timestamp',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _selectDateTime(_itemDelStartTimestampController),
                  ),
                ),
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the delivery start time';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _itemDelEndTimestampController,
                decoration: InputDecoration(
                  labelText: 'Delivery End Timestamp',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _selectDateTime(_itemDelEndTimestampController),
                  ),
                ),
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the delivery end time';
                  }
                  DateTime? startDateTime = DateTime.tryParse(_itemDelStartTimestampController.text);
                  DateTime? endDateTime = DateTime.tryParse(value);
                  if (startDateTime != null && endDateTime != null &&
                      (endDateTime.isBefore(startDateTime) || endDateTime.isBefore(DateTime.now()) || endDateTime == startDateTime)) {
                    return 'Ensure that it is always after delivery start time and current time';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              _itemImage == null
                  ? _existingImageUrl != null
                  ? Image.network(_existingImageUrl!)
                  : Text('No image selected.')
                  : Image.file(_itemImage!),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text('Pick Image'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveItem,
                child: Text(widget.item == null ? 'Add Item' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
