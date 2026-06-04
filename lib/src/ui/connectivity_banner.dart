import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/connectivity_providers.dart';
import '../providers/sync_providers.dart';
import 'auth_theme.dart';

// Remove any export statements from this file
// This file should ONLY contain the widget definition

class ConnectivityBanner extends ConsumerWidget {
  final Widget child;
  final bool showRetryButton;
  final VoidCallback? onManualRetry;

  const ConnectivityBanner({
    super.key,
    required this.child,
    this.showRetryButton = true,
    this.onManualRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(isConnectedProvider);

    return Column(
      children: [
        if (!isConnected)
          Container(
            width: double.infinity,
            color: AuthColors.error,
            padding: EdgeInsets.symmetric(
                horizontal: 16.w, vertical: 12.h),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      color: AuthColors.white,
                      size: 20.sp,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'No Internet Connection',
                      style: TextStyle(
                        color: AuthColors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (showRetryButton)
                  TextButton(
                    onPressed: () {
                      ref
                          .read(offlineSyncLayerProvider)
                          .sync();
                      onManualRetry?.call();
                    },
                    child: Text(
                      'Retry',
                      style: TextStyle(
                        color: AuthColors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Expanded(child: child),
      ],
    );
  }
}
