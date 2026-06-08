import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    
    // MUST set contentViewController BEFORE setting frame —
    // setting the controller triggers a layout that resizes the window
    self.contentViewController = flutterViewController
    
    // Fixed window: 800×600, centered
    let windowWidth: CGFloat = 800
    let windowHeight: CGFloat = 600
    if let screen = NSScreen.main {
      let screenFrame = screen.visibleFrame
      let x = (screenFrame.width - windowWidth) / 2 + screenFrame.origin.x
      let y = (screenFrame.height - windowHeight) / 2 + screenFrame.origin.y
      self.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
    } else {
      self.setFrame(NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight), display: true)
    }
    
    // Appearance
    self.title = "AI Balance Tracker"
    self.titlebarAppearsTransparent = false
    self.styleMask.remove(.resizable)
    
    // Prevent horizontal scroll: fixed width, unlimited height for scrolling
    self.contentMinSize = NSSize(width: windowWidth, height: windowHeight)
    self.contentMaxSize = NSSize(width: windowWidth, height: CGFloat.greatestFiniteMagnitude)
    
    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
