import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/queue_providers.dart';
// Import the helper
import 'auth_theme.dart';

class SyncStatusIndicator extends ConsumerWidget {
  final bool showAsFloatingAction;
  final bool showLabel;

  const SyncStatusIndicator({
    super.key,
    this.showAsFloatingAction = false,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount =
        ref.watch(pendingItemsCountProvider);

    if (pendingCount == 0) return const SizedBox.shrink();

    final indicator = Container(
      padding: EdgeInsets.symmetric(
          horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AuthColors.yellow,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AuthColors.black.withAlpha(26),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16.w,
            height: 16.w,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: AuthColors.black,
            ),
          ),
          if (showLabel) ...[
            SizedBox(width: 8.w),
            Text(
              '$pendingCount pending',
              style: TextStyle(
                color: AuthColors.black,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );

    if (showAsFloatingAction) {
      return Positioned(
        bottom: 16.h,
        right: 16.w,
        child: indicator,
      );
    }

    return indicator;
  }
}
