# ImpactAlert LiDAR Project

ImpactAlert is an iOS LiDAR research prototype for pedestrian-carried collision alerts. The app runs on a LiDAR-capable iPhone or iPad, uses ARKit scene depth to estimate whether objects are approaching the user, and plays an audible warning when the estimated speed and time-to-impact values cross the configured danger thresholds.

This repository contains two related parts:

- `BaseLidar`: the iOS LiDAR prototype application.
- Python experiment scripts: lightweight analysis tools for threshold evaluation, alert counting, and confusion-matrix reporting.

## Related Paper

This project is associated with the following paper:

**ImpactAlert: Pedestrian-Carried Vehicle Collision Alert System**  
Authors: Raghav Rawat, Caspar Lant, Haowen Yuan, and Dennis Shasha  
Journal: *Electronics* 2025, 14(15), 3133  
DOI: [10.3390/electronics14153133](https://doi.org/10.3390/electronics14153133)  
Paper page: <https://www.mdpi.com/2079-9292/14/15/3133>

The paper presents ImpactAlert as a pedestrian-carried collision warning system, with a particular focus on visually impaired pedestrians and other pedestrians who may need warnings about vehicles, people, or moving objects approaching from unseen directions. The system uses the LiDAR sensor on a commercial phone, processes depth data over multiple frames, estimates the speed and time to impact of potential threats, and alerts the pedestrian when user-configurable thresholds are crossed.

The paper also reports experiments in varied urban and semi-urban environments in the United States, India, and China. The evaluation uses false positives, false negatives, precision, recall, F1-score, and related metrics to measure the behavior of the alert algorithm. A central design idea is to focus on pixels in the middle region of the LiDAR depth map that are both close to the user and changing significantly across sampled frames.

## Repository Layout

```text
Impact-Alert-Lidar/
|-- .gitignore
|-- README.md
|-- BaseLidar.xcodeproj/
|-- BaseLidar/
|-- BaseLidarTests/
|-- BaseLidarUITests/
|-- impact.py
`-- Confusion Matrix.py
```

## Root-Level Files

- `.gitignore`  
  Defines files that should not be committed to Git. It excludes macOS metadata, Xcode user state, local build outputs, Swift and Python generated files, virtual environments, and editor-specific folders such as `.idea/` and `.vscode/`.

- `README.md`  
  The project documentation. It explains the research context, paper citation, repository structure, file responsibilities, and usage instructions.

- `impact.py`  
  A Python 3 analysis script for CSV-based experiment results. It expects an `impactexper.csv` file in the repository root. The script reads speed, time-to-impact, and ground-truth danger labels, then evaluates several speed-threshold and time-to-impact-threshold combinations. It prints alert counts, true positives, false positives, false negatives, true negatives, accuracy, precision, recall, and F1-score.

- `Confusion Matrix.py`  
  A Python 3 analysis script with an embedded LaTeX-style experiment table. It parses the embedded data, computes a global confusion matrix, prints accuracy, precision, recall/sensitivity, specificity, total sample counts, predicted danger counts, actual danger counts, and confusion matrices grouped by object type such as `Walking`, `Car`, `Bus`, and `Scooter`. Because the filename contains a space, quote it when running it from the shell.

## `BaseLidar.xcodeproj/`

This directory contains the Xcode project used to build and run the iOS app.

- `BaseLidar.xcodeproj/project.pbxproj`  
  The main Xcode project configuration file. It defines the `BaseLidar` app target, `BaseLidarTests` unit-test target, `BaseLidarUITests` UI-test target, build settings, bundle identifiers, iOS deployment target, resources, asset catalogs, ARKit framework linkage, camera permission text, and inclusion of `alert.mp3` as an app resource.

- `BaseLidar.xcodeproj/project.xcworkspace/contents.xcworkspacedata`  
  The Xcode workspace metadata file that tells Xcode how to open the project workspace.

- `BaseLidar.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist`  
  Shared Xcode workspace check metadata. This is lightweight shared project metadata and is safe to keep in version control.

The repository intentionally ignores Xcode user-specific and generated files such as `xcuserdata/`, `.xcuserstate`, `WorkspaceSettings.xcsettings`, `DerivedData/`, and `.xcresult` files. Those files represent local developer state or local build artifacts and should not be committed to GitHub.

## `BaseLidar/`

This is the main iOS app source and resource directory.

- `BaseLidar/BaseLidarApp.swift`  
  The SwiftUI application entry point. The `@main` app struct creates the main window and loads `ContentView`.

- `BaseLidar/ContentView.swift`  
  The root SwiftUI view. It embeds `ARViewControllerRepresentable` in a full-screen layout.

- `BaseLidar/ARViewControllerRepresentable.swift`  
  The SwiftUI-to-UIKit bridge. It implements `UIViewControllerRepresentable` so the UIKit-based `ARViewController` can be used inside the SwiftUI application lifecycle.

- `BaseLidar/ARViewController.swift`  
  The core ImpactAlert prototype implementation. This controller is responsible for the user interface, ARKit session, LiDAR depth processing, and alert behavior. It:
  - creates an `ARSCNView` and sets itself as the `ARSessionDelegate`;
  - checks that the device supports `ARWorldTrackingConfiguration.FrameSemantics.sceneDepth`;
  - starts or pauses the AR session through the Start/Stop button;
  - reads `frame.sceneDepth.depthMap` every 10 AR frames;
  - extracts the central region of the depth map, from `width / 12` to `11 * width / 12` and from `height / 3` to `2 * height / 3`;
  - sorts central-region depth values and uses the median depth to prioritize nearby pixels;
  - compares the current depth frame against a previous sampled frame;
  - counts only pixels whose absolute depth change is greater than `0.2 m`;
  - estimates average depth change, approaching speed, and time to impact;
  - plays the alert sound when `timeToImpact < ttiThreshold` and `speed < speedThreshold`;
  - provides sliders for speed threshold and time-to-impact threshold;
  - displays an experimental-use safety disclaimer in the interface.

- `BaseLidar/alert.mp3`  
  The audible warning played when the app detects a potential collision threat.

- `BaseLidar/Assets.xcassets/`  
  The Xcode asset catalog for app resources such as app icons and accent colors.

- `BaseLidar/Assets.xcassets/Contents.json`  
  Root metadata for the asset catalog.

- `BaseLidar/Assets.xcassets/AccentColor.colorset/Contents.json`  
  Metadata for the app accent color. It currently follows the default Xcode asset structure.

- `BaseLidar/Assets.xcassets/AppIcon.appiconset/Contents.json`  
  Metadata for the iOS app icon asset slot. Verify that production icon images are complete before distribution.

- `BaseLidar/Preview Content/Preview Assets.xcassets/Contents.json`  
  Default SwiftUI preview asset metadata. It affects local Xcode previews only.

## `BaseLidarTests/`

This directory contains the Xcode unit-test target.

- `BaseLidarTests/BaseLidarTests.swift`  
  The default XCTest template file. It currently contains setup, teardown, an example functional test, and an example performance test. Future work could move the depth-processing algorithm into testable pure Swift functions and add unit tests here.

## `BaseLidarUITests/`

This directory contains the Xcode UI-test target.

- `BaseLidarUITests/BaseLidarUITests.swift`  
  The default UI-test template. It launches the app and includes a launch-performance test structure.

- `BaseLidarUITests/BaseLidarUITestsLaunchTests.swift`  
  The default launch test. It launches the app and stores a launch-screen screenshot attachment. It can be extended into a basic UI regression test.

## How the App Works

In the current implementation, negative speed represents motion toward the phone. The app stores sampled depth frames and processes each new sampled frame as follows:

1. Read the ARKit scene depth map.
2. Select the center region of the depth map to reduce the influence of objects near the image edges.
3. Sort the center-region depth values and compute the median depth.
4. Focus on pixels that are closer than the median and whose depth changed by more than `0.2 m` between sampled frames.
5. Compute the average distance and average depth change for those relevant pixels.
6. Estimate speed using an assumed sampling interval of about `0.5 s`.
7. If speed is negative, compute `timeToImpact = threatDistance / abs(speed)`. If speed is non-negative, treat the frame as not approaching.
8. Play the alert sound when both speed and time-to-impact thresholds indicate danger.

Default parameters:

- speed threshold: `-2.2 m/s`
- time-to-impact threshold: `3 s`
- pixel depth-change threshold: `0.2 m`
- depth-processing cadence: every 10 AR frames
- assumed processing interval: `10 / 20 = 0.5 s`

Alert condition:

```text
timeToImpact < ttiThreshold
speed < speedThreshold
```

Because approaching motion is represented with negative speed, a speed threshold closer to `0` makes the system more sensitive. A more negative speed threshold makes alerts stricter.

## Requirements

### iOS App

- macOS
- Xcode
- A physical iPhone or iPad with LiDAR and ARKit scene-depth support
- iOS or iPadOS compatible with the project settings
- Camera permission granted at runtime

The current Xcode project uses iOS `17.4` as the deployment target. The app cannot be fully tested in the iOS Simulator because the simulator does not provide real LiDAR scene-depth data.

### Python Scripts

- Python 3
- No third-party Python packages are required by the current scripts

## Running the iOS App

1. Open `BaseLidar.xcodeproj` in Xcode.
2. Select the `BaseLidar` scheme.
3. Connect and select a LiDAR-capable physical iPhone or iPad.
4. Configure signing if Xcode asks for a development team or bundle identifier.
5. Build and run the app on the device.
6. Grant camera permission on first launch.
7. Tap `Start LiDAR` to begin depth processing.
8. Adjust the speed threshold and time-to-impact threshold as needed.
9. When an approaching object meets the configured thresholds, the app plays `alert.mp3`.
10. Tap `Stop LiDAR` to pause the AR session.

## Running the Analysis Scripts

### Embedded Table Version

Run:

```bash
python3 "Confusion Matrix.py"
```

This script has the experiment table embedded directly in the file and does not require an external CSV file.

### CSV Version

Place `impactexper.csv` in the repository root, then run:

```bash
python3 impact.py
```

`impact.py` currently reads data by column index:

- column `2`: speed as a floating-point number;
- column `3`: time to impact as a floating-point number;
- column `4`: collision danger label, with `Yes` or `No`.

The first row is treated as a header and skipped.

## Safety Notice

ImpactAlert is a research prototype, not a certified safety device. It may produce false positives and false negatives. Users should not rely on it as their only collision-avoidance mechanism and should continue to use normal situational awareness and established mobility practices.

## Development Notes

- Do not commit Xcode user-state files such as `xcuserdata/`, `.xcuserstate`, or local workspace settings.
- Do not commit editor-specific folders such as `.idea/` or `.vscode/`.
- Do not commit generated files such as `DerivedData/`, `.xcresult`, `build/`, Python caches, or virtual environments.
- If future experiment CSV files or video data are added, confirm that they are appropriate for public release. Large data should use a deliberate data-release process, release assets, or a separate data repository.
- For stronger test coverage, consider extracting the depth-processing logic from `ARViewController.swift` into pure Swift functions and covering those functions in `BaseLidarTests`.

## Citation

If this repository is useful in your research or development work, please cite:

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
