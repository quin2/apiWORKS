//
//  ResultArea.swift
//  apiWORKS
//
//  Created by Quinn Vinlove on 10/23/22.
//

import SwiftUI

struct ResultArea: View {
    @Binding public var loadingData: Bool
    @Binding public var apiResponse: String
    
    var body: some View {
        HStack {
            Form {
                Section(header: Text("Result").font(.title2)){
                    GeometryReader { geometry in
                        if(loadingData){
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .position(x: geometry.frame(in: .local).midX, y: geometry.frame(in: .local).midY)
                        }
                        else{
                            ScrollView {
                                Text(apiResponse)
                                    .lineLimit(nil)
                                    .frame(width: geometry.size.width, alignment: .leading)
                                    .padding(0)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct ResultArea_Previews: PreviewProvider {
    static var previews: some View {
        ResultArea(loadingData: .constant(false), apiResponse: .constant("response goes here"))
    }
}
