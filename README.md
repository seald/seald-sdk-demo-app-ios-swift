# Seald SDK demo app iOS Swift

This is a basic app, demonstrating use of the Seald SDK for iOS in Swift.

You can check the reference documentation at <https://docs.seald.io/sdk/seald-sdk-ios/>.

The main file you could be interested in reading is [`./seald-sdk-demo-app-ios-swift/ContentView.swift`](./seald-sdk-demo-app-ios-swift/ContentView.swift).

Before running the app, you have to install the Cocoapods, with the command `pod install`.

Also, it is recommended to create your own Seald team on <https://www.seald.io/create-sdk>,
and change the values of `appId`, `JWTSharedSecretId`, and `JWTSharedSecret`, that you can get on the `SDK` tab
of the Seald dashboard settings, as well as `SSKSBackendAppKey` that you can get on the `SSKS` tab,
in `./seald-sdk-demo-app-ios-swift/credentials.swift`,
so that the example runs in your own Seald team.

Finally, to run the app, open `SealdSDK demo app ios swift.xcworkspace` in XCode, then run it.
