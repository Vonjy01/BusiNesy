// generic_tabview.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/auth_controller.dart';
import 'package:project6/utils/constant.dart';
import 'package:project6/widget/Header.dart';
import 'package:project6/widget/app_drawer.dart';

class GenericTabView extends ConsumerWidget {
  final String headerTitle;
  final List<String> tabTitles;
  final List<Widget> tabViews;
  final Widget? bottomButton;
  final double? tabBarOffsetY;
  final EdgeInsets? tabBarMargin;

  const GenericTabView({
    super.key,
    required this.headerTitle,
    required this.tabTitles,
    required this.tabViews,
    this.bottomButton,
    this.tabBarOffsetY = -40,
    this.tabBarMargin = const EdgeInsets.symmetric(horizontal: 10),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    
    return DefaultTabController(
      length: tabTitles.length,
      child: Scaffold(
        drawer: user != null ? AppDrawer(user: user) : null,
        body: Column(
          children: [
            Header(title: headerTitle),
            
            Transform.translate(
              offset: Offset(0, tabBarOffsetY ?? -40),
              child: Container(
                margin: tabBarMargin,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme_light,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // ← AJOUTEZ CETTE LIGNE
                  children: [
                    Material(
                      color: Colors.transparent,
                      elevation: 0,
                      child: TabBar(
                        isScrollable: true,
                        labelColor: background_theme,
                        unselectedLabelColor: Colors.grey,
                        indicator: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: background_theme, width: 5),
                          ),
                        ),
                        overlayColor: MaterialStateProperty.all(Colors.transparent),
                        dividerColor: Colors.transparent,
                        tabs: tabTitles.map((title) => Tab(
                          child: Align( // ← AJOUTEZ CET ALIGN
                            alignment: Alignment.centerLeft,
                            child: Text(title),
                          ),
                        )).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: TabBarView(
                children: tabViews,
              ),
            ),
            
            if (bottomButton != null) bottomButton!,
          ],
        ),
      ),
    );
  }
}