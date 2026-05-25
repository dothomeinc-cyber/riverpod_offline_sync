import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riverpod_offline_sync/riverpod_offline_sync.dart';
import '../providers/sync_providers.dart';
import '../providers/queue_providers.dart';
import 'auth_theme.dart';

class OfflineToast extends ConsumerStatefulWidget {
  final Widget child;

  const OfflineToast({super.key, required this.child});

  @override
  ConsumerState<OfflineToast> createState() =>
      _OfflineToastState();
}

class _OfflineToastState
    extends ConsumerState<OfflineToast> {
  OverlayEntry? _toastEntry;
  bool _listenersSetup = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_listenersSetup && mounted) {
        _setupListeners();
        _listenersSetup = true;
      }
    });
  }

  void _setupListeners() {
    ref.listen(syncStateProvider, (previous, next) {
      if (!mounted) return;
      next.whenData((state) {
        if (state == SyncStateType.completed) {
          _showToast('Sync completed!', AuthColors.success);
        } else if (state == SyncStateType.failed) {
          _showToast('Sync failed', AuthColors.error);
        }
      });
    });

    ref.listen(pendingItemsCountProvider, (previous, next) {
      if (!mounted) return;
      if (next == 1 &&
          (previous == null || previous == 0)) {
        _showToast('Saved offline', AuthColors.yellow);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  void _showToast(String message, Color color) {
    _toastEntry?.remove();

    _toastEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 50.h,
        left: 16.w,
        right: 16.w,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: AuthColors.black.withAlpha(26),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  color == AuthColors.success
                      ? Icons.check_circle
                      : color == AuthColors.yellow
                          ? Icons.save
                          : Icons.error,
                  color: AuthColors.white,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                        color: AuthColors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_toastEntry!);
    Future.delayed(const Duration(seconds: 2),
        () => _toastEntry?.remove());
  }

  @override
  void dispose() {
    _toastEntry?.remove();
    super.dispose();
  }
}
