import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import ' api_service.dart';

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
  final _orderEndDateController = TextEditingController();
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
      _itemDelEndTimestampController.text = _formatDateTime(widget.item!['item_del_end_timestamp']) ?? '';
      _orderEndDateController.text = _formatDateTime(widget.item!['order_end_date']) ?? '';
      _existingImageUrl = 'http://34.16.177.102:4000/' + (widget.item!['item_photo'] ?? '');
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
    _orderEndDateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      if (await Permission.photos.request().isGranted) {
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
        setState(() {
          if (pickedFile != null) {
            _itemImage = File(pickedFile.path);
          } else {
            print('No image selected.');
          }
        });
      } else {
        print('Images permission denied');
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

        String orderEndDate = _orderEndDateController.text.isEmpty
            ? _itemDelEndTimestampController.text
            : _orderEndDateController.text;

        // Validate that orderEndDate is not greater than itemDelEndTimestamp
        if (DateTime.parse(orderEndDate).isAfter(DateTime.parse(_itemDelEndTimestampController.text))) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Order end date cannot be greater than delivery end timestamp')));
          return;
        }
        // Validate that orderEndDate is not equal to or before current time
        if (DateTime.parse(orderEndDate).isBefore(DateTime.now())) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Order end date cannot be set to current time or earlier')));
          return;
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
            orderEndDate: orderEndDate,
            itemPhoto: imageFile,
          );
          Navigator.pop(context);
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
            orderEndDate: orderEndDate,
            itemPhoto: imageFile,
          );
        }
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to update item')));
      }
    }
  }

  Future<void> _selectDateTime(TextEditingController controller) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
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
    try {
      final dateTime = DateFormat("yyyy-MM-ddTHH:mm:ssZ").parse(dateTimeStr);
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
    } catch (e) {
      print('Error parsing date/time string: $e');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Add New Item' : 'Edit Item'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _itemNameController,
                        decoration: InputDecoration(
                          labelText: 'Item Name',
                          labelStyle: TextStyle(color: Colors.orange),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the item name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _itemDescController,
                        decoration: InputDecoration(
                          labelText: 'Item Description',
                          labelStyle: TextStyle(color: Colors.orange),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the item description';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _itemQuantityController,
                        decoration: InputDecoration(
                          labelText: 'Item Quantity',
                          labelStyle: TextStyle(color: Colors.orange),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the item quantity';
                          } else if (int.tryParse(value) == null || int.parse(value) <= 0) {
                            return 'Quantity must be a positive integer';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _itemPriceController,
                        decoration: InputDecoration(
                          labelText: 'Item Price',
                          labelStyle: TextStyle(color: Colors.orange),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the item price';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _itemDelStartTimestampController,
                        decoration: InputDecoration(
                          labelText: 'Delivery Start Time',
                          labelStyle: TextStyle(color: Colors.orange),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.calendar_today),
                            onPressed: () => _selectDateTime(_itemDelStartTimestampController),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the delivery start time';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _itemDelEndTimestampController,
                        decoration: InputDecoration(
                          labelText: 'Delivery End Time',
                          labelStyle: TextStyle(color: Colors.orange),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.calendar_today),
                            onPressed: () => _selectDateTime(_itemDelEndTimestampController),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the delivery end time';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _orderEndDateController,
                        decoration: InputDecoration(
                          labelText: 'Order End Date (Optional)',
                          labelStyle: TextStyle(color: Colors.orange),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.calendar_today),
                            onPressed: () => _selectDateTime(_orderEndDateController),
                          ),
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty && DateTime.tryParse(value) == null) {
                            return 'Invalid date format';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10),
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: _itemImage != null
                              ? FileImage(_itemImage!)
                              : _existingImageUrl != null
                              ? NetworkImage(_existingImageUrl!) as ImageProvider
                              : AssetImage('assets/placeholder.png'),
                          child: _itemImage == null && _existingImageUrl == null
                              ? Icon(Icons.add_a_photo, size: 50, color: Colors.orange)
                              : null,
                        ),
                      ),
                      if (_existingImageUrl != null)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _itemImage = null;
                              _existingImageUrl = null;
                            });
                          },
                          icon: Icon(Icons.delete, color: Colors.red),
                          label: Text("Remove Image", style: TextStyle(color: Colors.red)),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _saveItem,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text('Save Item', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
