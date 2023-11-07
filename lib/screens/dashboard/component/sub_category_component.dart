import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class SubCategoryComponentTwo extends StatelessWidget {
  final String categoryImage;
  final String categoryName;
  final void Function()? onTap;
  SubCategoryComponentTwo(
      {super.key,
      required this.categoryImage,
      required this.categoryName,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 5,
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 50,
                width: 50,
                child: Image.asset(
                  '$categoryImage',
                  fit: BoxFit.fitWidth,
                ),
              ),
              16.height,
              Center(
                child: Text(
                  '$categoryName',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ).paddingOnly(left: 8, right: 8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
