# SMCSense 1.0

No bells and whistles SMC Monitor.  No graphs, no history, no network, no disk, no overhead.

This FrankenProject was born out of several unrelated projects: it started by hacking
[FeedbinNotifier](https://github.com/kmikael/FeedbinNotifier.git) for its simple code
structure and interface. The sensor code was taken from [XRG](https://github.com/mikepj/XRG.git).
NSMenuItem hacking was borrowed from [textmate](https://github.com/textmate/textmate.git).
Sensor name overrides via plists were inspired by [HWSensors](https://github.com/kozlek/HWSensors.git).
Finally, some useful info can be found [here](http://www.cocoabuilder.com/archive/cocoa/190983-prevent-nsmenuitem-selection.html#191003).

## Installation

You can build SMCSense with Xcode or from command-line:

    xcodebuild clean build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

By default, SMCSense refreshes every 10 seconds, you can change this in the defaults using:

    defaults write org.dborca.SMCSense SMCSenseRefresh 5
    defaults write org.dborca.SMCSense SMCSenseShowFan false

## License

* SMC code (APSL/) is licensed under APSLv2
* textmate code (NSMenuItem Additions.h) is licensed under GPLv3
* Everything else (aka my code) is licensed under GPLv2
* Icon created by Alex Tai from Noun Project is licensed under CC
