# small_refresh

基于 `CustomScrollView` 的下拉刷新与上拉加载组件，动画较顺滑，并支持自定义头部、底部视图。

[![Pub Version](https://img.shields.io/pub/v/small_refresh.svg)](https://pub.dev/packages/small_refresh)
[![License](https://img.shields.io/badge/license-BSD%203--Clause-blue.svg)](LICENSE)

## 功能概览

- 下拉刷新、上拉加载，与 `Sliver` 列表组合使用
- 默认提供 `DefaultSmallRefreshHeader` / `DefaultSmallRefreshFooter`（依赖 `flutter_spinkit`）
- 可继承 `SmallRefreshHeaderState` / `SmallRefreshFooterState`，或 `SmallRefreshHeaderWidget` / `SmallRefreshFooterWidget` 自行实现 UI
- 提供粘性头部场景：`SmallStickRefreshView`（外层 `RefreshIndicator`）与 `SmallStickPageView`（外层普通滚动），分别对应 `SmallStickRefreshViewController` / `SmallStickPageViewController`

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

### 粘性布局：`SmallStickRefreshView` 与 `SmallStickPageView`

两者都是「顶部区域 + 中间吸顶区域 + 下方内容区」三段布局，由各自的 `ScrollController` 测量 `headView` / `stickView` 高度，并与内层列表联动。区别如下：

| 组件 | 外层滚动 | 外层下拉刷新 | 控制器 |
|------|----------|--------------|--------|
| `SmallStickRefreshView` | `CustomScrollView`（包在 `RefreshIndicator` 里） | 有，使用 `onRefresh` | `SmallStickRefreshViewController` |
| `SmallStickPageView` | `SingleChildScrollView` + `Column` | 无 | `SmallStickPageViewController` |

内层列表通常使用 **`SmallRefresh`**，并把 **`SmallRefreshController` 的 `stickController`** 设为外层的 stick 控制器，这样父子滚动会协同（例如吸顶后再滚内容）。

#### 与内层 `SmallRefresh` 的约定（重要）

`SmallStickRefreshViewController.isStickRefresh == true` 时，下拉由外层 `RefreshIndicator` 完成，内层 **`SmallRefresh` 不要再设置 `header` 和 `onRefresh`**（否则断言失败）。 Footer、`onLoad` 等仍可照常使用。

`SmallStickPageViewController.isStickRefresh == false` 时，内层 **`SmallRefresh` 可以照常使用 `header`、`onRefresh`**。

#### `SmallStickRefreshView` 示例

```dart
final SmallStickRefreshViewController _stickController =
    SmallStickRefreshViewController();

/// 内层列表用的控制器：把 stick 父级传进去
late final SmallRefreshController _innerRefreshController =
    SmallRefreshController(stickController: _stickController);

@override
Widget build(BuildContext context) {
  return SmallStickRefreshView(
    controller: _stickController,
    headView: const YourHeadBanner(),
    stickView: const YourStickyTabBar(),
    triggerMode: RefreshIndicatorTriggerMode.anywhere,
    refreshColor: Theme.of(context).colorScheme.primary,
    onRefresh: () async {
      await yourRefreshLogic();
    },
    body: SmallRefresh(
      controller: _innerRefreshController,
      // 外层已负责下拉刷新，这里必须为 null
      header: null,
      onRefresh: null,
      footer: DefaultSmallRefreshFooter(controller: _innerRefreshController),
      slivers: yourSlivers(),
      onLoad: yourOnLoad,
    ),
  );
}
```

#### `SmallStickPageView` 示例

结构与上面类似，但**没有**外层 `onRefresh`；若需要下拉刷新，放在内层 `SmallRefresh` 即可。

```dart
final SmallStickPageViewController _stickController =
    SmallStickPageViewController();

late final SmallRefreshController _innerRefreshController =
    SmallRefreshController(stickController: _stickController);

@override
Widget build(BuildContext context) {
  return SmallStickPageView(
    controller: _stickController,
    headView: const YourHeadBanner(),
    stickView: const YourStickyTabBar(),
    body: SmallRefresh(
      controller: _innerRefreshController,
      header: DefaultSmallRefreshHeader(controller: _innerRefreshController),
      footer: DefaultSmallRefreshFooter(controller: _innerRefreshController),
      slivers: yourSlivers(),
      onRefresh: () async {
        await yourRefreshLogic();
      },
      onLoad: yourOnLoad,
    ),
  );
}
```

`crossAxisAlignment`、`clipBehavior` 等参数在两处 widget 上含义一致，可按布局需要调整。

更多用法可参考仓库内 `example/` 示例工程。

## 主要导出

包入口 `small_refresh.dart` 导出包括但不限于：

| 类型 | 说明 |
|------|------|
| `SmallRefresh` | 主刷新容器，接收 `slivers`、`onRefresh`、`onLoad` 等 |
| `SmallRefreshController` | 控制刷新/加载状态、与默认头尾联动 |
| `DefaultSmallRefreshHeader` / `DefaultSmallRefreshFooter` | 默认头、尾 |
| `SmallStickRefreshView` / `SmallStickRefreshViewController` | 粘性三段布局 + 外层 `RefreshIndicator` |
| `SmallStickPageView` / `SmallStickPageViewController` | 粘性三段布局 + 外层 `SingleChildScrollView`（无内置下拉） |
| `SmallStickController` | 抽象类型，上述两个 Controller 均实现，用于传给 `SmallRefreshController(stickController: …)` |

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
