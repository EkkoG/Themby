import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:themby/src/common/constants.dart';
import 'package:themby/src/common/widget/dynamic_height_grid_view.dart';
import 'package:themby/src/extensions/constrains.dart';
import 'package:themby/src/features/emby/data/view_repository.dart';
import 'package:themby/src/features/emby/presentation/emby_library/emby_library_query_notifier.dart';
import 'package:themby/src/features/emby/presentation/emby_library/sort_button.dart';
import 'package:themby/src/features/emby/presentation/emby_library/sort_order_button.dart';
import 'package:themby/src/features/emby/presentation/widgets/media_card_v.dart';
import 'package:themby/src/features/emby/presentation/widgets/skeleton/media_card_v_skeleton.dart';

class EmbyLibraryScreen extends ConsumerWidget {
  const EmbyLibraryScreen({super.key, required this.parentId,required this.filter, required this.title});
  final String title;
  final String parentId;
  final String filter;

  static const pageSize = 30;

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final itemQuery = ref.watch(embyLibraryQueryNotifierProvider);

    final response = ref.watch(getItemProvider(
      itemQuery: (
        page: 0,
        parentId: parentId,
        includeItemTypes: itemQuery.includeItemTypes,
        sortBy: itemQuery.sortBy,
        sortOrder: itemQuery.sortOrder,
        filters: filter,
      ),
    ));

    final totalRecordCount = response.valueOrNull?.totalRecordCount;

    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        centerTitle: true,
        title: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Container(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.symmetric(horizontal: StyleString.safeSpace),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${totalRecordCount ?? 0} 项"),
                const Row(
                  children: [
                    SortOrderButton(),
                    SortButton()
                  ],
                )
              ],
            ),
          ),
        )
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(getItemProvider);
          ref.read(getItemProvider(
            itemQuery: (
              page: 0,
              parentId: parentId,
              includeItemTypes: itemQuery.includeItemTypes,
              sortBy: itemQuery.sortBy,
              sortOrder: itemQuery.sortOrder,
              filters: filter,
            )
          ).future);
        },
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(StyleString.safeSpace, 0, StyleString.safeSpace, 0),
              sliver: SliverDynamicHeightGridView(
                  crossAxisCount: mediaQuery.smAndDown ? 3 : 8,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 8,
                  builder: (BuildContext context, int index) {
                    final page = index ~/ pageSize;
                    final indexInPage = index % pageSize;
                    final responseAsync = ref.watch(
                        getItemProvider(
                            itemQuery: (
                              page: page,
                              parentId: parentId,
                              includeItemTypes: itemQuery.includeItemTypes,
                              sortBy: itemQuery.sortBy,
                              sortOrder: itemQuery.sortOrder,
                              filters: filter,
                            )
                        )
                    );
                    return responseAsync.when(
                      data: (response) {
                        if (response.items.length <= indexInPage) {
                          return const SizedBox();
                        }
                        return LayoutBuilder(builder: (context, boxConstraints){
                          return MediaCardV(
                            item: response.items[indexInPage],
                            width: boxConstraints.maxWidth,
                            height: boxConstraints.maxWidth / 0.68,
                          );
                        });

                      },
                      loading: () => LayoutBuilder(builder: (context, boxConstraints){
                          return MediaCardVSkeleton(
                            width: boxConstraints.maxWidth,
                            height: boxConstraints.maxWidth / 0.68,
                          );
                      }),
                      error: (error, stack) => Center(child: Text('Error: $error')),
                    );
                  },
                  itemCount: totalRecordCount ?? 8,
                ),
              ),
            // SliverGrid.builder(gridDelegate: gridDelegate, itemBuilder: itemBuilder)
          ],
        ),
      ),
    );
  }
}

// gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
// maxCrossAxisExtent: mediaQuery.smAndDown ? 172 : 258,
// mainAxisSpacing: 12,
// crossAxisSpacing: 12,
// childAspectRatio: mediaQuery.smAndDown ? 13 / 25 : 13 / 24,
// ),