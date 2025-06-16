import Cocoa
import FlutterMacOS

public class InternetSpeedMeterPlugin: NSObject, FlutterPlugin {
  var lastRxBytes: UInt64 = 0
  var lastTxBytes: UInt64 = 0
  var lastUpdateTime: TimeInterval = Date().timeIntervalSince1970

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "internet_speed_meter", binaryMessenger: registrar.messenger)
    let instance = InternetSpeedMeterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "getPlatformVersion" {
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
    } else if call.method == "getSpeed" {
      let speed = getNetworkSpeed()
      result(speed)
    } else {
      result(FlutterMethodNotImplemented)
    }
  }

  private func getNetworkSpeed() -> Double {
    // 获取所有网络接口流量
    var ifaddrPtr: UnsafeMutablePointer<ifaddrs>? = nil
    var rxBytes: UInt64 = 0
    var txBytes: UInt64 = 0

    if getifaddrs(&ifaddrPtr) == 0 {
      var ptr = ifaddrPtr
      while ptr != nil {
        if let addr = ptr?.pointee {
          if addr.ifa_addr.pointee.sa_family == UInt8(AF_LINK) {
            let data = unsafeBitCast(addr.ifa_data, to: UnsafeMutablePointer<if_data>.self)
            rxBytes += UInt64(data.pointee.ifi_ibytes)
            txBytes += UInt64(data.pointee.ifi_obytes)
          }
        }
        ptr = ptr?.pointee.ifa_next
      }
      freeifaddrs(ifaddrPtr)
    }

    let currentTime = Date().timeIntervalSince1970
    let elapsedTime = currentTime - lastUpdateTime
    let rxSpeed = elapsedTime > 0 ? Double(rxBytes - lastRxBytes) / elapsedTime : 0
    let txSpeed = elapsedTime > 0 ? Double(txBytes - lastTxBytes) / elapsedTime : 0

    lastRxBytes = rxBytes
    lastTxBytes = txBytes
    lastUpdateTime = currentTime

    return rxSpeed + txSpeed // 单位：字节/秒
  }
}