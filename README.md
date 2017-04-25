# MetalScope

![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat) ![CocoaPods compatible](https://img.shields.io/cocoapods/v/MetalScope.svg) ![Swift 3.0.x](https://img.shields.io/badge/Swift-3.1.x-orange.svg)

Metal-backed 360° panorama view for iOS.

|                          | Features
|--------------------------|---------
| :metal:                  | Built on top of SceneKit + Metal
| :eyes:                   | Distorted stereo view for Cardboard
| :globe_with_meridians:   | Support mono/stereo equirectangular images/videos
| :arrow_forward:          | Direct access to AVPlayer for video control
| :point_up_2:             | Smooth touch rotation and re-centering
| :sunrise_over_mountains: | Custom SCNScene presentation
| :bird:                   | Written in Swift 3

## Usage

### PanoramaView

Use `PanoramaView` to display an equirectangular image or video.

```swift
import MetalScope
import Metal
import AVFoundation

guard let device = MTLCreateSystemDefaultDevice() else {
    fatalError("MetalScope requires Metal 🤘")
}

let panoramaView = PanoramaView(frame: ..., device: device)

// load monoscopic panorama image
let panoramaImage = UIImage(...)
panoramaView.load(panoramaImage, format: .mono)

// load stereoscopic panorama video
let videoURL = URL(...)
let player = AVPlayer(url: videoURL)
panoramaView.load(player, format: .stereoOverUnder)
player.play()

// load any SCNScene
panoramaView.scene = ...
```

`PanoramaView` rotates the point of view by device motions and user's pan gesture. To reset rotation, just call `setNeedsResetRotation()`

```swift
let panoramaView: PanoramaView = ...

// double tap to re-center the scene
let recognizer = UITapGestureRecognizer(
  target: panoramaView,
  action: #selector(PanoramaView.setNeedsResetRotation(_:)))
recognizer.numberOfTapsRequired = 2

panoramaView.addGestureRecognizer(recognizer)

// if you want to disable pan gesture:
panoramaView.panGestureRecognizer.isEnabled = false
```

![PanoramaView Preview](https://raw.githubusercontent.com/ejeinc/MetalScope/master/Resources/panorama-preview.gif)

[60 FPS demo](https://youtu.be/D7wTFA5K96U) on YouTube

### StereoView

For stereo display for Google's Cardboard, use `StereoView` or `StereoViewController` instead.

```swift
let stereoViewController = StereoViewController(device: ...)

// load media
stereoViewController.load(image, format: .stereoOverUnder)

// or any SCNScene
stereoViewController.scene = panoramaView.scene

// customize stereo parameters if needed
stereoViewController.stereoParameters = StereoParameters(
  screenModel: .default,
  viewerModel: .cardboardMay2015)

present(stereoViewController, animated: true, completion: nil)
```

![Preview of StereoViewController](https://raw.githubusercontent.com/ejeinc/MetalScope/master/Resources/stereo-preview.jpg)

Check example apps for more samples.

### Simulator
`PanoramaView`, `StereoView` and `StereoViewController` can also be used on iOS simulator by using alternative initializers.

```swift
#if arch(arm) || arch(arm64)
let panoramaView = PanoramaView(frame: view.bounds, device: device)
#else
let panoramaView = PanoramaView(frame: view.bounds) // simulator
#endif
```

Please note that these classes are significantly limited in functionality on the simulator. For example, `PanoramaView` can display photos, but cannot display videos. For `StereoView` and `StereoViewController`, it is a placeholder and nothing is displayed.

## Requirements

- Xcode 8.2+
- iOS 9.0+
- Swift 3.0+
- Metal (Apple A7+)

NOTE: Metal is not supported in the iOS Simulator 😢

## Installation

### Carthage

If you use [Carthage](https://github.com/Carthage/Carthage) to manage your dependencies, add MetalScope to your `Cartfile`:

```
github "ejeinc/MetalScope"
```

### CocoaPods

If you use [CocoaPods](https://github.com/CocoaPods/CocoaPods) to manage your dependencies, add MetalScope to your `Podfile`:

```
pod 'MetalScope'
```

### Manually

You can also manually install the framework by dragging and dropping the `MetalScope.xcodeproj` into your project or workspace.

## License

MetalScope is released under the MIT license. See LICENSE for details.
