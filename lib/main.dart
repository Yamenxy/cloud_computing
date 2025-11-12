import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Social Groups App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AddGroupPage(),
    );
  }
}

class AddGroupPage extends StatefulWidget {
  const AddGroupPage({super.key});

  @override
  State<AddGroupPage> createState() => _AddGroupPageState();
}

class _AddGroupPageState extends State<AddGroupPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController typeController = TextEditingController();

  Future<void> addGroup() async {
    if (nameController.text.isNotEmpty && typeController.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('groups').add({
        "name": nameController.text,
        "type": typeController.text,
      });

      nameController.clear();
      typeController.clear();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✅ Group Saved")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Group"),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ViewGroupsPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Group Name"),
            ),
            TextField(
              controller: typeController,
              decoration: const InputDecoration(labelText: "Group Type"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: addGroup, child: const Text("Submit")),
          ],
        ),
      ),
    );
  }
}

class ViewGroupsPage extends StatelessWidget {
  const ViewGroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Stored Groups")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('groups').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No Groups Found"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final group = docs[index];
              return ListTile(
                title: Text(group['name']),
                subtitle: Text(group['type']),
              );
            },
          );
        },
      ),
    );
  }
}
