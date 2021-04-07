Change Log
==========

Version 1.0.1 *(7th April, 2021)*
-------------------------------------------
* Updates `Video Playback Completed` to call `stop`.
* Maps `Video Playback Exited` to call `stop` .
* Removes `end` handler as per Nielsen's requirements to use `stop` instead.

Version 1.0.0 *(13th November, 2020)*
-------------------------------------------
* Updates Nielsen SDK to 8.x
* Fixes out-of-the-box compilation issues when used as a pod.

Version 0.0.6 *(8th October, 2020)*
-------------------------------------------
 * Update SEGAnalytics import to support new namespacing introduced in `analytics-ios` v4.x

Version 0.0.5 *(21st June, 2020)*
-------------------------------------------
* Relaxes Segment Analytics library dependency.

Version 0.0.4 *(23rd September, 2019)*
-------------------------------------------
* Fixes a syntax issue with `loadType` that may cause an Xcode build error.

Version 0.0.3 *(18th September, 2019)*
-------------------------------------------
* Maps Segment `loadType`, falling back to `load_type`, to Nielsen `adModel` field.

Version 0.0.2 *(12th July, 2019)*
-------------------------------------------
* Fix example app import paths.

Version 0.0.1 *(10th July, 2019)*
-------------------------------------------
*(Supports analytics-ios 3.6.+ and Nielsen-DTVR 6.0.0.0+)*

* Initial release.
