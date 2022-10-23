//
//  ContentView.swift
//  apiWORKS
//
//  Created by Quinn Vinlove on 7/3/22.
//

import SwiftUI
import CoreData

struct RequestHeader: Identifiable, Hashable {
    let id = UUID()
    var key = ""
    var value = ""
}

enum ApiMode {
    case Development, Production
}

//TODO: verify valid JSON can be sent
struct ContentView: View {
    @State private var apiUrl: String = ""
    @State private var selection = 1
    @State private var apiRequestType = 0
    @State private var apiContentType = 0
    @State private var apiResponse: String = ""
    @State private var apiRequest: String = ""
    
    @State private var reqHeader = [RequestHeader]()
    @State private var presentAddAlert = false
    
    @State private var presentAddCallAlert = false;
    
    @State private var loadingData: Bool = false;
    
    @State private var presentConfirmRemoveCall: Bool = false;
    @State private var presentConfirmRemoveGroup: Bool = false;
    
    @State private var presentGroupSettings = false;
    
    @Environment(\.managedObjectContext) var moc
    
    @FetchRequest(sortDescriptors: []) var apiGroups: FetchedResults<RequestGroup>
    
    @State private var selectedReq: Request?;
    
    @State private var removeTarget: Request?
    
    func startRemoveReq(req: Request){
        removeTarget = req;
        presentConfirmRemoveCall = true
    }
    
    func removeReq(){
        let lastGroup = removeTarget?.group
        
        moc.delete(removeTarget!)
        presentConfirmRemoveCall = false
        selectedReq = nil
        
        try? moc.save()
        
        //remove group, if it is the last call in there
        if(lastGroup?.request?.count == 0){
            moc.delete(lastGroup!)
            try? moc.save()
        }
    }
    
    func getRemoveReqStr() -> String {
        var request = "Are you sure you want to remove " + (removeTarget?.name ?? "") + "?"
        if(removeTarget?.group?.request?.count == 1){
            request += " Removing this request will also remove the group " + (removeTarget?.group?.name ?? "")
        }
        return request
    }
    
    func call(){
        loadingData = true;
        
        let url = URL(string: getCurrentURL(request: selectedReq))!

        var request = URLRequest(url: url)
        //https://cocoacasts.com/networking-fundamentals-how-to-make-an-http-request-in-swift
        
        //set method
        if(apiRequestType == 1){
            request.httpMethod = "POST"
        }
        
        //get content type from header
        var contentType = "application/json"
        if(apiContentType == 0){
            contentType = "text/plain"
        }
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        for header in reqHeader {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }
        
        //set request body
        request.httpBody = apiRequest.data(using: .utf8)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                loadingData = false;
                apiResponse = String(decoding: data, as: UTF8.self)
                
                selectedReq?.lastResponseBody = data
                try? moc.save()
            } else if let error = error {
                loadingData = false;
                apiResponse = error.localizedDescription
            }
        }
        
        task.resume()
    }
    
    private func toggleSidebar() {
           #if os(iOS)
           #else
           NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
           #endif
       }
    
    func removeGroup(){
        moc.delete((selectedReq?.group)!)
        selectedReq = nil
        
        try? moc.save()
        
        presentConfirmRemoveGroup = false
    }
    
    func getRemoveGroupStr() -> String{
        var request = "Are you sure you want to remove " + (selectedReq?.group?.name ?? "") + "?"
        request += " There are " + String(selectedReq?.group?.request?.count ?? 0) + " requests in this group."
        return request
    }
    
    var body: some View {
        NavigationView {
            List(apiGroups, selection: $selectedReq) { group in
                Section(header: Text(group.name ?? "unknown")){
                    ForEach(Array(group.request! as! Set<Request>), id: \.self) { req in
                        HStack {
                            Text(req.name ?? "")
                            Spacer()
                            Button(action: { startRemoveReq(req: req) }){
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .onChange(of: selectedReq ) { req in
                apiUrl = req?.url ?? ""
                apiRequestType = Int(req?.requestType ?? 0)
                apiContentType = Int(req?.contentType ?? 0)
                
                let reqToDecode: Data = req?.requestBody ?? "".data(using: .utf8)!
                apiRequest = String(decoding: reqToDecode, as: UTF8.self)
                
                let lastResponseToDecode: Data = req?.lastResponseBody ?? "".data(using: .utf8)!
                apiResponse = String(decoding: lastResponseToDecode, as: UTF8.self)
                
                //load key set
                let myKeys = req?.headerName ?? []
                let myValues = req?.headerValue ?? []
                reqHeader.removeAll()
                for i in 0..<myKeys.count {
                    reqHeader.append(RequestHeader(key: myKeys[i], value: myValues[i]))
                }
            }
            VStack() {
                if(selectedReq == nil){
                    Text("To begin, select a request or create a new one :)")
                }
                else if(selectedReq != nil) {
                    URLBar(selectedReq: $selectedReq, apiUrl: $apiUrl, apiRequestType: $apiRequestType)
                    TabView {
                        ContentTab(selectedReq: $selectedReq, apiContentType: $apiContentType, apiRequest: $apiRequest)
                        HeadersTab(selectedReq: $selectedReq, reqHeader: $reqHeader)
                    }
                    ResultArea(loadingData: $loadingData, apiResponse: $apiResponse)
                    HStack{
                        Spacer()
                        Button(action: call){
                            Text("Request")
                        }
                    }
                    .disabled(!getCurrentURL(request: selectedReq).isValidURL)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity)
        }
        .listStyle(SidebarListStyle())
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar{
            ToolbarItem(placement: .navigation) {
                Button(action: toggleSidebar, label: { // 1
                    Image(systemName: "sidebar.leading")
                })
            }
            ToolbarItem {
                Button(action: { presentAddAlert = true })
                {
                    Image(systemName: "plus.rectangle.on.folder")
                }
            }
            ToolbarItem {
                Button(action: {presentGroupSettings = true})
                {
                    Image(systemName: "folder.badge.gearshape")
                }
                .disabled(selectedReq == nil)
            }
            ToolbarItem {
                Button(action: { presentAddCallAlert = true })
                {
                    Image(systemName: "plus.square")
                }
                .disabled(apiGroups.count < 1)
            }
        }
        .sheet(isPresented: $presentGroupSettings){
            GroupSettingsSheet(presentGroupSettings: $presentGroupSettings, presentConfirmRemoveGroup: $presentConfirmRemoveGroup, selectedReq: $selectedReq)
        }
        .sheet(isPresented: $presentAddAlert){
            NewGroupSheet(presentAddAlert: $presentAddAlert)
        }
        .sheet(isPresented: $presentAddCallAlert){
            NewRequestSheet(presentAddCallAlert: $presentAddCallAlert)
        }
        .confirmationDialog("Remove request", isPresented: $presentConfirmRemoveCall) {
            Button("Yes", action: removeReq)
        } message: {
            Text(getRemoveReqStr())
        }
        .confirmationDialog("Remove group", isPresented: $presentConfirmRemoveGroup) {
            Button("Yes", action: removeGroup)
        } message: {
            Text(getRemoveGroupStr())
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
