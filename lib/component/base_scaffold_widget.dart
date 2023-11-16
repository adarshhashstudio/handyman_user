import 'package:booking_system_flutter/component/back_widget.dart';
import 'package:booking_system_flutter/component/base_scaffold_body.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../utils/constant.dart';

class AppScaffold extends StatelessWidget {
  final String? appBarTitle;
  final bool showBack;
  final List<Widget>? actions;

  final Widget child;
  final Color? scaffoldBackgroundColor;
  final Widget? bottomNavigationBar;
  final bool showLoader;

  AppScaffold({
    this.appBarTitle,
    required this.child,
    this.actions,
    this.scaffoldBackgroundColor,
    this.bottomNavigationBar,
    this.showLoader = true,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarTitle != null
          ? appBarWidget(
              appBarTitle.validate(),
              textColor: white,
              showBack: showBack,
              textSize: APP_BAR_TEXT_SIZE,
              elevation: 0.0,
              color: context.primaryColor,
              backWidget: BackWidget(),
              actions: actions,
            )
          : null,
      backgroundColor: scaffoldBackgroundColor,
      body: Body(child: child, showLoader: showLoader),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
