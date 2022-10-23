//
//  URLBar.swift
//  apiWORKS
//
//  Created by Quinn Vinlove on 10/23/22.
//

import SwiftUI

struct URLBar: View {
    @Binding public var selectedReq: Request?
    @Binding public var apiUrl: String
    @Binding public var apiRequestType: Int
    
    @Environment(\.managedObjectContext) var moc
    
    var body: some View {
        HStack{
            Form {
                Section(header: Text(selectedReq?.name ?? "").font(.title)){
                    HStack {
                        TextField("URL: " + getCurrentPrefix(request: selectedReq), text: $apiUrl){ //"URL", text: $apiUrl
                            selectedReq?.url = apiUrl
                            try? moc.save()
                        }
                        Picker(selection: $apiRequestType, label: Text("Method")) {
                            Text("GET").tag(0)
                            Text("POST").tag(1)
                        }
                        .onChange(of: apiRequestType) { newValue in
                            selectedReq?.requestType = Int16(newValue)
                            try? moc.save()
                        }
                        .frame(width: 200)
                        
                    }
                }
            }
        }
    }
}

struct URLBar_Previews: PreviewProvider {
    static var previews: some View {
        URLBar(selectedReq: .constant(nil), apiUrl: .constant(""), apiRequestType: .constant(0))
    }
}
