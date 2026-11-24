import Flutter
import UIKit
import UserNotifications
import XCTest

class RunnerTests: XCTestCase {

  @MainActor
  func testAppDelegateReceivesNotificationCallbacks() {
    let appDelegate = UIApplication.shared.delegate
    XCTAssertNotNil(appDelegate)
    XCTAssertTrue(UNUserNotificationCenter.current().delegate === appDelegate)
  }

  func testExample() {
    // If you add code to the Runner application, consider adding tests here.
    // See https://developer.apple.com/documentation/xctest for more information about using XCTest.
  }

}
