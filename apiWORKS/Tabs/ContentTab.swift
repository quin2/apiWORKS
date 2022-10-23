//
//  ContentTab.swift
//  apiWORKS
//
//  Created by Quinn Vinlove on 10/23/22.
//

import SwiftUI

extension NSTextView {
    open override var frame: CGRect {
        didSet {
            self.isAutomaticQuoteSubstitutionEnabled = false
        }
    }
}

struct ContentTab: View {
    @Binding public var selectedReq: Request?
    @Binding public var apiContentType: Int
    @Binding public var apiRequest: String
    
    @Environment(\.managedObjectContext) var moc
    
    var body: some View {
        Form {
            VStack {
                Picker(selection: $apiContentType, label: Text("Content Type")) {
                    Text("Plain text").tag(0)
                    Text("JSON").tag(1)
                }
                .onChange(of: apiContentType) { newValue in
                    selectedReq?.contentType = Int16(newValue)
                    
                    try? moc.save()
                }
                //TODO: better editor
                Section(header: Text("Request data")){
                    TextEditor(text: $apiRequest)
                        .onChange(of: apiRequest) { newValue in
                            selectedReq?.requestBody = newValue.data(using: .utf8)
                            
                            try? moc.save()
                        }
                }
            }
        }
        .padding(10)
        .tabItem {
            Text("Content")
        }
    }
}

struct ContentTab_Previews: PreviewProvider {
    static var previews: some View {
        ContentTab(selectedReq: .constant(nil), apiContentType: .constant(0), apiRequest: .constant(""))
    }
}
