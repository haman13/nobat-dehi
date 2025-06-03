import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/servicesList.dart';
import 'package:flutter_application_1/pages/models_list.dart';
import 'package:flutter_application_1/utils/supabase_config.dart';

class ManageServicesPage extends StatefulWidget {
  const ManageServicesPage({super.key});

  @override
  State<ManageServicesPage> createState() => _ManageServicesPageState();
}

class _ManageServicesPageState extends State<ManageServicesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> servicesList = [];
  List<Map<String, dynamic>> modelsList = List.from(models);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadServices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    try {
      final response = await SupabaseConfig.client
          .from('services')
          .select();
      setState(() {
        servicesList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      // اگر جدول خالی بود یا خطایی رخ داد، از لیست پیش‌فرض استفاده کن
      setState(() {
        servicesList = defaultServices.map((service) => {
          'label': service['label'],
          'icon': service['icon'].codePoint,
        }).toList();
      });
    }
  }

  Future<void> _saveServices() async {
    try {
      await SupabaseConfig.client.from('services').upsert(
        servicesList.map((service) => {
          'label': service['label'],
          'icon': service['icon'],
        }).toList(),
      );
    } catch (e) {
      throw Exception('خطا در ذخیره خدمات: $e');
    }
  }

  Future<void> _saveModels() async {
    try {
      await SupabaseConfig.client.from('models').upsert(
        modelsList.map((model) => {
          'name': model['name'],
          'price': model['price'],
          'duration': model['duration'],
          'description': model['description'],
          'service': model['service'],
        }).toList(),
      );
    } catch (e) {
      throw Exception('خطا در ذخیره مدل‌ها: $e');
    }
  }

  void _addService() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        IconData selectedIcon = Icons.cleaning_services;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('افزودن خدمت جدید'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'نام خدمت',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('انتخاب آیکون:'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildIconOption(Icons.cleaning_services, selectedIcon, (icon) {
                        setDialogState(() {
                          selectedIcon = icon;
                        });
                      }),
                      _buildIconOption(Icons.face, selectedIcon, (icon) {
                        setDialogState(() {
                          selectedIcon = icon;
                        });
                      }),
                      _buildIconOption(Icons.spa, selectedIcon, (icon) {
                        setDialogState(() {
                          selectedIcon = icon;
                        });
                      }),
                      _buildIconOption(Icons.brush, selectedIcon, (icon) {
                        setDialogState(() {
                          selectedIcon = icon;
                        });
                      }),
                      _buildIconOption(Icons.cut, selectedIcon, (icon) {
                        setDialogState(() {
                          selectedIcon = icon;
                        });
                      }),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('انصراف'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      try {
                        // اضافه کردن به Supabase
                        final response = await SupabaseConfig.client
                            .from('services')
                            .insert({
                              'label': nameController.text,
                              'icon': selectedIcon.codePoint,
                            })
                            .select()
                            .single();

                        setState(() {
                          servicesList.add(response);
                        });
                        
                        if (!mounted) return;
                        Navigator.pop(context);
                      } catch (e) {
                        if (!mounted) return;
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('خطا'),
                            content: Text('خطایی در افزودن خدمت رخ داد: $e'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('باشه'),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('افزودن'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addModel() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final priceController = TextEditingController();
        final durationController = TextEditingController();
        final descriptionController = TextEditingController();
        String selectedService = servicesList.first['label'];

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('افزودن مدل جدید'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedService,
                    decoration: const InputDecoration(
                      labelText: 'خدمت',
                      border: OutlineInputBorder(),
                    ),
                    items: servicesList.map((service) {
                      return DropdownMenuItem<String>(
                        value: service['label'] as String,
                        child: Text(service['label'] as String),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedService = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'نام مدل',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'قیمت (تومان)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: durationController,
                    decoration: const InputDecoration(
                      labelText: 'مدت زمان (دقیقه)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'توضیحات',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('انصراف'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty &&
                        priceController.text.isNotEmpty &&
                        durationController.text.isNotEmpty) {
                      setState(() {
                        modelsList.add({
                          'name': nameController.text,
                          'price': int.parse(priceController.text),
                          'duration': '${durationController.text} دقیقه',
                          'description': descriptionController.text,
                          'service': selectedService,
                        });
                      });
                      _saveModels();
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('افزودن'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteService(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف خدمت'),
        content: const Text('آیا از حذف این خدمت اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                servicesList.removeAt(index);
              });
              _saveServices();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _deleteModel(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف مدل'),
        content: const Text('آیا از حذف این مدل اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                modelsList.removeAt(index);
              });
              _saveModels();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Widget _buildIconOption(IconData icon, IconData selectedIcon, Function(IconData) onSelect) {
    final isSelected = icon == selectedIcon;
    return InkWell(
      onTap: () => onSelect(icon),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
          ),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.blue : Colors.grey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت خدمات و مدل‌ها'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'خدمات'),
            Tab(text: 'مدل‌ها'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildServicesList(),
          _buildModelsList(),
        ],
      ),
    );
  }

  Widget _buildServicesList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _addService,
            icon: const Icon(Icons.add),
            label: const Text('افزودن خدمت جدید'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: servicesList.length,
            itemBuilder: (context, index) {
              final service = servicesList[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(IconData(service['icon'], fontFamily: 'MaterialIcons')),
                  title: Text(service['label']),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteService(index),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModelsList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _addModel,
            icon: const Icon(Icons.add),
            label: const Text('افزودن مدل جدید'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: servicesList.length,
            itemBuilder: (context, serviceIndex) {
              final service = servicesList[serviceIndex];
              final serviceModels = modelsList.where((model) => model['service'] == service['label']).toList();
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExpansionTile(
                  title: Text(service['label']),
                  subtitle: Text('${serviceModels.length} مدل'),
                  children: serviceModels.asMap().entries.map((entry) {
                    final modelIndex = modelsList.indexOf(entry.value);
                    return ListTile(
                      title: Text(entry.value['name']),
                      subtitle: Text('${entry.value['price']} تومان - ${entry.value['duration']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteModel(modelIndex),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
} 