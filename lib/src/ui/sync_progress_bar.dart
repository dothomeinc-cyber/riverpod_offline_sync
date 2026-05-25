import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/sync_providers.dart';
import 'auth_theme.dart';

class SyncProgressBar extends ConsumerWidget {
  final bool showDetails;

  const SyncProgressBar({
    super.key,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(syncProgressProvider);
    final isSyncing = ref.watch(isSyncingProvider);

    if (!isSyncing) return const SizedBox.shrink();

    return progressAsync.when(
      data: (progress) {
        if (progress == null) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AuthColors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: AuthColors.black.withAlpha(26),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Syncing...',
                    style: AuthTextStyles.titleM,
                  ),
                  Text(
                    '${progress.current}/${progress.total}',
                    style: AuthTextStyles.bodyM,
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: LinearProgressIndicator(
                  value: progress.total > 0
                      ? progress.current / progress.total
                      : 0,
                  minHeight: 6.h,
                  backgroundColor: AuthColors.black15,
                  color: AuthColors.yellow,
                ),
              ),
              if (showDetails &&
                  progress.currentOperation.isNotEmpty) ...[
                SizedBox(height: 8.h),
                Text(
                  progress.currentOperation,
                  style: AuthTextStyles.caption,
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
