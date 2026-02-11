import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'giver_home_screen.dart';

class PickupRequestScreen extends StatefulWidget {
  final String imageUrl;

  const PickupRequestScreen({super.key, required this.imageUrl});

  @override
  State<PickupRequestScreen> createState() => _PickupRequestScreenState();
}

class _PickupRequestScreenState extends State<PickupRequestScreen> {
  final materialCtrl = TextEditingController();
  final confirmAddressCtrl = TextEditingController();
  final weightCtrl = TextEditingController();
  final _nameEditController = TextEditingController();

  String currentAddress = '';
  String name = '';
  String phone = '';
  bool sameAsCurrent = true;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserAddress();
  }

  Future<void> _loadUserAddress() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('giverusers')
        .doc(uid)
        .get();

    setState(() {
      currentAddress = doc.data()?['address'] ?? '';
      name = doc.data()?['name'] ?? 'Unknown';
      phone = doc.data()?['phone'] ?? '';
      confirmAddressCtrl.text = currentAddress;
      _nameEditController.text = name;
      loading = false;
    });
  }

  Future<void> _sendPickupRequest() async {
    if (materialCtrl.text.isEmpty ||
        confirmAddressCtrl.text.isEmpty ||
        weightCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Fill all fields')));
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('pickup_requests').add({
      'giverId': uid,
      'giverName': _nameEditController.text.trim(),
      'giverPhone': phone,
      'material': materialCtrl.text.trim(),
      'address': confirmAddressCtrl.text.trim(),
      'approxWeight': weightCtrl.text.trim(),
      'weight': double.tryParse(weightCtrl.text.trim()) ?? 0.0,
      'imageUrl': widget.imageUrl, // 🔥 IMAGE URL
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: const Text('Request sent to the collector'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => const GiverHomeScreen()),
                (route) => false,
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Pickup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🔥 IMAGE PREVIEW
            Center(
              child: Image.network(
                widget.imageUrl,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),

            const Text('Your Name'),
            TextField(controller: _nameEditController),

            const SizedBox(height: 16),
            const Text('Material Type'),
            TextField(controller: materialCtrl),

            const SizedBox(height: 16),
            const Text('Current Address'),
            Text(currentAddress),

            CheckboxListTile(
              value: sameAsCurrent,
              title: const Text('Same as current address'),
              onChanged: (v) {
                setState(() {
                  sameAsCurrent = v!;
                  if (v) confirmAddressCtrl.text = currentAddress;
                });
              },
            ),

            if (!sameAsCurrent)
              TextField(
                controller: confirmAddressCtrl,
                decoration:
                    const InputDecoration(labelText: 'Confirm Address'),
              ),

            const SizedBox(height: 16),
            const Text('Approx Weight (kg)'),
            TextField(
              controller: weightCtrl,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sendPickupRequest,
                child: const Text('Send Pickup Request'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
