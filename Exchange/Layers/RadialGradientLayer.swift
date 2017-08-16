import UIKit

class RadialGradientLayer: CALayer {

    required override init() {
        super.init()
        needsDisplayOnBoundsChange = true
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    required override init(layer: Any) {
        super.init(layer: layer)
    }

    public var colors = [UIColor(red: 9, green: 143, blue: 233).cgColor,
                         UIColor(red: 1, green: 81, blue: 176).cgColor]

    override func draw(in ctx: CGContext) {
        ctx.saveGState()

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var locations = [CGFloat]()
        for i in 0...colors.count - 1 {
            locations.append(CGFloat(i) / CGFloat(colors.count))
        }
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations)
        let center = CGPoint(x: bounds.width / 2.0, y: bounds.height / 2.0)
        let radius = bounds.height
        ctx.drawRadialGradient(gradient!, startCenter: center, startRadius: 0.0, endCenter: center,
                endRadius: radius, options: CGGradientDrawingOptions(rawValue: 0))
    }
}
