import 'package:flutter/material.dart';
import 'package:project6/models/user_model.dart';
import 'package:project6/services/database_helper.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({Key? key}) : super(key: key);

  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  List<User> users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('users'); // <-- nom de ta table
    setState(() {
      users = result.map((json) => User.fromJson(json)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Liste des utilisateurs")),
      body: users.isEmpty
          ? const Center(child: Text("Aucun utilisateur trouvé"))
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  child: ListTile(
                    title: Text(user.nom),
                    subtitle: Text("Tel: ${user.telephone}\nCode: ${user.motDePasse}"),
                  ),
                );
              },
            ),
    );
  }
}
