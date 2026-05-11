# ImpactAlert LiDAR Project

ImpactAlert 是一个基于 iOS LiDAR 与 ARKit scene depth 的行人携带式碰撞预警研究原型。应用运行在支持 LiDAR 的 iPhone 或 iPad 上，通过连续深度帧估计物体是否正在靠近使用者，并在速度与碰撞时间阈值满足危险条件时播放警报音。

这个仓库包含两部分内容：

- `BaseLidar`：ImpactAlert 的 iOS LiDAR 原型应用。
- Python 实验脚本：用于论文实验数据的阈值分析、报警计数与混淆矩阵计算。

## 相关论文

本项目对应论文：

**ImpactAlert: Pedestrian-Carried Vehicle Collision Alert System**  
作者：Raghav Rawat, Caspar Lant, Haowen Yuan, Dennis Shasha  
期刊：*Electronics* 2025, 14(15), 3133  
DOI：[10.3390/electronics14153133](https://doi.org/10.3390/electronics14153133)  
论文页面：<https://www.mdpi.com/2079-9292/14/15/3133>

论文介绍了一个由行人携带的碰撞预警系统 ImpactAlert，主要面向视障行人，以及其他需要感知来自视野外车辆、行人或移动物体风险的使用者。系统利用商用手机上的 LiDAR 深度传感能力，跨多个深度帧估计潜在威胁物体的接近速度与 time to impact，并在达到用户设定的危险阈值时通过声音、手机反馈或智能手杖震动等方式提醒行人。

论文还报告了在美国、印度和中国不同城市与半城市环境中的实验，覆盖从拥挤街区到相对低密度道路的场景，并用 false positive、false negative、precision、recall、F1-score 等指标评估系统效果。论文中的核心设计思想是：只关注中央视野区域内、距离较近且在相邻采样帧之间发生显著深度变化的像素，从而估计是否存在正在接近使用者的威胁。

## 仓库结构

```text
Impact-Alert-Lidar/
├── .gitignore
├── README.md
├── BaseLidar.xcodeproj/
├── BaseLidar/
├── BaseLidarTests/
├── BaseLidarUITests/
├── impact.py
└── Confusion Matrix.py
```

## 根目录文件

- `.gitignore`  
  Git 忽略规则文件。它排除了 macOS、Xcode、Swift、Python 和常见编辑器产生的本地文件，例如 `.DS_Store`、`xcuserdata`、`.xcuserstate`、`DerivedData`、`.xcresult`、Python 缓存、虚拟环境、`.idea/` 和 `.vscode/`。这样可以避免个人工作区状态、构建产物和 IDE 配置污染 GitHub 仓库。

- `README.md`  
  当前项目说明文档，解释项目背景、论文信息、目录结构、每个文件和文件夹的作用，以及如何运行 iOS 应用和实验脚本。

- `impact.py`  
  Python 3 实验分析脚本。它从仓库根目录下的 `impactexper.csv` 读取实验结果，并在多个 speed threshold 和 time-to-impact threshold 组合下统计报警次数、true positive、false positive、false negative、true negative、accuracy、precision、recall 和 F1-score。当前仓库没有包含 `impactexper.csv`，所以运行此脚本前需要先把对应 CSV 放到根目录。

- `Confusion Matrix.py`  
  Python 3 实验分析脚本，文件名中包含空格，运行时需要加引号。这个脚本内置了一份 LaTeX 表格形式的实验数据，解析后计算整体混淆矩阵、accuracy、precision、recall/sensitivity、specificity、样本总数、预测危险数量、真实危险数量，并按 `Walking`、`Car`、`Bus`、`Scooter` 等类别输出分组混淆矩阵。它不依赖外部 CSV 文件。

## `BaseLidar.xcodeproj/`

这是 Xcode 工程目录，用于构建和运行 iOS 应用。

- `BaseLidar.xcodeproj/project.pbxproj`  
  Xcode 工程主配置文件。它定义了 `BaseLidar` 应用 target、`BaseLidarTests` 单元测试 target、`BaseLidarUITests` UI 测试 target、构建配置、bundle identifier、iOS deployment target、资源文件、asset catalog、ARKit framework 链接、相机权限说明，以及 `alert.mp3` 的资源打包关系。

- `BaseLidar.xcodeproj/project.xcworkspace/contents.xcworkspacedata`  
  Xcode workspace 描述文件，用于告诉 Xcode 如何打开该 project workspace。

- `BaseLidar.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist`  
  Xcode 共享 workspace 检查配置。它属于轻量级共享工程元数据，可以保留在版本控制中。

仓库会忽略以下 Xcode 生成内容：`xcuserdata/`、`.xcuserstate`、`WorkspaceSettings.xcsettings`、`DerivedData/` 和 `.xcresult`。这些文件通常只反映某台机器、某个开发者或某次构建的状态，不适合提交到 GitHub。

## `BaseLidar/`

这是 iOS 应用源代码与资源目录。

- `BaseLidar/BaseLidarApp.swift`  
  SwiftUI 应用入口。`@main` 标记的 `BaseLidarApp` 创建主窗口，并加载 `ContentView`。

- `BaseLidar/ContentView.swift`  
  SwiftUI 根视图。它使用 `ZStack` 放置 `ARViewControllerRepresentable`，并让 AR 控制器铺满屏幕。

- `BaseLidar/ARViewControllerRepresentable.swift`  
  SwiftUI 与 UIKit 的桥接层。它实现 `UIViewControllerRepresentable`，负责在 SwiftUI 生命周期中创建并持有 `ARViewController`。因为 ARKit 深度处理逻辑写在 UIKit controller 中，这个桥接文件让 SwiftUI app 可以复用 UIKit/ARKit 实现。

- `BaseLidar/ARViewController.swift`  
  项目的核心文件，包含 ImpactAlert 原型的 UI、ARKit session、LiDAR 深度图处理和报警逻辑。它的主要职责包括：
  - 创建 `ARSCNView` 并设置 `ARSessionDelegate`；
  - 检查设备是否支持 `ARWorldTrackingConfiguration.FrameSemantics.sceneDepth`，也就是是否支持 LiDAR scene depth；
  - 通过 Start/Stop 按钮启动或暂停 AR session；
  - 每 10 个 AR frame 读取一次 `frame.sceneDepth.depthMap`；
  - 从深度图中选取中央区域：横向 `width / 12` 到 `11 * width / 12`，纵向 `height / 3` 到 `2 * height / 3`；
  - 对中央区域深度值排序并取中位数，优先关注较近像素；
  - 将当前深度帧与历史深度帧比较，只统计深度变化绝对值大于 `0.2 m` 的像素；
  - 计算平均深度变化、估计接近速度、估计 time to impact；
  - 当 `timeToImpact < ttiThreshold` 且 `speed < speedThreshold` 时播放警报音；
  - 提供 speed threshold 与 time-to-impact threshold 两个滑块；
  - 在界面底部显示实验用途免责声明。

- `BaseLidar/alert.mp3`  
  报警音频文件。当检测到潜在碰撞威胁时，`ARViewController` 通过 `AVAudioPlayer` 播放它。

- `BaseLidar/Assets.xcassets/`  
  Xcode asset catalog，用于管理应用图标、Accent Color 和其他资源。

- `BaseLidar/Assets.xcassets/Contents.json`  
  asset catalog 根元数据文件。

- `BaseLidar/Assets.xcassets/AccentColor.colorset/Contents.json`  
  Accent Color 资源配置。当前是 Xcode 默认结构。

- `BaseLidar/Assets.xcassets/AppIcon.appiconset/Contents.json`  
  App Icon 资源配置。当前定义了 iOS app icon 的 catalog 位置；正式发布前需要确认图标图片资源是否完整。

- `BaseLidar/Preview Content/Preview Assets.xcassets/Contents.json`  
  SwiftUI preview 使用的默认资源目录元数据，只影响 Xcode 本地预览。

## `BaseLidarTests/`

Xcode 生成的单元测试 target 目录。

- `BaseLidarTests/BaseLidarTests.swift`  
  默认 XCTest 模板文件，包含 `setUpWithError`、`tearDownWithError`、示例功能测试和示例性能测试。当前还没有实际业务断言，后续可以把深度处理算法拆成可测试函数后在这里补充单元测试。

## `BaseLidarUITests/`

Xcode 生成的 UI 测试 target 目录。

- `BaseLidarUITests/BaseLidarUITests.swift`  
  默认 UI 测试模板。它启动应用，并保留了 launch performance 测试结构。

- `BaseLidarUITests/BaseLidarUITestsLaunchTests.swift`  
  默认启动测试。它启动应用并保存 launch screen 截图附件，可用于后续扩展基础 UI 回归测试。

## 应用工作原理

ImpactAlert 在当前实现中把负速度视为物体正在靠近手机。应用持续保存深度帧数据，并在每次处理新深度帧时执行以下步骤：

1. 读取 ARKit scene depth map。
2. 选取画面中央区域，减少边缘无关物体的影响。
3. 对中央区域深度值排序并取中位数。
4. 只关注比中位数更近、且相邻采样之间深度变化超过 `0.2 m` 的像素。
5. 计算这些像素的平均深度变化与平均距离。
6. 用约 `0.5 s` 的采样间隔估计速度。
7. 若速度为负，计算 `timeToImpact = threatDistance / abs(speed)`；若速度非负，则视为没有接近风险。
8. 若速度和 time to impact 同时越过用户设定阈值，则播放报警音。

默认参数：

- speed threshold：`-2.2 m/s`
- time-to-impact threshold：`3 s`
- 像素深度变化阈值：`0.2 m`
- 深度处理频率：每 10 个 AR frame 处理一次
- 估算处理间隔：`10 / 20 = 0.5 s`

报警条件：

```text
timeToImpact < ttiThreshold
speed < speedThreshold
```

由于靠近运动使用负速度表示，speed threshold 越接近 `0`，系统越敏感；speed threshold 越负，报警越严格。

## 环境要求

### iOS 应用

- macOS
- Xcode
- 支持 LiDAR 和 ARKit scene depth 的实体 iPhone 或 iPad
- 项目当前 deployment target 为 iOS `17.4`
- 运行时需要授予相机权限

该应用不能依赖 iOS Simulator 完整测试，因为模拟器不提供真实 LiDAR scene depth 数据。

### Python 实验脚本

- Python 3
- 当前脚本只使用 Python 标准库，不需要额外安装第三方包

## 如何运行 iOS 应用

1. 用 Xcode 打开 `BaseLidar.xcodeproj`。
2. 选择 `BaseLidar` scheme。
3. 连接并选择支持 LiDAR 的实体 iPhone 或 iPad。
4. 如果 Xcode 提示签名问题，配置 development team 或修改 bundle identifier。
5. Build and Run 到设备。
6. 首次运行时授予相机权限。
7. 点击 `Start LiDAR` 开始处理深度数据。
8. 根据需要调整 speed threshold 和 time-to-impact threshold。
9. 当检测到满足阈值条件的接近物体时，应用会播放 `alert.mp3`。
10. 点击 `Stop LiDAR` 暂停 AR session。

## 如何运行实验脚本

### 运行内置表格版本

```bash
python3 "Confusion Matrix.py"
```

这个脚本的数据已经写在文件内部，不需要额外 CSV。

### 运行 CSV 版本

先将 `impactexper.csv` 放在仓库根目录，然后运行：

```bash
python3 impact.py
```

`impact.py` 当前按列索引读取数据：

- 第 `2` 列：speed，浮点数；
- 第 `3` 列：time to impact，浮点数；
- 第 `4` 列：collision danger，值为 `Yes` 或 `No`。

脚本会跳过第一行 header。

## 安全声明

ImpactAlert 当前是研究原型，不是经过认证的安全设备。它可能产生误报，也可能漏报。使用者不应把它作为唯一的避障或防碰撞手段，仍然需要保持正常环境感知，并遵循常规出行安全措施。

## 开发与维护建议

- 不要提交 Xcode 个人状态文件，例如 `xcuserdata/`、`.xcuserstate` 和本机 workspace settings。
- 不要提交 `.idea/`、`.vscode/` 等编辑器或 IDE 的个人配置。
- 不要提交 `DerivedData/`、`.xcresult`、`build/`、Python cache、虚拟环境等生成文件。
- 如果后续补充实验 CSV 或视频数据，应先确认数据是否适合公开发布；大型数据建议使用 release asset、数据仓库或单独的数据发布流程。
- 如果要提升可测试性，可以把 `ARViewController.swift` 中的深度处理逻辑抽成纯 Swift 算法模块，再在 `BaseLidarTests` 中添加单元测试。

## 引用

如果本仓库对你的研究或开发有帮助，请引用：

```bibtex
@article{rawat2025impactalert,
  title = {ImpactAlert: Pedestrian-Carried Vehicle Collision Alert System},
  author = {Rawat, Raghav and Lant, Caspar and Yuan, Haowen and Shasha, Dennis},
  journal = {Electronics},
  volume = {14},
  number = {15},
  pages = {3133},
  year = {2025},
  doi = {10.3390/electronics14153133}
}
```
