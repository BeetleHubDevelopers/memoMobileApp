import UIKit
import Flutter
import awesome_notifications
import local_auth

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    AwesomeNotifications().initialize(
      'resource://drawable/res_app_icon',
      [
        NotificationChannel(
          channelKey: 'kdsg_channel',
          channelName: 'Kdsg notifications',
          channelDescription: 'Kdsg notifications',
          defaultColor: Color(0xFF9D50DD),
          ledColor: Colors.white,
        )
      ],
    )
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
