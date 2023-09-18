

import 'package:small_refresh/small_refresh.dart';




#Create A Controller at first
final SmallRefreshController _refreshController = SmallRefreshController();

int _dataCount = 0;
List dataList = List.from({"1", "2", "3", "4", "5", "6", "7", "8", "9", "10"});


#build your refresh view
Widget _buildRefresh() {
    return SmallRefresh(
    topPadding: 0,
    bottomPadding: 0,
    firstRefresh: true,
    controller: _refreshController,
    header: DefaultSmallRefreshHeader(
    controller: _refreshController,
    ),
    footer: DefaultSmallRefreshFooter(
       controller: _refreshController,
    ),
    slivers: _buildSliver(),
    onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 2000));
        dataList.clear();
        _dataCount = 0;
        for (int s = 0; s < 10; s++) {
        _dataCount++;
        dataList.add(_dataCount.toString());
       }
    },
    onLoad: () async {
        await Future.delayed(const Duration(milliseconds: 2000));
        if (dataList.length < 30) {
        for (int s = 0; s < 10; s++) {
        _dataCount++;
        dataList.add(_dataCount.toString());
        }
        setState(() {});
      } else {
        _refreshController.footerEnd();
        setState(() {});
      }
     },
   );
}

#You can customize your header or footer by StatefulWidget's State extends SmallRefreshHeaderState/SmallRefreshFooterState 

#or just extends SmallRefreshHeaderWidget/SmallRefreshFooterWidget with listeners in State