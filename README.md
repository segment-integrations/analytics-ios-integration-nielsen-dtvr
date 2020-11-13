# Segment Nielsen DTVR Integration

## Installation

The Nielsen App SDK as of version 6.0.0.0 is compatible with iOS 8.0 and above.

The Segment-Nielsen DTVR SDK is available on [CocoaPods](http://cocoapods.org). Add the following line to your Podfile:

```ruby
pod "Segment-Nielsen-DTVR", :git => 'https://github.com/segment-integrations/analytics-ios-integration-nielsen-dtvr.git', :tag => '1.4.0'
```

The integration relies on the Nielsen App SDK framework, which can either be installed via CocoaPods or by manually adding the framework.
You will need to have a Nielsen representative before getting started.

## Xcode 12

The Nielsen Cocoapod (8.0.0.0) specifies iOS 8.0 as its minimum target.  This has the negative effect of generating ones Cocoapod workspace with invalid values.  To fix this, the following script can be added to the end of the `Podfile`:

```
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end
  end
end
```

This will remove the deployment target settings and fall back to what has been specified within the Xcode Project itself.

It should also be noted that the Nielsen Cocoapod does not include an `arm64` slice.  It may be necessary for  `EXCLUDED_ARCHS[sdk=iphonesimulator*]` to be set to exclude `arm64` in your project.

### CocoaPods

When using the Nielsen SDK version 6.2.0.0 and above, Nielsen recommends installation via CocoaPods, and Apple recommends using the dynamic framework.

Requirements for CocoaPods:
Dynamic Framework - version 1.6.1 or higher
Static Framework - version 1.4.0 or higher

1. Set repository credentials
The first step is to add the credentials received from Nielsen into your .netrc file. Navigate to your home folder and create a file called .netrc
```
cd ~/
vi .netrc
```

Add the credentials in the following format:
```
machine raw.githubusercontent.com
login <Nielsen App SDK client>
password <Auth token>
```

You will need to fill out a license agreement form and have the contact information for your Nielsen representative in order to obtain the credentials [here](https://engineeringportal.nielsen.com/docs/Special:Downloads)

2. Add the source to your Podfile:
Dynamic Framework - `source 'https://github.com/NielsenDigitalSDK/nielsenappsdk-ios-specs-dynamic.git'`
Note - you will also need to include `use_frameworks!`

Static Framework - `source 'https://github.com/NielsenDigitalSDK/nielsenappsdk-ios-specs.git'`

3. Add the pod to your Podfile:

`pod NielsenAppSDK`

There are several other pods available, and can be found in the [Nielsen Digital Measurement iOS Artifactory Guide](https://engineeringportal.nielsen.com/docs/Digital_Measurement_iOS_Artifactory_Guide)

4. Install pods

`pod install`

The full instructions from Nielsen can be found [here](https://engineeringportal.nielsen.com/docs/Digital_Measurement_iOS_Artifactory_Guide)

### Manual

Navigate to the [Nielsen Downloads](https://engineeringportal.nielsen.com/docs/Special:Downloads) page to download the iOS SDK.
You will need to fill out a license agreement form and have the contact information for your Nielsen representative ready.

Once extracted, add the static NielsenAppApi.framework to the project and ensure it's in the `Frameworks` folder, and that it is linked.

Nielsen also requires the following frameworks, which must be included into Link Binary with Libraries (within app target’s Build Phases) - NOTE - if using the dynamic framework, these will dynamically be linked and there is no need to manually link these.
  - AdSupport.framework
  - SystemConfiguration.framework
  - CoreLocation.framework (Not applicable for International (Germany))
  - libsqlite3

## Usage

Register the factory with the Segment SDK in the `application:didFinishLaunchingWithOptions` method of your `AppDelegate`:

`#import <Segment-Nielsen-DTVR/SEGNielsenDTVRIntegrationFactory.h>`

```
NSString *const SEGMENT_WRITE_KEY = @" ... ";
SEGAnalyticsConfiguration *config = [SEGAnalyticsConfiguration configurationWithWriteKey:SEGMENT_WRITE_KEY];

[config use:[SEGNielsenDTVRIntegrationFactory instance]];

[SEGAnalytics setupWithConfiguration:config];
```

## Sample

See the example application under `Example/` for a demonstration of integration with the Nielsen App SDK and Segment-Nielsen DTVR Integration with a sample custom video player.

## License

Segment-Nielsen DTVR is available under the MIT license. See the LICENSE file for more info.
