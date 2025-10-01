// import 'package:flutter/material.dart';
// import 'package:project6/widget/arrivage_list.dart';

// class ProductsScreen extends StatelessWidget {
//   const ProductsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(16),
//           child: Row(
//             children: [
//               Expanded(
//                 child: TextField(
//                   decoration: InputDecoration(
//                     hintText: 'Filtrer les produits...',
//                     prefixIcon: const Icon(Icons.search),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                       borderSide: BorderSide.none,
//                     ),
//                     filled: true,
//                     fillColor: Colors.grey[200],
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 10),
//               IconButton(
//                 icon: const Icon(Icons.filter_alt_outlined),
//                 onPressed: () {},
//               ),
//             ],
//           ),
//         ),
//         Expanded(
//           child: ListView(
//             padding: const EdgeInsets.only(bottom: 80),
//             children: const [
//               ArrivageList(
//                 name: 'T-Shirt Blanc',
//                 category: 'Vêtements',
//                 stock: 42,
//               ),
//               ArrivageList(
//                 name: 'Jean Slim Noir',
//                 category: 'Vêtements',
//                 stock: 15,
//               ),
//               ArrivageList(
//                 name: 'Chaussures de Sport',
//                 category: 'Chaussures',
//                 stock: 8,
//               ),
//               ArrivageList(
//                 name: 'Casquette Baseball',
//                 category: 'Accessoires',
//                 stock: 3,
//               ),
//               ArrivageList(
//                 name: 'Sac à Dos',
//                 category: 'Accessoires',
//                 stock: 12,
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }