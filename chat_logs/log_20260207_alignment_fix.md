# 聊天记录 - 2026-02-07 按钮图标与文本对齐优化

## 1. 用户需求
用户反馈“提醒事项”和“午休助眠”两个按钮的文本和图标在垂直方向上没有对齐（上下不协调），要求优化以避免看起来不协调。

## 2. 问题分析
- **结构差异**：
  - 左侧“提醒事项”按钮 (`intervalCard`) 的图标是一个 `Item` (16x16)，内部包含自定义绘制的 `Rectangle`。
  - 右侧“午休助眠”按钮 (`napCard`) 的图标原本是一个直接的 `Text` 元素，虽然设置了 `height: 16`，但其内部的字体渲染基线和垂直对齐方式可能与左侧的 `Item` 容器不一致，导致视觉重心的偏差。
- **对齐原理**：
  - 两个按钮都使用 `Column` 布局，且 `anchors.centerIn: parent`。
  - 要保证内容严格对齐，必须确保 `Column` 内的第一个元素（图标）具有完全相同的尺寸和布局行为。

## 3. 解决方案
- **统一容器**：将“午休助眠”按钮的月亮图标 (`Text`) 也包裹在一个 `Item` (16x16) 容器中。
- **布局一致性**：
  - 两个按钮的图标容器高度均为 16px。
  - 两个按钮的 `Column` 间距均为 `spacing: 2`。
  - 两个按钮的文本字体大小均为 `pixelSize: 10`。
- **代码实现**：
  - 在 `napCard` 中引入 `Item` 包装层，将 `Text` 居中放置 (`anchors.centerIn: parent`)。
  - 这样，两个按钮的 `Column` 结构完全镜像，数学上保证了垂直方向的绝对对齐。

## 4. 修改文件
### `assets/qml/Main.qml`
- **定位**：`napCard` -> `Column` -> Icon 部分。
- **修改内容**：
  ```qml
  // 统一图标容器，确保与左侧日历图标严格对齐
  Item {
      width: 16
      height: 16
      anchors.horizontalCenter: parent.horizontalCenter
      
      Text {
          text: "☾"
          // ... 样式属性 ...
          anchors.centerIn: parent
          verticalAlignment: Text.AlignVCenter
          horizontalAlignment: Text.AlignHCenter
      }
  }
  ```

## 5. 验证
- **结构验证**：左右两个 `Column` 的第一个子元素现在都是 16x16 的 `Item`，第二个子元素都是文本。
- **视觉验证**：由于容器高度一致且都居中对齐，文本起始位置（Y轴）将严格一致。图标中心点也将严格处于同一水平线上。

## 6. 时间记录
- **开始时间**: 2026-02-07 10:58:00 (预估)
- **结束时间**: 2026-02-07 11:00:00
- **总耗时**: 2 分钟
