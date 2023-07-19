//
//  BottomSheetContent.swift
//  
//
//  Created by Parvinder on 19/07/23.
//

import SwiftUI

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {

    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

public struct BottomSheetContent<ContentBody: View> : View {
    var backgroundColor: Color = .white
    var corners: CGFloat = 8
    var contentBody: () -> ContentBody
    
    public init(backgroundColor: Color, corners: CGFloat, contentBody: @escaping () -> ContentBody) {
        self.backgroundColor = backgroundColor
        self.corners = corners
        self.contentBody = contentBody
    }
    
    public var body: some View {
        ZStack {
            VStack {
                backgroundColor
                    .frame(height: 22)
                    .cornerRadius(corners, corners: [UIRectCorner.topLeft, .topRight])
                Spacer()
            }
            contentBody()
                .frame(maxWidth: .infinity)
        }
        .background(
            backgroundColor.ignoresSafeArea()
                .offset(y: 22)
        )
    }
    
}
