import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  
  private var mainWindow: NSWindow?
  
  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Let Flutter set up first
    super.applicationDidFinishLaunching(notification)
    
    let windowWidth: CGFloat = 800
    let windowHeight: CGFloat = 600
    
    // Create the Flutter view controller
    let flutterViewController = FlutterViewController()
    RegisterGeneratedPlugins(registry: flutterViewController)
    
    // Create the window programmatically
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight),
      styleMask: [.titled, .closable, .miniaturizable],
      backing: .buffered,
      defer: false
    )
    
    window.title = "AI Balance Tracker"
    window.contentViewController = flutterViewController
    window.isReleasedWhenClosed = false
    
    // Fixed size
    window.styleMask.remove(.resizable)
    window.contentMinSize = NSSize(width: windowWidth, height: windowHeight)
    window.contentMaxSize = NSSize(width: windowWidth, height: CGFloat.greatestFiniteMagnitude)
    
    // Center on screen
    window.center()
    
    // Show it
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
    
    self.mainWindow = window
  }
  
  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if !flag, let window = mainWindow {
      window.makeKeyAndOrderFront(nil)
    }
    return true
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
