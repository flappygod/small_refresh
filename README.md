<p>import 'package:small_refresh/small_refresh.dart';</p>

<p></p>

<p>
#Create A Controller at first<br />
final SmallRefreshController _refreshController = SmallRefreshController();</p>

<p>int _dataCount = 0;<br />
List dataList = List.from({&quot;1&quot;, &quot;2&quot;, &quot;3&quot;, &quot;4&quot;, &quot;5&quot;, &quot;6&quot;, &quot;7&quot;, &quot;8&quot;, &quot;9&quot;, &quot;10&quot;});</p>

<p>
#build your refresh view<br />
Widget _buildRefresh() {<br />
 return SmallRefresh(<br />
 topPadding: 0,<br />
 bottomPadding: 0,<br />
 firstRefresh: true,<br />
 controller: _refreshController,<br />
 header: DefaultSmallRefreshHeader(<br />
 controller: _refreshController,<br />
 ),<br />
 footer: DefaultSmallRefreshFooter(<br />
 controller: _refreshController,<br />
 ),<br />
 slivers: _buildSliver(),<br />
 onRefresh: () async {<br />
 await Future.delayed(const Duration(milliseconds: 2000));<br />
 dataList.clear();<br />
 _dataCount = 0;<br />
 for (int s = 0; s < 10; s++) {<br />
 _dataCount++;<br />
 dataList.add(_dataCount.toString());<br />
 }<br />
 },<br />
 onLoad: () async {<br />
 await Future.delayed(const Duration(milliseconds: 2000));<br />
 if (dataList.length < 30) {<br />
 for (int s = 0; s < 10; s++) {<br />
 _dataCount++;<br />
 dataList.add(_dataCount.toString());<br />
 }<br />
 setState(() {});<br />
 } else {<br />
 _refreshController.footerEnd();<br />
 setState(() {});<br />
 }<br />
 },<br />
 );<br />
}</p>

<p>#You can customize your header or footer by StatefulWidget's State extends SmallRefreshHeaderState/SmallRefreshFooterState </p>

<p>#or just extends SmallRefreshHeaderWidget/SmallRefreshFooterWidget with listeners in State</p>