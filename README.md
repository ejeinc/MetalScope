# MetalScope

Metal-backed 360° panorama view for iOS.

|                          | Features
|--------------------------|---------
| :metal:                  | Built on top of SceneKit + Metal
| :eyes:                   | Distorted stereo view for Cardboard
| :globe_with_meridians:   | Support mono/stereo equirectangular images/videos
| :arrow_forward:          | Direct access to AVPlayer for 360 video control
| :point_up_2:             | Smooth touch rotation and re-centering
| :sunrise_over_mountains: | Custom SCNScene presentation
| :bird:                   | Written in Swift 3

## Usage

### PanoramaView

Use `PanoramaView` to display an equirectangular image or video.

```swift
import MetalScope
import Metal

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

`PanoramaView` rotates the point of view by device motions and user's pan gesture. To reset rotation, just call `resetCenter()`

```swift
let panoramaView: PanoramaView = ...

// double tap to re-center the scene
let recognizer = UITapGestureRecognizer(
  target: panoramaView,
  action: #selector(PanoramaView.resetCenter))
recognizer.numberOfTapsRequired = 2

panoramaView.addGestureRecognizer(recognizer)

// if you want to disable pan gesture:
panoramaView.panGestureRecognizer.isEnabled = false
```

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
  viewerModel: .cardboardJun2014)

present(stereoViewController, animated: true, completion: nil)
```

![Preview of StereoViewController](https://raw.githubusercontent.com/ejeinc/MetalScope/master/Resources/stereo-preview.jpg)

Check example apps for more samples.

## Requirements

- Xcode 8.2+
- iOS 9.0+
- Swift 3.0+
- Metal (Apple A7+)

## Installation

### Carthage

To integrate `MetalScope` into your Xcode project using [Carthage](https://github.com/Carthage/Carthage), specify it in your `Cartfile`:

```ogdl
github "ejeinc/MetalScope" "master"
```

### Manually

You can also manually install the framework by dragging and dropping the `MetalScope.xcodeproj` into your project or workspace.

## License

MetalScope is released under the MIT license. See LICENSE for details.
