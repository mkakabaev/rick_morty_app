import 'package:flutter/material.dart';

class LoadingPlate extends StatelessWidget {
  final bool adjustForAppBar;

  const LoadingPlate({super.key, this.adjustForAppBar = true});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(bottom: adjustForAppBar ? kToolbarHeight : 0),
        child: const CircularProgressIndicator(),
      ),
    );
  }
}
