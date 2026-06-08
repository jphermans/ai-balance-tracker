import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
    
    // Customize window AFTER Flutter is fully initialized
    let windowWidth: CGFloat = 800
    let windowHeight: CGFloat = 600
    
    // Center on screen
    if let screen = NSScreen.main {
      let screenFrame = screen.visibleFrame
      let x = (screenFrame.width - windowWidth) / 2 + screenFrame.origin.x
      let y = (screenFrame.height - windowHeight) / 2 + screenFrame.origin.y
      self.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
    }
    
    self.title = "AI Balance Tracker"
    self.titlebarAppearsTransparent = false
    self.isMovableByWindowBackground = false
    
    // Resizable window with minimum 800×600
    self.contentMinSize = NSSize(width: windowWidth, height: windowHeight)
    
    // Fullscreen — keep the green button functional
    self.collectionBehavior = [.fullScreenPrimary]
  }
}
