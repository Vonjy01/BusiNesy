// import 'package:flutter/material.dart';

// import 'package:project6/widget/Header.dart';
// import 'package:project6/widget/app_drawer.dart';
// import 'package:project6/widget/client_list.dart';

// class ClientPage extends StatelessWidget {
//   const ClientPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return  Scaffold(
//       drawer: AppDrawer(),
//         body: Column(
//   children: [
//     Header(title: 'Liste des clients'),
//     Expanded(
//       child: ListView.builder(
//         itemCount: 10,
//         itemBuilder: (context, i) => Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 10),
//           child: ClientList(nom: 'Client ${i + 1}'),
//         ),
//       ),
//     ),
//   ],
// )

//     );
//   }
// }