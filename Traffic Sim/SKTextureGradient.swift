//
// Modified based on https://gist.github.com/Tantas/7fc01803d6b559da48d6, https://gist.github.com/craiggrummitt/ad855e358004b5480960 by Maxim Bilan
//
import SpriteKit

public enum GradientDirection {
    case up
    case left
    case upLeft
    case upRight
}

public extension SKTexture {
    
    convenience init(size: CGSize, color1: CIColor, color2: CIColor, from: CGPoint, to: CGPoint) {
        
        let context = CIContext(options: nil)
        let filter = CIFilter(name: "CILinearGradient")
        let startVector = CIVector(x: from.x, y: from.y)
        let endVector = CIVector(x: to.x, y: to.y)
        
        filter!.setDefaults()
        
        filter!.setValue(startVector, forKey: "inputPoint0")
        filter!.setValue(endVector, forKey: "inputPoint1")
        filter!.setValue(color1, forKey: "inputColor0")
        filter!.setValue(color2, forKey: "inputColor1")
        
        let image = context.createCGImage(filter!.outputImage!, from: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        self.init(cgImage: image!)
    }
    
}
