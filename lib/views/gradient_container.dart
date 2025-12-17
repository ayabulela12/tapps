import 'package:flutter/material.dart';
import 'package:appmaniazar/constants/brand_colors.dart';

class GradientContainer extends StatelessWidget {
  const GradientContainer({
    super.key,
    this.child,
    this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
  }) : assert(child == null || children == null, 
             'Cannot provide both a child and children');

  final Widget? child;
  final List<Widget>? children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                BrandColors.primaryBlue,
                BrandColors.secondaryBlue,
              ],
              stops: [0.0, 1.0],
            ),
          ),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: padding,
                  child: child ?? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children ?? [],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
