import Foundation
import Capacitor

@objc(SimpleTestPlugin)
public class SimpleTestPlugin: CAPPlugin, CAPBridgedPlugin {
    
    public let identifier = "SimpleTestPlugin"
    public let jsName = "SimpleTestPlugin"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "test", returnType: CAPPluginReturnPromise)
    ]
    
    public override init() {
        super.init()
        NSLog("🧪 SimpleTestPlugin (Swift现代版本) 已初始化!")
    }
    
    @objc func test(_ call: CAPPluginCall) {
        NSLog("🧪 SimpleTestPlugin test方法被调用!")
        call.resolve(["message": "Swift插件工作正常!"])
    }
}