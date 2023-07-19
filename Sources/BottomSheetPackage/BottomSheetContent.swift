//
//  BottomSheetContent.swift
//  
//
//  Created by Parvinder on 19/07/23.
//

import SwiftUI

public struct BottomSheetContent<ContentBody: View> : View {
    var backgroundColor: Color = .white
    var corners: CGFloat = 8
    var contentBody: () -> ContentBody
    
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
