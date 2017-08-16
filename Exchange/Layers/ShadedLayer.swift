import UIKit

class ShadedLayer: QuartzCore.CALayer {

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

    override func draw(in ctx: CGContext) {
        ctx.saveGState()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: frame.width / 2 - 30, y: 0))
        path.addLine(to: CGPoint(x: frame.width / 2 - 3, y: 28))
        path.addLine(to: CGPoint(x: frame.width / 2, y: 30))
        path.addLine(to: CGPoint(x: frame.width / 2 + 3, y: 28))
        path.addLine(to: CGPoint(x: frame.width / 2 + 30, y: 0))
        path.addLine(to: CGPoint(x: frame.width, y: 0))
        path.addLine(to: CGPoint(x: frame.width, y: frame.height))
        path.addLine(to: CGPoint(x: 0, y: frame.height))
        path.close()

        ctx.setFillColor(UIColor.black.withAlphaComponent(0.2).cgColor)
        ctx.addPath(path.cgPath)
        ctx.drawPath(using: .fill)
    }
}
