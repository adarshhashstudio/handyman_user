import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/category_model.dart';
import 'package:booking_system_flutter/model/dashboard_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/dashboard/component/category_component.dart';
import 'package:booking_system_flutter/screens/dashboard/component/featured_service_list_component.dart';
import 'package:booking_system_flutter/screens/dashboard/component/service_list_component.dart';
import 'package:booking_system_flutter/screens/dashboard/component/slider_and_location_component.dart';
import 'package:booking_system_flutter/screens/dashboard/shimmer/dashboard_shimmer.dart';
import 'package:booking_system_flutter/screens/notification/notification_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../component/empty_error_state_widget.dart';
import '../../../component/loader_widget.dart';
import '../component/booking_confirmed_component.dart';
import '../component/new_job_request_component.dart';

class DashboardFragment extends StatefulWidget {
  @override
  _DashboardFragmentState createState() => _DashboardFragmentState();
}

class _DashboardFragmentState extends State<DashboardFragment> {
  Future<DashboardResponse>? future;

  @override
  void initState() {
    super.initState();
    init();

    setStatusBarColor(primaryColor, delayInMilliSeconds: 800);

    LiveStream().on(LIVESTREAM_UPDATE_DASHBOARD, (p0) {
      init();
      setState(() {});
    });
  }

  void init() async {
    future = userDashboard(
        isCurrentLocation: appStore.isCurrentLocation,
        lat: getDoubleAsync(LATITUDE),
        long: getDoubleAsync(LONGITUDE));
    globalServiceResponse = await getAllServices();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    super.dispose();
    LiveStream().dispose(LIVESTREAM_UPDATE_DASHBOARD);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        // appBar: appBarWidget('K&C Services',
        //     textColor: white,
        //     showBack: false,
        //     titleWidget: Row(
        //       children: [
        //         SvgPicture.asset(
        //           "assets/icons/KandC-logo-dark.svg",
        //           width: 50,
        //         ),
        //         13.width,
        //         Text(
        //           'K&C Services',
        //           style: primaryTextStyle(
        //               size: 20, weight: FontWeight.bold, color: white),
        //         )
        //       ],
        //     ),
        //     textSize: APP_BAR_TEXT_SIZE,
        //     elevation: 3.0,
        //     color: context.primaryColor,
        //     actions: [
        //       if (appStore.isLoggedIn)
        //         Container(
        //           margin: EdgeInsets.only(right: 16),
        //           decoration: boxDecorationDefault(
        //               color: context.cardColor, shape: BoxShape.circle),
        //           height: 36,
        //           padding: EdgeInsets.all(8),
        //           width: 36,
        //           child: Stack(
        //             clipBehavior: Clip.none,
        //             children: [
        //               ic_notification
        //                   .iconImage(size: 24, color: primaryColor)
        //                   .center(),
        //               Observer(builder: (context) {
        //                 return Positioned(
        //                   top: -20,
        //                   right: -10,
        //                   child: appStore.unreadCount.validate() > 0
        //                       ? Container(
        //                           padding: EdgeInsets.all(4),
        //                           child: FittedBox(
        //                             child: Text(appStore.unreadCount.toString(),
        //                                 style: primaryTextStyle(
        //                                     size: 12, color: Colors.white)),
        //                           ),
        //                           decoration: boxDecorationDefault(
        //                               color: Colors.red, shape: BoxShape.circle),
        //                         )
        //                       : Offstage(),
        //                 );
        //               })
        //             ],
        //           ),
        //         ).onTap(() {
        //           NotificationScreen().launch(context);
        //         })
        //     ]),
        body: Stack(
          children: [
            SnapHelperWidget<DashboardResponse>(
              initialData: cachedDashboardResponse,
              future: future,
              errorBuilder: (error) {
                return NoDataWidget(
                  title: error,
                  imageWidget: ErrorStateWidget(),
                  retryText: language.reload,
                  onRetry: () {
                    appStore.setLoading(true);
                    init();

                    setState(() {});
                  },
                );
              },
              loadingWidget: DashboardShimmer(),
              onSuccess: (snap) {
                return AnimatedScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  listAnimationType: ListAnimationType.FadeIn,
                  fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                  onSwipeRefresh: () async {
                    appStore.setLoading(true);

                    init();
                    setState(() {});

                    return await 2.seconds.delay;
                  },
                  children: [
                    SliderLocationComponent(
                      sliderList: snap.slider.validate(),
                      callback: () async {
                        appStore.setLoading(true);

                        init();
                        setState(() {});
                      },
                    ),

                    // CategoryComponent(categoryList: snap.category.validate()),
                    // 16.height,
                    // FeaturedServiceListComponent(serviceList: snap.featuredServices.validate()),
                    // ServiceListComponent(serviceList: snap.service.validate()),

                    CategoryComponent(categoryList: [
                      CategoryData(
                          id: 1,
                          description: "Home Repair",
                          name: "Home Repair",
                          categoryImage: "assets/images/home-repair.png"),
                      CategoryData(
                          id: 2,
                          description: "Concierge Services",
                          name: "Concierge Services",
                          categoryImage: "assets/images/concierge-services.png")
                    ]),
                    if (snap.upcomingData != null &&
                        snap.upcomingData!.isNotEmpty)
                      30.height,
                    PendingBookingComponent(upcomingData: snap.upcomingData),
                    if (snap.upcomingData == null || snap.upcomingData!.isEmpty)
                      12.height,
                    // 12.height,
                    // NewJobRequestComponent(),
                  ],
                );
              },
            ),
            Observer(
                builder: (context) =>
                    LoaderWidget().visible(appStore.isLoading)),
          ],
        ),
      ),
    );
  }
}
