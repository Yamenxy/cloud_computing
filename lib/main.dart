import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Background message handler - MUST be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📨 Background Message: ${message.messageId}');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Data: ${message.data}');
  
  // Store message in Firestore
  await _storeMessageInFirestore(message);
  
  // Handle topic subscription/unsubscription
  if (message.data.containsKey('subscribeToTopic')) {
    String topic = message.data['subscribeToTopic'];
    await FirebaseMessaging.instance.subscribeToTopic(topic);
    print('✅ Subscribed to topic: $topic (Background)');
  }
  
  if (message.data.containsKey('unsubscribeToTopic')) {
    String topic = message.data['unsubscribeToTopic'];
    await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    print('❌ Unsubscribed from topic: $topic (Background)');
  }
}

// Helper function to store message in Firestore
Future<void> _storeMessageInFirestore(RemoteMessage message) async {
  try {
    await FirebaseFirestore.instance.collection('notifications').add({
      'messageId': message.messageId,
      'sentTime': message.sentTime?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'receivedTime': DateTime.now().toIso8601String(),
      'notification': {
        'title': message.notification?.title,
        'body': message.notification?.body,
        'android': message.notification?.android != null ? {
          'channelId': message.notification?.android?.channelId,
          'priority': message.notification?.android?.priority.toString(),
        } : null,
      },
      'data': message.data,
    });
    print('💾 Message stored in Firestore');
  } catch (e) {
    print('❌ Error storing message: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
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
  String? fcmToken;
  final List<String> _messages = [];

  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    try {
      // Request permission
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      print('📱 User granted permission: ${settings.authorizationStatus}');
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? token = await FirebaseMessaging.instance.getToken();
        setState(() {
          fcmToken = token;
        });
        print('🔑 FCM Token: $token');
      }

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📩 Foreground Message Received!');
        print('Title: ${message.notification?.title}');
        print('Body: ${message.notification?.body}');
        print('Data: ${message.data}');
        
        // Store message in Firestore
        _storeMessageInFirestore(message);
        
        // Handle topic subscription/unsubscription
        if (message.data.containsKey('subscribeToTopic')) {
          String topic = message.data['subscribeToTopic'];
          FirebaseMessaging.instance.subscribeToTopic(topic);
          print('✅ Subscribed to topic: $topic (Foreground)');
        }
        
        if (message.data.containsKey('unsubscribeToTopic')) {
          String topic = message.data['unsubscribeToTopic'];
          FirebaseMessaging.instance.unsubscribeFromTopic(topic);
          print('❌ Unsubscribed from topic: $topic (Foreground)');
        }
        
        setState(() {
          _messages.insert(0, 
            '📩 ${message.notification?.title ?? "New Message"}\n'
            '${message.notification?.body ?? message.data.toString()}\n'
            'Time: ${DateTime.now().toString().substring(11, 19)}'
          );
        });

        // Show dialog when message arrives in foreground
        if (message.notification != null) {
          _showMessageDialog(
            message.notification!.title ?? 'Notification',
            message.notification!.body ?? 'No body'
          );
        }
      });

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('💬 Notification tapped (from background)');
        _showMessageDialog(
          message.notification?.title ?? 'Notification',
          'You tapped on: ${message.notification?.body ?? message.data.toString()}'
        );
      });

      // Check if app was opened from a terminated state via notification
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        print('🚀 App opened from terminated state via notification');
        _showMessageDialog(
          initialMessage.notification?.title ?? 'Notification',
          'App launched from: ${initialMessage.notification?.body ?? initialMessage.data.toString()}'
        );
      }
      
    } catch (e) {
      print('❌ Error setting up FCM: $e');
    }
  }

  void _showMessageDialog(String title, String body) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

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
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsHistoryPage()),
              );
            },
          ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Messages Section
            if (_messages.isNotEmpty) ...[
              Text(
                '📨 Received Messages (${_messages.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 15,
                        child: Text('${index + 1}'),
                      ),
                      title: Text(
                        _messages[index],
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
            ],
            
            // Original Form Section
            Text(
              'Add Group',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Group Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: typeController,
              decoration: const InputDecoration(
                labelText: "Group Type",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: addGroup,
              child: const Text("Submit"),
            ),
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

class NotificationsHistoryPage extends StatelessWidget {
  const NotificationsHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications History"),
        backgroundColor: Colors.purple,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('receivedTime', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 100,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No Notifications Yet',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Send a test message from Firebase Console',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return Column(
            children: [
              // Statistics Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.deepPurple.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      'Total',
                      notifications.length.toString(),
                      Icons.all_inbox,
                    ),
                    _buildStatCard(
                      'Today',
                      _getTodayCount(notifications).toString(),
                      Icons.today,
                    ),
                  ],
                ),
              ),
              
              // Notifications List
              Expanded(
                child: ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index].data() as Map<String, dynamic>;
                    final notification = notif['notification'] as Map<String, dynamic>?;
                    final data = notif['data'] as Map<String, dynamic>?;
                    final receivedTime = notif['receivedTime'] as String?;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 2,
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple.shade100,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: Colors.purple.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          notification?['title'] ?? 'No Title',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              notification?['body'] ?? 'No Body',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(receivedTime),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                        children: [
                          if (data != null && data.isNotEmpty)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.all(12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.data_object, 
                                        size: 16, 
                                        color: Colors.blue.shade700,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Data Payload:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ...data.entries.map((entry) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      '${entry.key}: ${entry.value}',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 13,
                                        color: Colors.blue.shade900,
                                      ),
                                    ),
                                  )).toList(),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  int _getTodayCount(List<QueryDocumentSnapshot> notifications) {
    final today = DateTime.now();
    return notifications.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final receivedTime = data['receivedTime'] as String?;
      if (receivedTime == null) return false;
      
      final notifDate = DateTime.parse(receivedTime);
      return notifDate.year == today.year &&
             notifDate.month == today.month &&
             notifDate.day == today.day;
    }).length;
  }

  String _formatTime(String? timeString) {
    if (timeString == null) return 'Unknown time';
    
    try {
      final dateTime = DateTime.parse(timeString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return timeString;
    }
  }
}
