import UIKit
import Capacitor

class MainViewController: CAPBridgeViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("🎯 MainViewController 加载完成")
    }
    
    override func capacitorDidLoad() {
        NSLog("🎯 开始注册自定义插件 (CAPBridgedPlugin)")
        
        // 注册所有自定义插件
        registerCustomPlugins()
        
        super.capacitorDidLoad()
    }
    
    private func registerCustomPlugins() {
        // 注册ChatOverlay插件
        bridge?.registerPluginInstance(ChatOverlayPlugin())
        
        NSLog("🎯 ChatOverlayPlugin (CAPBridgedPlugin) 注册完成")
    }
}