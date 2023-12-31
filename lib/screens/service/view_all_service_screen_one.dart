import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/screens/dashboard/component/sub_category_component.dart';
import 'package:booking_system_flutter/screens/service/view_all_service_screen_two.dart';
import 'package:booking_system_flutter/store/filter_store.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../component/cached_image_widget.dart';
import '../../component/empty_error_state_widget.dart';
import '../../main.dart';
import '../../model/category_model.dart';
import '../../model/service_data_model.dart';
import '../../network/rest_apis.dart';
import '../../utils/common.dart';
import '../../utils/constant.dart';
import '../../utils/images.dart';
import '../filter/filter_screen.dart';
import 'component/service_component.dart';

class ViewAllServiceScreenOne extends StatefulWidget {
  final int? categoryId;
  final String? categoryName;
  final String isFeatured;
  final bool isFromProvider;
  final bool isFromCategory;
  final bool isFromSearch;
  final int? providerId;

  ViewAllServiceScreenOne({
    this.categoryId,
    this.categoryName = '',
    this.isFeatured = '',
    this.isFromProvider = true,
    this.isFromCategory = false,
    this.isFromSearch = false,
    this.providerId,
    Key? key,
  }) : super(key: key);

  @override
  State<ViewAllServiceScreenOne> createState() =>
      _ViewAllServiceScreenOneState();
}

class _ViewAllServiceScreenOneState extends State<ViewAllServiceScreenOne> {
  Future<List<CategoryData>>? futureCategory;
  List<CategoryData> homeInteriorList = [
    CategoryData(
        id: 9, name: "HVAC System", categoryImage: "assets/images/havc.png"),
    CategoryData(
        id: 10, name: "Plumbing", categoryImage: "assets/images/plumbing.png"),
    CategoryData(
        id: 11,
        name: "Elecritical",
        categoryImage: "assets/images/electric.png"),
    CategoryData(
        id: 14, name: "Drywall", categoryImage: "assets/services/drywall.png"),
    CategoryData(
        id: 15, name: "Paint", categoryImage: "assets/services/paint.png"),
    CategoryData(
        id: 16,
        name: "Trim Carpentry",
        categoryImage: "assets/services/trim-carpenter.png"),
    CategoryData(
        id: 17, name: "Flooring", categoryImage: "assets/services/flooring.png"),
    CategoryData(
        id: 18,
        name: "Countertops",
        categoryImage: "assets/services/countertop.png"),
    CategoryData(
        id: 19, name: "Glass", categoryImage: "assets/services/glass.png"),
    CategoryData(
        id: 20,
        name: "Windows/Doors",
        categoryImage: "assets/services/door.png"),
  ];
  List<CategoryData> homeExteriorList = [
    CategoryData(id: 12, name: "Yard", categoryImage: "assets/images/yard.jpg"),
    CategoryData(id: 13, name: "Pool", categoryImage: "assets/images/pool.png"),
  ];
  String globalTextField = '';

  Future<List<ServiceData>>? futureService;

  List<ServiceData> filteredServiceList = [];

  FocusNode myFocusNode = FocusNode();
  TextEditingController searchCont = TextEditingController();

  int? subCategory;

  int page = 1;
  bool isLastPage = false;

  @override
  void initState() {
    super.initState();
    init();
    filterStore = FilterStore();
  }

  void init() async {
    // fetchAllServiceData();

    // if (widget.categoryId != null) {
    //   fetchCategoryList();
    // }
    filterServices("");
  }

  void filterServices(String searchText) {
    if (searchText.isEmpty) {
      globalTextField = '';
      filteredServiceList = []; // Show all data
    } else {
      filteredServiceList =
          globalServiceResponse!.serviceList!.where((service) {
        // Check if the service name contains the search text (case-insensitive).
        return service.name!.toLowerCase().contains(searchText.toLowerCase());
      }).toList();
    }
  }

  void fetchCategoryList() async {
    futureCategory = getSubCategoryListAPI(catId: widget.categoryId!);
  }

  void fetchAllServiceData() async {
    futureService = searchServiceAPI(
      page: page,
      list: globalServiceResponse!.serviceList!,
      categoryId: widget.categoryId != null
          ? widget.categoryId.validate().toString()
          : filterStore.categoryId.join(','),
      subCategory: subCategory != null ? subCategory.validate().toString() : '',
      providerId: widget.providerId != null
          ? widget.providerId.toString()
          : filterStore.providerId.join(","),
      isPriceMin: filterStore.isPriceMin,
      isPriceMax: filterStore.isPriceMax,
      search: searchCont.text,
      latitude: filterStore.latitude,
      longitude: filterStore.longitude,
      lastPageCallBack: (p0) {
        isLastPage = p0;
      },
      isFeatured: widget.isFeatured,
    );
  }

  String get setSearchString {
    if (!widget.categoryName.isEmptyOrNull) {
      return widget.categoryName!;
    } else if (widget.isFeatured == "1") {
      return language.lblFeatured;
    } else {
      return language.allServices;
    }
  }

  Widget gridSubCategoryWidget() {
    return GridView.builder(
      shrinkWrap: true,
      itemCount: widget.categoryName == "Home Interior"
          ? homeInteriorList.length
          : widget.categoryName == "Home Exterior"
              ? homeExteriorList.length
              : [].length, // list.validate().length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
      ),
      itemBuilder: (context, index) {
        CategoryData data = widget.categoryName == "Home Interior"
            ? homeInteriorList[index]
            : widget.categoryName == "Home Exterior"
                ? homeExteriorList[index]
                : homeExteriorList[index];
        return SubCategoryComponentTwo(
          categoryImage: data.categoryImage.toString(),
          categoryName: data.name.toString(),
          crossAxisCount: 3,
          onTap: () {
            ViewAllServiceScreenTwo(
              categoryId: data.id.validate(),
              categoryName: data.name,
              isFromCategory: true,
            ).launch(context);
          },
        );
      },
    );
  }

  // Widget subCategoryWidget() {
  // return SnapHelperWidget<List<CategoryData>>(
  //   future: futureCategory,
  //   initialData: cachedSubcategoryList
  //       .firstWhere((element) => element?.$1 == widget.categoryId.validate(),
  //           orElse: () => null)
  //       ?.$2,
  //   loadingWidget: Offstage(),
  //   onSuccess: (list) {
  //     if (list.length == 1) return Offstage();

  // return Column(
  //   crossAxisAlignment: CrossAxisAlignment.start,
  //   mainAxisSize: MainAxisSize.min,
  //   children: [
  //     16.height,
  //     Text(language.lblSubcategories,
  //             style: boldTextStyle(size: LABEL_TEXT_SIZE))
  //         .paddingLeft(16),
  //     HorizontalList(
  //       itemCount: categoryList.length, // list.validate().length,
  //       padding: EdgeInsets.only(left: 16, right: 16),
  //       runSpacing: 8,
  //       spacing: 12,
  //       itemBuilder: (_, index) {
  //         CategoryData data = categoryList[index];

  //         return Observer(
  //           builder: (_) {
  //             bool isSelected = filterStore.selectedSubCategoryId == index;

  //             return GestureDetector(
  //               onTap: () {
  //                 filterStore.setSelectedSubCategory(catId: index);

  //                 subCategory = data.id;
  //                 page = 1;

  //                 appStore.setLoading(true);
  //                 fetchAllServiceData();

  //                 setState(() {});
  //               },
  //               child: SizedBox(
  //                 width: context.width() / 4 - 20,
  //                 child: Stack(
  //                   clipBehavior: Clip.none,
  //                   children: [
  //                     Column(
  //                       children: [
  //                         16.height,
  //                         if (index == 0)
  //                           Container(
  //                             height: CATEGORY_ICON_SIZE,
  //                             width: CATEGORY_ICON_SIZE,
  //                             decoration: BoxDecoration(
  //                                 color: context.cardColor,
  //                                 shape: BoxShape.circle,
  //                                 border: Border.all(color: grey)),
  //                             alignment: Alignment.center,
  //                             child: Text(data.name.validate(),
  //                                 style: boldTextStyle(size: 12)),
  //                           ),
  //                         if (index != 0)
  //                           data.categoryImage.validate().endsWith('.svg')
  //                               ? Container(
  //                                   width: CATEGORY_ICON_SIZE,
  //                                   height: CATEGORY_ICON_SIZE,
  //                                   padding: EdgeInsets.all(8),
  //                                   decoration: BoxDecoration(
  //                                       color: context.cardColor,
  //                                       shape: BoxShape.circle),
  //                                   child: SvgPicture.network(
  //                                     data.categoryImage.validate(),
  //                                     height: CATEGORY_ICON_SIZE,
  //                                     width: CATEGORY_ICON_SIZE,
  //                                     color: appStore.isDarkMode
  //                                         ? Colors.white
  //                                         : data.color
  //                                             .validate(value: '000')
  //                                             .toColor(),
  //                                     placeholderBuilder: (context) =>
  //                                         PlaceHolderWidget(
  //                                             height: CATEGORY_ICON_SIZE,
  //                                             width: CATEGORY_ICON_SIZE,
  //                                             color: transparentColor),
  //                                   ),
  //                                 )
  //                               : Container(
  //                                   padding: EdgeInsets.all(12),
  //                                   decoration: BoxDecoration(
  //                                       color: context.cardColor,
  //                                       shape: BoxShape.circle),
  //                                   child: CachedImageWidget(
  //                                     url: data.categoryImage.validate(),
  //                                     fit: BoxFit.fitWidth,
  //                                     width: SUBCATEGORY_ICON_SIZE,
  //                                     height: SUBCATEGORY_ICON_SIZE,
  //                                     circle: true,
  //                                   ),
  //                                 ),
  //                         4.height,
  //                         if (index == 0)
  //                           Text(language.lblViewAll,
  //                               style: boldTextStyle(size: 12),
  //                               textAlign: TextAlign.center,
  //                               maxLines: 1),
  //                         if (index != 0)
  //                           Marquee(
  //                               child: Text('${data.name.validate()}',
  //                                   style: boldTextStyle(size: 12),
  //                                   textAlign: TextAlign.center,
  //                                   maxLines: 1)),
  //                       ],
  //                     ),
  //                     Positioned(
  //                       top: 14,
  //                       right: 0,
  //                       child: Container(
  //                         padding: EdgeInsets.all(2),
  //                         decoration: boxDecorationDefault(
  //                             color: context.primaryColor),
  //                         child:
  //                             Icon(Icons.done, size: 16, color: Colors.white),
  //                       ).visible(isSelected),
  //                     )
  //                   ],
  //                 ),
  //               ),
  //             );
  //           },
  //         );
  //       },
  //     ),
  //     16.height,
  //   ],
  // );
  //   },
  // );
  // }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    filterStore.clearFilters();
    myFocusNode.dispose();
    filterStore.setSelectedSubCategory(catId: 0);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: setSearchString,
      child: SizedBox(
        height: context.height(),
        width: context.width(),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  AppTextField(
                    textFieldType: TextFieldType.OTHER,
                    focus: myFocusNode,
                    controller: searchCont,
                    suffix: CloseButton(
                      onPressed: () {
                        page = 1;
                        searchCont.clear();
                        filterStore.setSearch('');

                        // appStore.setLoading(true);
                        // fetchAllServiceData();
                        filterServices("");
                        setState(() {});
                      },
                    ).visible(searchCont.text.isNotEmpty),
                    onFieldSubmitted: (s) {
                      page = 1;

                      filterStore.setSearch(s);
                      // appStore.setLoading(true);

                      // fetchAllServiceData();
                      globalTextField = s;
                      filterServices(s);
                      setState(() {});
                    },
                    decoration: inputDecoration(context).copyWith(
                      hintText: "${language.lblSearchFor} $setSearchString",
                      prefixIcon: ic_search.iconImage(size: 10).paddingAll(14),
                      hintStyle: secondaryTextStyle(size: 15),
                    ),
                  ).expand(),
                  16.width,
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration:
                        boxDecorationDefault(color: context.primaryColor),
                    child: CachedImageWidget(
                      url: ic_filter,
                      height: 26,
                      width: 26,
                      color: Colors.white,
                    ),
                  ).onTap(() {
                    hideKeyboard(context);

                    FilterScreen(
                            isFromProvider: widget.isFromProvider,
                            isFromCategory: widget.isFromCategory)
                        .launch(context)
                        .then((value) {
                      if (value != null) {
                        // page = 1;
                        // appStore.setLoading(true);

                        // fetchAllServiceData();
                        setState(() {});
                      }
                    });
                  }, borderRadius: radius())
                ],
              ),
            ),
            AnimatedScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              onSwipeRefresh: () {
                page = 1;

                // appStore.setLoading(true);
                // fetchAllServiceData();
                setState(() {});

                return Future.value(false);
              },
              onNextPage: () {
                if (!isLastPage) {
                  page++;

                  // appStore.setLoading(true);
                  // fetchAllServiceData();
                  // setState(() {});
                }
              },
              children: [
                // if (widget.categoryId != null) subCategoryWidget(),
                if (!widget.isFromSearch)
                  filteredServiceList.length == 0
                      ? gridSubCategoryWidget()
                      : Container(),
                16.height,
                // SnapHelperWidget(
                //   future: futureService,
                //   loadingWidget: LoaderWidget(),
                //   errorBuilder: (p0) {
                //     return NoDataWidget(
                //       title: p0,
                //       retryText: language.reload,
                //       imageWidget: ErrorStateWidget(),
                //       onRetry: () {
                //         page = 1;
                //         appStore.setLoading(true);

                //         fetchAllServiceData();
                //         setState(() {});
                //       },
                //     );
                //   },
                // onSuccess: (data) {
                //   return

                if (globalTextField != '' && filteredServiceList.isEmpty)
                  NoDataWidget(
                    title: language.lblNoServicesFound,
                    subTitle: (searchCont.text.isNotEmpty ||
                            filterStore.providerId.isNotEmpty ||
                            filterStore.categoryId.isNotEmpty)
                        ? language.noDataFoundInFilter
                        : null,
                    imageWidget: EmptyStateWidget(),
                  ),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text(language.service,
                    //         style: boldTextStyle(size: LABEL_TEXT_SIZE))
                    //     .paddingSymmetric(horizontal: 16),
                    AnimatedListView(
                      itemCount: filteredServiceList.length,
                      listAnimationType: ListAnimationType.FadeIn,
                      fadeInConfiguration:
                          FadeInConfiguration(duration: 2.seconds),
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      // emptyWidget: NoDataWidget(
                      //   title: language.lblNoServicesFound,
                      //   subTitle: (searchCont.text.isNotEmpty ||
                      //           filterStore.providerId.isNotEmpty ||
                      //           filterStore.categoryId.isNotEmpty)
                      //       ? language.noDataFoundInFilter
                      //       : null,
                      //   imageWidget: EmptyStateWidget(),
                      // ),
                      itemBuilder: (_, index) {
                        return ServiceComponent(
                                serviceData: filteredServiceList[index])
                            .paddingAll(8);
                        return Container();
                      },
                    ).paddingAll(8),
                  ],
                )
                // ;
                // },
                // ),
              ],
            ).expand(),
          ],
        ),
      ),
    );
  }
}
