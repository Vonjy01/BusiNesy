// lib/widget/generic_tab_view.dart
import 'package:flutter/material.dart';

import 'package:project6/widget/generic_tabview.dart';
import 'package:project6/widget/vente.dart';

class VentePage extends StatelessWidget {
  const VentePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const GenericTabView(
      headerTitle: 'Historique des ventes',
      tabTitles: ['Tous', 'Réservé', 'Incomplète'],
      tabViews: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: HistoriqueVente(),
        ),
        VenteReserver(),
        VenteIncomplete(),
      ],
     
    );
  }
}

class HistoriqueVente extends StatelessWidget {
  const HistoriqueVente({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        children: List.generate(10, (i) {
          return  Vente(
            id: 'Produit $i',
            date: 'Aujourd\'hui, 14:30',
            items: 3,
            client: 'Rabe',
            amount: 70000,
            status: 'Complété',
          );
        }));
  }
}
class VenteReserver extends StatelessWidget {
  const VenteReserver({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        children: List.generate(10, (i) {
          return  Vente(
            id: 'Produit ${10+i} ',
            date: 'Aujourd\'hui, 14:30',
            items: 3,
            client: 'Vonjy',
            amount: 50000,
            status: 'Reservé',
          );
        }));
  }
}
class VenteIncomplete extends StatelessWidget {
  const VenteIncomplete({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        children: List.generate(10, (i) {
          return  Vente(
            id: 'Produit ${10+i} ',
            date: 'Aujourd\'hui, 14:30',
            items: 3,
            client: 'Rakoto',
            amount: 50000,
            status: 'Incomplète',
          );
        }));
  }
}


      // Expanded(
            //   child: ListView(
            //     children: const [
            //       Vente(
            //         id: '#000123',
            //         date: 'Aujourd\'hui, 14:30',
            //         items: 3,
            //         amount: 129.97,
            //         status: 'Complété',
            //       ),
            //       Vente(
            //         id: '#000122',
            //         date: 'Aujourd\'hui, 11:15',
            //         items: 2,
            //         amount: 69.98,
            //         status: 'Complété',
            //       ),
            //       Vente(
            //         id: '#000121',
            //         date: 'Hier, 16:45',
            //         items: 1,
            //         amount: 89.99,
            //         status: 'Complété',
            //       ),
            //       Vente(
            //         id: '#000120',
            //         date: 'Hier, 10:30',
            //         items: 4,
            //         amount: 199.96,
            //         status: 'Complété',
            //       ),
            //     ],
            //   ),
            // ),