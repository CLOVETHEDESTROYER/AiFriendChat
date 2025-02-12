import SwiftUI

struct ZigZagView: View {
    var height: CGFloat = 20
    var segments: Int = 8
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let segmentWidth = width / CGFloat(segments)
                
                path.move(to: CGPoint(x: 0, y: 0))
                
                for segment in 0..<segments {
                    let x1 = CGFloat(segment) * segmentWidth
                    let x2 = x1 + (segmentWidth / 2)
                    let x3 = x1 + segmentWidth
                    
                    if segment == 0 {
                        path.move(to: CGPoint(x: x1, y: 0))
                    }
                    
                    path.addLine(to: CGPoint(x: x2, y: height))
                    path.addLine(to: CGPoint(x: x3, y: 0))
                }
            }
            .stroke(Color("zigzag"), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
        .frame(height: height)
    }
}

#Preview {
    ZigZagView()
        .padding()
        .background(Color.black)
} 