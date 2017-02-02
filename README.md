# MetalScope

Metal-backed 360-degree media view for iOS.

## Features

|                          | Features
|--------------------------|---------
| :metal:                  | Built on top of SceneKit + Metal
| :eyes:                   | Distorted stereo view for Cardboard
| :globe_with_meridians:   | Support mono/stereo equirectangular images/videos
| :arrow_forward:          | Direct access to AVPlayer for 360 video control
| :point_up_2:             | Smooth touch rotation and re-centering
| :sunrise_over_mountains: | Custom SCNScene presentation
| :bird:                   | Written in Swift 3

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
