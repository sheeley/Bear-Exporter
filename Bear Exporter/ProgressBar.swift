//
//  ProgressBar.swift
//  Bear Exporter
//
//  Created by Johnny Sheeley on 2/2/20.
//  Copyright © 2020 Johnny Sheeley. All rights reserved.
//

import SwiftUI

struct ProgressBar: View {
    @Binding var value:CGFloat

    func getProgressBarWidth(geometry:GeometryProxy) -> CGFloat {
        let frame = geometry.frame(in: .global)
        return frame.size.width * value
    }

    func getPercentage(_ value:CGFloat) -> String {
        let intValue = Int(ceil(value * 100))
        return "\(intValue) %"
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .trailing) {
                Text("Progress: \(self.getPercentage(self.value))")
                    .padding()
                ZStack(alignment: .leading) {
                    Rectangle()
                        .opacity(0.1)
                    Rectangle()
                        .frame(minWidth: 0, idealWidth:self.getProgressBarWidth(geometry: geometry),
                               maxWidth: self.getProgressBarWidth(geometry: geometry))
                        .opacity(0.5)
                        .background(Color.gray)
                        .animation(.default)
                }
                .frame(height:10)
            }.frame(height:10)
        }
    }
}

struct ProgressBar_Previews: PreviewProvider {
    
    static var previews: some View {
        // @State(initialValue: "") var code: String
        ProgressBar(value: .constant(55.5))
    }
}
