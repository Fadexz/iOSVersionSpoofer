# iOSVersionSpoofer
 Automatically spoofs your iOS version to recent versions based on the date automatically. It can also spoof app versions.

 - It is made in a way to spoof as many method/function call return values as possible, in short this means that more of the ways the version can be checked are spoofed (forged). This includes many methods from UIDevice, NSURLSession, and your User Agent.
 - It may not cover every single method call but the majority are spoofed.
 - App Version is spoofed in NSBundle and User Agent (if it exists and is not a custom key name)
 - Other methods are also spoofed to be more generic such as your device's hostname is "iphone.local" and not your custom device name and more.
 - This tweak does not spoof your device type or screen size or anything else similar as that wasn't within the scope of this tweak.
 - This tweak is mostly useful for bypassing iOS and app version requirements so you can continue to operate them easily on your older device.

 Note: The compiled deb 1.0.0 release spoofs app version to "11.79.1", you will need to compile it for yourself for the updated code which sets this hardcoded version number higher to be more versatile.
