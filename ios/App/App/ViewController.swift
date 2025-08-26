import UIKit
import Capacitor

class ViewController: CAPBridgeViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("🎯 ViewController viewDidLoad - 准备注册插件")
    }

    override func capacitorDidLoad() {
        NSLog("🎯 capacitorDidLoad - 开始注册自定义插件")
        
        // 注册ChatOverlay插件
        bridge?.registerPluginInstance(ChatOverlayPlugin())
        NSLog("🎯 ChatOverlayPlugin 注册完成")
        
        // 注册SimpleTestPlugin插件  
        bridge?.registerPluginInstance(SimpleTestPlugin())
        NSLog("🎯 SimpleTestPlugin 注册完成")
        
        super.capacitorDidLoad()
    }
}