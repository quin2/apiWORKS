//
//  HeadersTab.swift
//  apiWORKS
//
//  Created by Quinn Vinlove on 10/23/22.
//

import SwiftUI

struct HeadersTab: View {
    @Binding public var selectedReq: Request?
    @Binding public var reqHeader: [RequestHeader]
    
    @Environment(\.managedObjectContext) var moc
    
    func removeHeader(header: RequestHeader){
        guard let headerIndex = reqHeader.firstIndex(of: header) else { return }
        reqHeader.remove(at: headerIndex)
        
        selectedReq?.headerName = reqHeader.map {$0.key}
        selectedReq?.headerValue = reqHeader.map {$0.value}
        
        try? moc.save()
    }
    
    func addHeader(){
        reqHeader.append(RequestHeader())
        selectedReq?.headerName = reqHeader.map {$0.key}
        selectedReq?.headerValue = reqHeader.map {$0.value}
        
        try? moc.save()
    }
    
    var body: some View {
        VStack {
            ForEach($reqHeader) { $myReqHeader in
                HStack {
                    TextField("Key", text: $myReqHeader.key){
                        selectedReq?.headerName = reqHeader.map {$0.key}
                    }
                    TextField("Value", text: $myReqHeader.value){
                        selectedReq?.headerValue = reqHeader.map {$0.value}
                    }
                    Button(action: {removeHeader(header: myReqHeader)}) {
                        Image(systemName: "trash")
                            .frame(width: 20)
                    }
                }
            }
            HStack{
                Spacer()
                Button(action: addHeader){
                    Image(systemName: "plus")
                        .frame(width: 20)
                }
                .disabled(reqHeader.count >= 5)
            }
            Spacer()
        }
        .padding(10)
        .tabItem {
            Text("Headers")
        }
    }
}

struct HeadersTab_Previews: PreviewProvider {
    static var previews: some View {
        HeadersTab(selectedReq: .constant(nil), reqHeader: .constant([RequestHeader]()))
    }
}
