import 'dart:io';

import 'package:booking_system_flutter/app_theme.dart';
import 'package:booking_system_flutter/component/app_common_dialog.dart';
import 'package:booking_system_flutter/component/custom_image_picker.dart';
import 'package:booking_system_flutter/component/custom_stepper.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/booking_amount_model.dart';
import 'package:booking_system_flutter/model/package_data_model.dart';
import 'package:booking_system_flutter/model/service_detail_response.dart';
import 'package:booking_system_flutter/screens/booking/component/confirm_booking_dialog.dart';
import 'package:booking_system_flutter/screens/booking/component/coupon_widget.dart';
import 'package:booking_system_flutter/screens/map/map_screen.dart';
import 'package:booking_system_flutter/services/location_service.dart';
import 'package:booking_system_flutter/utils/booking_calculations_logic.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/model_keys.dart';
import 'package:booking_system_flutter/utils/permissions.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';

class BookingServiceStep2 extends StatefulWidget {
  final ServiceDetailResponse data;
  final bool? isSlotAvailable;
  final BookingPackage? selectedPackage;

  BookingServiceStep2(
      {required this.data,
      this.isSlotAvailable,
      required this.selectedPackage});

  @override
  _BookingServiceStep2State createState() => _BookingServiceStep2State();
}

class _BookingServiceStep2State extends State<BookingServiceStep2> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController dateTimeCont = TextEditingController();
  TextEditingController addressCont = TextEditingController();
  TextEditingController descriptionCont = TextEditingController();

  DateTime currentDateTime = DateTime.now();
  DateTime? selectedDate;
  DateTime? finalDate;
  TimeOfDay? pickedTime;
  bool isButtonClicked = false;
  bool isNowButtonClicked = true;

  BookingAmountModel bookingAmountModel = BookingAmountModel();
  num advancePaymentAmount = 0;
  CouponData? appliedCouponData;
  int itemCount = 1;

  UniqueKey uniqueKey = UniqueKey();

  List<File> imageFiles = [];
  List<Attachments> tempAttachments = [];

  bool isUpdate = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    if (widget.data.serviceDetail!.dateTimeVal != null) {
      if (widget.isSlotAvailable.validate()) {
        dateTimeCont.text = formatDate(
            widget.data.serviceDetail!.dateTimeVal.validate(),
            format: DATE_FORMAT_1);
        selectedDate =
            DateTime.parse(widget.data.serviceDetail!.dateTimeVal.validate());
        pickedTime = TimeOfDay.fromDateTime(selectedDate!);
      }
      addressCont.text = widget.data.serviceDetail!.address.validate();
    }
    setCurrentDateWithAdditional2Hours();

    setPrice();
  }

  void selectDateAndTime(BuildContext context) async {
    await showDatePicker(
      context: context,
      initialDate: selectedDate ?? currentDateTime,
      firstDate: currentDateTime,
      lastDate: currentDateTime.add(30.days),
      locale: Locale(appStore.selectedLanguageCode),
      cancelText: language.lblCancel,
      confirmText: language.lblOk,
      helpText: language.lblSelectDate,
      builder: (_, child) {
        return Theme(
          data: appStore.isDarkMode ? ThemeData.dark() : AppTheme.lightTheme(),
          child: child!,
        );
      },
    ).then((date) async {
      if (date != null) {
        await showTimePicker(
          context: context,
          initialTime: pickedTime ?? TimeOfDay.now(),
          cancelText: language.lblCancel,
          confirmText: language.lblOk,
          builder: (_, child) {
            return Theme(
              data: appStore.isDarkMode
                  ? ThemeData.dark()
                  : AppTheme.lightTheme(),
              child: child!,
            );
          },
        ).then((time) {
          if (time != null) {
            finalDate = DateTime(
                date.year, date.month, date.day, time.hour, time.minute);

            DateTime now = DateTime.now().subtract(1.minutes);
            if (date.isToday &&
                finalDate!.millisecondsSinceEpoch <
                    now.millisecondsSinceEpoch) {
              return toast(language.selectedOtherBookingTime);
            }

            selectedDate = date;
            pickedTime = time;
            widget.data.serviceDetail!.dateTimeVal = finalDate.toString();
            dateTimeCont.text =
                "${formatDate(selectedDate.toString(), format: DATE_FORMAT_3)} ${pickedTime!.format(context).toString()}";

            setState(() {
              isNowButtonClicked = false;
              isButtonClicked = true;
            });
          }
        }).catchError((e) {
          toast(e.toString());
        });
      }
    });
  }

  void setCurrentDateWithAdditional2Hours() {
    final DateTime newDateTime = currentDateTime.add(Duration(hours: 2));

    selectedDate = newDateTime;
    pickedTime = TimeOfDay.fromDateTime(newDateTime);
    finalDate = newDateTime;
    widget.data.serviceDetail!.dateTimeVal = finalDate.toString();

    dateTimeCont.text =
        "${formatDate(selectedDate.toString(), format: DATE_FORMAT_3)} ${pickedTime!.format(context).toString()}";
    setState(() {});
  }

  void _handleSetLocationClick() {
    Permissions.cameraFilesAndLocationPermissionsGranted().then((value) async {
      await setValue(PERMISSION_STATUS, value);

      if (value) {
        String? res = await MapScreen(
                latitude: getDoubleAsync(LATITUDE),
                latLong: getDoubleAsync(LONGITUDE))
            .launch(context);

        if (res != null) {
          addressCont.text = res;
          setState(() {});
        }
      }
    });
  }

  void _handleCurrentLocationClick() {
    Permissions.cameraFilesAndLocationPermissionsGranted().then((value) async {
      await setValue(PERMISSION_STATUS, value);

      if (value) {
        appStore.setLoading(true);

        await getUserLocation().then((value) {
          addressCont.text = value;
          widget.data.serviceDetail!.address = value.toString();
          setState(() {});
        }).catchError((e) {
          log(e);
          toast(e.toString());
        });

        appStore.setLoading(false);
      }
    }).catchError((e) {
      //
    });
  }

  void setPrice() {
    bookingAmountModel = finalCalculations(
      servicePrice: widget.data.serviceDetail!.price.validate(),
      appliedCouponData: appliedCouponData,
      discount: widget.data.serviceDetail!.discount.validate(),
      taxes: widget.data.taxes,
      quantity: itemCount,
      selectedPackage: widget.selectedPackage,
    );

    if (bookingAmountModel.finalGrandTotalAmount.isNegative) {
      appliedCouponData = null;
      setPrice();

      toast("This coupon can't be applied");

      ///TODO String translation
    } else {
      advancePaymentAmount = (bookingAmountModel.finalGrandTotalAmount *
          (widget.data.serviceDetail!.advancePaymentPercentage.validate() / 100)
              .toStringAsFixed(DECIMAL_POINT)
              .toDouble());
    }
    setState(() {});
  }

  void applyCoupon() async {
    var value = await showInDialog(
      context,
      backgroundColor: context.cardColor,
      contentPadding: EdgeInsets.zero,
      builder: (p0) {
        return AppCommonDialog(
          title: language.lblAvailableCoupons,
          child: CouponWidget(
            couponData: widget.data.couponData.validate(),
            appliedCouponData: appliedCouponData ?? null,
          ),
        );
      },
    );

    if (value != null) {
      if (value is bool && !value) {
        appliedCouponData = null;
      } else if (value is CouponData) {
        appliedCouponData = value;
      } else {
        appliedCouponData = null;
      }
      setPrice();
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 24, right: 16, left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                8.height,
                Text(language.lblStepper1Title,
                    style: boldTextStyle(size: LABEL_TEXT_SIZE)),
                20.height,
                Form(
                  key: formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Container(
                    decoration: boxDecorationDefault(color: context.cardColor),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.isSlotAvailable.validate(value: true))
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(language.lblDateAndTime,
                                  style: boldTextStyle(size: LABEL_TEXT_SIZE)),
                              8.height,
                              Container(
                                width: context.width() * 0.89,
                                height: context.height() * 0.05,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          setCurrentDateWithAdditional2Hours();
                                          setState(() {
                                            isNowButtonClicked = true;
                                            isButtonClicked = false;
                                          });
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                              color: isNowButtonClicked
                                                  ? primaryColor
                                                  : null,
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(12)),
                                              boxShadow: defaultBoxShadow(
                                                  blurRadius: 0,
                                                  spreadRadius: 0)),
                                          padding: EdgeInsets.all(10),
                                          child: Center(
                                              child: Text(
                                            'Now',
                                            style: TextStyle(
                                                color: isNowButtonClicked
                                                    ? white
                                                    : null),
                                          )),
                                        ),
                                      ),
                                    ),
                                    20.width,
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          selectDateAndTime(context);
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                              color: isButtonClicked
                                                  ? primaryColor
                                                  : null,
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(12)),
                                              boxShadow: defaultBoxShadow(
                                                  blurRadius: 0,
                                                  spreadRadius: 0)),
                                          padding: EdgeInsets.all(10),
                                          child: Center(
                                              child: Text(
                                            'Schedule',
                                            style: TextStyle(
                                              color: isButtonClicked
                                                  ? white
                                                  : null,
                                            ),
                                          )),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (selectedDate != null && !isNowButtonClicked)
                                8.height,
                              if (selectedDate != null && !isNowButtonClicked)
                                AppTextField(
                                  textFieldType: TextFieldType.OTHER,
                                  controller: dateTimeCont,
                                  isValidationRequired: true,
                                  validator: (value) {
                                    if (value!.isEmpty)
                                      return language.requiredText;
                                    return null;
                                  },
                                  readOnly: true,
                                  onTap: () {
                                    selectDateAndTime(context);
                                  },
                                  decoration: inputDecoration(context,
                                          prefixIcon: ic_calendar
                                              .iconImage(size: 10)
                                              .paddingAll(14))
                                      .copyWith(
                                    fillColor: context.scaffoldBackgroundColor,
                                    filled: true,
                                    hintText: language.chooseDateAndTime,
                                    hintStyle: secondaryTextStyle(),
                                  ),
                                ),
                              20.height,
                            ],
                          ),
                        Visibility(
                          visible: false,
                          child: Text(language.lblYourAddress,
                              style: boldTextStyle(size: LABEL_TEXT_SIZE)),
                        ),
                        Visibility(
                          visible: false,
                          child: AppTextField(
                            textFieldType: TextFieldType.ADDRESS,
                            // controller: addressCont,
                            maxLines: 1,
                            onFieldSubmitted: (s) {
                              // widget.data.serviceDetail!.address = s;
                            },
                            initialValue: appStore.address,
                            enabled: false,
                            decoration: inputDecoration(
                              context,
                              prefixIcon: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ic_location
                                      .iconImage(size: 22)
                                      .paddingOnly(top: 8),
                                ],
                              ),
                            ).copyWith(
                              fillColor: context.scaffoldBackgroundColor,
                              filled: true,
                              // hintText: language.lblEnterYourAddress,
                              hintStyle: secondaryTextStyle(),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: false,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                child: Text(language.lblChooseFromMap,
                                    style: boldTextStyle(
                                        color: primaryColor, size: 13)),
                                onPressed: () {
                                  _handleSetLocationClick();
                                },
                              ).flexible(),
                              TextButton(
                                onPressed: _handleCurrentLocationClick,
                                child: Text(language.lblUseCurrentLocation,
                                    style: boldTextStyle(
                                        color: primaryColor, size: 13),
                                    textAlign: TextAlign.right),
                              ).flexible(),
                            ],
                          ),
                        ),
                        Text("Comments:",
                            style: boldTextStyle(size: LABEL_TEXT_SIZE)),
                        8.height,
                        AppTextField(
                          textFieldType: TextFieldType.MULTILINE,
                          controller: descriptionCont,
                          maxLines: 10,
                          minLines: 4,
                          isValidationRequired: false,
                          onFieldSubmitted: (s) {
                            widget.data.serviceDetail!.bookingDescription = s;
                          },
                          decoration: inputDecoration(context).copyWith(
                            fillColor: context.scaffoldBackgroundColor,
                            filled: true,
                            hintText: 'Enter Comments',
                            hintStyle: secondaryTextStyle(),
                          ),
                        ),
                        16.height,
                        CustomImagePicker(
                          key: uniqueKey,
                          onRemoveClick: (value) {
                            if (tempAttachments.validate().isNotEmpty &&
                                imageFiles.isNotEmpty) {
                              showConfirmDialogCustom(
                                context,
                                dialogType: DialogType.DELETE,
                                positiveText: 'Delete',
                                negativeText: 'Cancel',
                                onAccept: (p0) {
                                  imageFiles.removeWhere(
                                      (element) => element.path == value);
                                  // removeAttachment(id: tempAttachments.validate().firstWhere((element) => element.url == value).id.validate());
                                },
                              );
                            } else {
                              showConfirmDialogCustom(
                                context,
                                dialogType: DialogType.DELETE,
                                positiveText: 'Delete',
                                negativeText: 'Cancel',
                                onAccept: (p0) {
                                  imageFiles.removeWhere(
                                      (element) => element.path == value);
                                  if (isUpdate) {
                                    uniqueKey = UniqueKey();
                                  }
                                  setState(() {});
                                },
                              );
                            }
                          },
                          selectedImages: widget.data != null
                              ? imageFiles
                                  .validate()
                                  .map((e) => e.path.validate())
                                  .toList()
                              : null,
                          onFileSelected: (List<File> files) async {
                            imageFiles = files;
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                16.height,
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // if (!widget.isSlotAvailable.validate())
                //   AppButton(
                //     shapeBorder: RoundedRectangleBorder(
                //         borderRadius: radius(),
                //         side: BorderSide(color: context.primaryColor)),
                //     onTap: () {
                //       customStepperController.previousPage(
                //           duration: 200.milliseconds, curve: Curves.easeInOut);
                //     },
                //     text: language.lblPrevious,
                //     textColor: textPrimaryColorGlobal,
                //   ).expand(),
                // if (!widget.isSlotAvailable.validate()) 16.width,
                AppButton(
                  onTap: () {
                    hideKeyboard(context);
                    // if (formKey.currentState!.validate()) {
                    //   formKey.currentState!.save();
                    //   widget.data.serviceDetail!.bookingDescription =
                    //       descriptionCont.text;
                    //   widget.data.serviceDetail!.address = addressCont.text;
                    //   customStepperController.nextPage(
                    //       duration: 200.milliseconds, curve: Curves.easeOut);
                    //
                    doIfLoggedIn(context, () {
                      showInDialog(
                        context,
                        builder: (p0) {
                          return ConfirmBookingDialog(
                            data: widget.data,
                            bookingPrice:
                                bookingAmountModel.finalGrandTotalAmount,
                            selectedPackage: widget.selectedPackage,
                            qty: itemCount,
                            couponCode: appliedCouponData?.code,
                            imagesFile: imageFiles,
                            bookingAmountModel: BookingAmountModel(
                              finalCouponDiscountAmount:
                                  bookingAmountModel.finalCouponDiscountAmount,
                              finalDiscountAmount:
                                  bookingAmountModel.finalDiscountAmount,
                              finalSubTotal: bookingAmountModel.finalSubTotal,
                              finalTotalServicePrice:
                                  bookingAmountModel.finalTotalServicePrice,
                              finalTotalTax: bookingAmountModel.finalTotalTax,
                            ),
                          );
                        },
                      );
                    });
                  },
                  text: language.btnNext,
                  textColor: Colors.white,
                  width: context.width(),
                  color: context.primaryColor,
                ).expand(),
              ],
            ),
          ),
          Observer(
              builder: (context) => LoaderWidget().visible(appStore.isLoading))
        ],
      ),
    );
  }
}
