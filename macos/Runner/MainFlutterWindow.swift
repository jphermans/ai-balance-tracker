import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    
    // Fixed window dimensions
    let windowWidth: CGFloat = 800
    let windowHeight: CGFloat = 600
    
    // Center on screen
    if let screen = NSScreen.main {
      let screenFrame = screen.visibleFrame
      let x = (screenFrame.width - windowWidth) / 2 + screenFrame.origin.x
      let y = (screenFrame.height - windowHeight) / 2 + screenFrame.origin.y
      self.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
    } else {
      self.setFrame(NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight), display: true)
    }
    
    self.contentViewController = flutterViewController
    
    // Fixed window — no resize
    self.styleMask.remove(.resizable)
    
    // Title + close/minimize only (no fullscreen)
    self.title = "AI Balance Tracker"
    self.titlebarAppearsTransparent = false
    self.isMovableByWindowBackground = false
    
    // Prevent horizontal scroll: set minimum content size to match window
    self.contentMinSize = NSSize(width: windowWidth, height: windowHeight)
    self.contentMaxSize = NSSize(width: windowWidth, height: CGFloat.greatestFiniteMagnitude)
    
    RegisterGeneratedPlugins(registry: flutterViewController)
    
    super.awakeFromNib()
  }
}
