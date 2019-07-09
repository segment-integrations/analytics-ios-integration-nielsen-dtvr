XCPRETTY := xcpretty -c && exit ${PIPESTATUS[0]}

SDK ?= "iphonesimulator"
DESTINATION ?= "platform=iOS Simulator,name=iPhone 7"
PROJECT := Segment-Nielsen-DTVR
XC_ARGS := -scheme $(PROJECT)_Example -workspace Example/$(PROJECT).xcworkspace -sdk $(SDK) -destination $(DESTINATION) ONLY_ACTIVE_ARCH=NO

install: Example/Podfile Segment-Nielsen-DTVR.podspec
	pod repo update
	pod install --project-directory=Example

clean:
	xcodebuild $(XC_ARGS) clean | $(XCPRETTY)

build:
	xcodebuild $(XC_ARGS) | $(XCPRETTY)

test:
	xcodebuild test $(XC_ARGS) | $(XCPRETTY)

lint:
	pod lib lint --use-libraries --allow-warnings

xcbuild:
	xctool $(XC_ARGS)

xctest:
	xctool test $(XC_ARGS)

.PHONY: test build xctest xcbuild clean
.SILENT: