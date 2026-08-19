import AppKit
import Foundation

func fail(_ message: String, code: Int32 = 2) -> Never {
  FileHandle.standardError.write(Data("flash-screen: \(message)\n".utf8))
  exit(code)
}

struct Configuration {
  private static let defaultDuration = 0.5
  private static let defaultFlashes = 2
  private static let defaultGap = 0.08

  let duration: TimeInterval
  let flashes: Int
  let gap: TimeInterval
  let color: NSColor

  init(environment: [String: String]) {
    duration = Self.timeInterval(
      named: "duration",
      value: environment["FLASH_SCREEN_DURATION"] ?? String(Self.defaultDuration),
      minimum: 0
    )
    flashes = Self.integer(
      named: "count",
      value: environment["FLASH_SCREEN_COUNT"] ?? String(Self.defaultFlashes),
      minimum: 1
    )
    gap = Self.timeInterval(
      named: "gap",
      value: environment["FLASH_SCREEN_GAP"] ?? String(Self.defaultGap),
      minimum: 0
    )

    let colorValue = environment["FLASH_SCREEN_COLOR"] ?? "black"
    guard let parsedColor = parseColor(colorValue) else {
      fail("invalid --color '\(colorValue)'")
    }
    color = parsedColor
  }

  private static func timeInterval(
    named name: String,
    value: String,
    minimum: TimeInterval
  ) -> TimeInterval {
    guard let parsed = TimeInterval(value), parsed >= minimum else {
      fail("invalid --\(name) '\(value)'")
    }
    return parsed
  }

  private static func integer(
    named name: String,
    value: String,
    minimum: Int
  ) -> Int {
    guard let parsed = Int(value), parsed >= minimum else {
      fail("invalid --\(name) '\(value)'")
    }
    return parsed
  }
}

func parseColor(_ value: String) -> NSColor? {
  switch value.lowercased() {
  case "white":
    return .white
  case "black":
    return .black
  default:
    break
  }

  guard value.hasPrefix("#") else { return nil }

  let hex = String(value.dropFirst())
  guard (hex.count == 6 || hex.count == 8), let raw = UInt64(hex, radix: 16) else {
    return nil
  }

  let redShift = hex.count == 6 ? 16 : 24
  let greenShift = hex.count == 6 ? 8 : 16
  let blueShift = hex.count == 6 ? 0 : 8
  let red = CGFloat((raw >> redShift) & 0xff) / 255
  let green = CGFloat((raw >> greenShift) & 0xff) / 255
  let blue = CGFloat((raw >> blueShift) & 0xff) / 255
  let alpha = hex.count == 6 ? 1 : CGFloat(raw & 0xff) / 255
  return NSColor(srgbRed: red, green: green, blue: blue, alpha: alpha)
}

let configuration = Configuration(environment: ProcessInfo.processInfo.environment)

final class Flasher: NSObject, NSApplicationDelegate {
  private let flashes: Int
  private let duration: TimeInterval
  private let gap: TimeInterval
  private let color: NSColor
  private var windows: [NSWindow] = []

  init(configuration: Configuration) {
    flashes = configuration.flashes
    duration = configuration.duration
    gap = configuration.gap
    color = configuration.color
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    windows = NSScreen.screens.map { screen in
      let window = NSWindow(
        contentRect: NSRect(origin: .zero, size: screen.frame.size),
        styleMask: .borderless,
        backing: .buffered,
        defer: false,
        screen: screen
      )
      window.level = .screenSaver
      window.collectionBehavior = [
        .canJoinAllSpaces,
        .fullScreenAuxiliary,
        .stationary,
        .ignoresCycle,
      ]
      window.backgroundColor = color
      window.isOpaque = false
      window.alphaValue = 0
      window.ignoresMouseEvents = true
      window.orderFrontRegardless()
      return window
    }

    flash(remaining: flashes)
  }

  private func flash(remaining: Int) {
    guard remaining > 0 else {
      NSApp.terminate(nil)
      return
    }

    windows.forEach { $0.alphaValue = 1 }

    NSAnimationContext.runAnimationGroup({ context in
      context.duration = duration
      windows.forEach { $0.animator().alphaValue = 0 }
    }, completionHandler: {
      if remaining == 1 {
        NSApp.terminate(nil)
        return
      }

      DispatchQueue.main.asyncAfter(deadline: .now() + self.gap) {
        self.flash(remaining: remaining - 1)
      }
    })
  }
}

let app = NSApplication.shared
let delegate = Flasher(configuration: configuration)
app.setActivationPolicy(.accessory)
app.delegate = delegate
app.run()
