# small_refresh

基于 `CustomScrollView` 的下拉刷新与上拉加载组件，动画较顺滑，并支持自定义头部、底部视图。

[![Pub Version](https://img.shields.io/pub/v/small_refresh.svg)](https://pub.dev/packages/small_refresh)
[![License](https://img.shields.io/badge/license-BSD%203--Clause-blue.svg)](LICENSE)

## 功能概览

- 下拉刷新、上拉加载，与 `Sliver` 列表组合使用
- 默认提供 `DefaultSmallRefreshHeader` / `DefaultSmallRefreshFooter`（依赖 `flutter_spinkit`）
- 可继承 `SmallRefreshHeaderState` / `SmallRefreshFooterState`，或 `SmallRefreshHeaderWidget` / `SmallRefreshFooterWidget` 自行实现 UI
- 提供粘性头部场景：`SmallStickRefreshView`、`SmallStickPageView` 等，与 `SmallStickRefreshViewController` 配合使用

## 环境要求

- Dart SDK：`>= 3.0.6`（见 `pubspec.yaml` 中 `environment`）
- Flutter 项目

## 安装

在工程根目录的 `pubspec.yaml` 中加入：

```yaml
dependencies:
  small_refresh: ^1.0.27
```

然后执行：

```bash
flutter pub get
```

## 快速开始

### 1. 导入

```dart
import 'package:small_refresh/small_refresh.dart';
```

### 2. 创建控制器

```dart
final SmallRefreshController _refreshController = SmallRefreshController();
```

### 3. 构建 `SmallRefresh`

下面示例演示：首次进入自动刷新、默认头尾、刷新与加载更多逻辑。

```dart
int _dataCount = 0;
final List<String> dataList = List<String>.from(
  <String>['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'],
);

Widget buildRefresh() {
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
    slivers: buildSlivers(),
    onRefresh: () async {
      await Future<void>.delayed(const Duration(milliseconds: 2000));
      dataList.clear();
      _dataCount = 0;
      for (int s = 0; s < 10; s++) {
        _dataCount++;
        dataList.add(_dataCount.toString());
      }
    },
    onLoad: () async {
      await Future<void>.delayed(const Duration(milliseconds: 2000));
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
```

请将 `buildSlivers()` 替换为你自己的 `List<Widget>`（例如 `SliverList`、`SliverGrid` 等）。

### 自定义 Header / Footer

- 使用 **StatefulWidget**，让 `State` 继承 `SmallRefreshHeaderState` 或 `SmallRefreshFooterState`，按需重写构建与动画逻辑。
- 或继承 **`SmallRefreshHeaderWidget` / `SmallRefreshFooterWidget`**，在 `State` 中监听控制器回调并更新 UI。

具体可参考 `lib/src/small_refresh_header.dart`、`lib/src/small_refresh_footer.dart` 中的默认实现。

### 粘性头部 + `RefreshIndicator`（`SmallStickRefreshView`）

顶部固定区域 + 中间可吸顶 + 下方可滚动内容时，可使用 `SmallStickRefreshView`，并配合 `SmallStickRefreshViewController`。支持 `RefreshIndicatorTriggerMode` 等参数（与 Material `RefreshIndicator` 行为一致）。

更多用法见仓库内 `example/` 示例工程。

## 主要导出

包入口 `small_refresh.dart` 导出包括但不限于：

| 类型 | 说明 |
|------|------|
| `SmallRefresh` | 主刷新容器，接收 `slivers`、`onRefresh`、`onLoad` 等 |
| `SmallRefreshController` | 控制刷新/加载状态、与默认头尾联动 |
| `DefaultSmallRefreshHeader` / `DefaultSmallRefreshFooter` | 默认头、尾 |
| `SmallStickRefreshView` / `SmallStickRefreshViewController` | 粘性头部场景的滚动与刷新 |
| `SmallStickPageView` | 与粘性 Tab/分页相关的页面视图 |

完整列表以 `lib/small_refresh.dart` 的 `export` 为准。

## 示例工程

```bash
cd example
flutter run
```

## 版本与变更

详见 [CHANGELOG.md](CHANGELOG.md)。

## 许可证

本项目采用 BSD 3-Clause License，见 [LICENSE](LICENSE) 文件。

## 仓库

<https://github.com/flappygod/small_refresh>
