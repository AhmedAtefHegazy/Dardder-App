import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/product.dart';
import '../../models/category.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../config/api_config.dart';

class ProductFormDialog extends StatefulWidget {
  final Product? product;

  const ProductFormDialog({
    Key? key,
    this.product,
  }) : super(key: key);

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _imageUrlController;
  String? _selectedCategoryId;
  late bool _isAvailable;
  bool _isLoading = false;
  File? _imageFile;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name);
    _descriptionController =
        TextEditingController(text: widget.product?.description);
    _priceController = TextEditingController(
      text: widget.product?.price.toStringAsFixed(2),
    );
    _stockController = TextEditingController(
      text: widget.product?.stockQuantity.toString(),
    );
    _imageUrlController = TextEditingController(text: widget.product?.imageUrl);
    _selectedCategoryId = widget.product?.categoryId;
    _isAvailable = widget.product?.inStock ?? true;

    // Load categories when dialog opens
    Future.microtask(() {
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });

        // Upload the image
        await _uploadImage();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    setState(() => _isLoading = true);

    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/api/products/upload-image'),
      );

      // Add file to request
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        _imageFile!.path,
      ));

      // Send request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        setState(() {
          _imageUrlController.text = jsonResponse['imageUrl'];
        });
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(),
                        prefixText: '\$',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a price';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return 'Please enter a valid price';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(
                        labelText: 'Stock',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter stock';
                        }
                        final stock = int.tryParse(value);
                        if (stock == null || stock < 0) {
                          return 'Invalid stock';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Consumer<CategoryProvider>(
                builder: (context, categoryProvider, child) {
                  if (categoryProvider.isLoading) {
                    return const CircularProgressIndicator();
                  }

                  final categories = categoryProvider.categories;
                  if (categories.isEmpty) {
                    return const Text(
                        'No categories available. Please create a category first.');
                  }

                  return DropdownButtonFormField(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value as String;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Choose Product Image'),
                    ),
                  ),
                ],
              ),
              if (_imageFile != null ||
                  _imageUrlController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _imageFile != null
                      ? Image.file(
                          _imageFile!,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          _imageUrlController.text,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.error),
                        ),
                ),
              ],
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Available'),
                value: _isAvailable,
                onChanged: (value) => setState(() => _isAvailable = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final categoryProvider = context.read<CategoryProvider>();
    final selectedCategory = categoryProvider.categories.firstWhere(
      (cat) => cat.id == _selectedCategoryId,
      orElse: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selected category not found. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return Category(id: '', name: '', description: '');
      },
    );

    // Don't proceed if category is invalid
    if (selectedCategory.id.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final product = Product(
        id: widget.product?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        stockQuantity: int.parse(_stockController.text),
        categoryId: selectedCategory.id,
        categoryName: selectedCategory.name,
        imageUrl:
            _imageUrlController.text.isEmpty ? '' : _imageUrlController.text,
        inStock: _isAvailable,
      );

      final productProvider = context.read<ProductProvider>();

      if (widget.product == null) {
        await productProvider.createProduct(product);
      } else {
        await productProvider.updateProduct(widget.product!.id, product);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.product == null
                  ? 'Product created successfully'
                  : 'Product updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the products list
        await productProvider.refreshProducts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
