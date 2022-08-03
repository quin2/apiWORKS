//
//  ContentView.swift
//  apiWORKS
//
//  Created by Quinn Vinlove on 7/3/22.
//

import SwiftUI
import CoreData

extension Binding where Value == String? {
    func onNone(_ fallback: String) -> Binding<String> {
        return Binding<String>(get: {
            return self.wrappedValue ?? fallback
        }) { value in
            self.wrappedValue = value
        }
    }
}

extension Optional where Wrapped == String {
    var _bound: String? {
        get {
            return self
        }
        set {
            self = newValue
        }
    }
    public var bound: String {
        get {
            return _bound ?? ""
        }
        set {
            _bound = newValue.isEmpty ? nil : newValue
        }
    }
}

extension String {
    var isValidURL: Bool {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
            // it is a link, if the match covers the whole string
            return match.range.length == self.utf16.count
        } else {
            return false
        }
    }
}

struct RequestHeader: Identifiable, Hashable {
    let id = UUID()
    var key = ""
    var value = ""
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
    @State private var tempGroupName = ""
    
    @State private var presentAddCallAlert = false;
    @State private var tempCallName = ""
    @State private var tempCallParent: RequestGroup?;
    
    @State private var loadingData: Bool = false;
    
    @State private var presentConfirmRemoveCall: Bool = false;
    
    @Environment(\.managedObjectContext) var moc
    
    @FetchRequest(sortDescriptors: []) var apiGroups: FetchedResults<RequestGroup>
    
    @State private var selectedReq: Request?;
    
    @State private var removeTarget: Request?
    
    func addGroup() {
        if(tempGroupName == ""){
            presentAddAlert = false
            return
        }
            
        let group = RequestGroup(context: moc)
        group.id = UUID()
        group.name = tempGroupName
        
        try? moc.save()
        
        tempGroupName = ""
        presentAddAlert = false
    }
    
    func cancelAddGroup(){
        presentAddAlert = false
    }
    
    func addCall(){
        if(tempCallName == "" || tempCallParent == nil){
            presentAddCallAlert = false
            return
        }
        
        let call = Request(context: moc)
        call.name = tempCallName
        call.group = tempCallParent
        
        tempCallParent?.addToRequest(call)
        
        try? moc.save()
        
        tempCallName = ""
        presentAddCallAlert = false
        return
    }
    
    func cancelAddCall(){
        presentAddCallAlert = false;
    }
    
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
    
    func call(){
        loadingData = true;
        
        let url = URL(string: apiUrl)!

        var request = URLRequest(url: url)
        //https://cocoacasts.com/networking-fundamentals-how-to-make-an-http-request-in-swift
        
        //set method
        if(apiRequestType == 1){
            request.httpMethod = "POST"
        }
        
        //get content type from header
        var contentType = "application/json"
        if(apiContentType == 1){
            contentType = "text/plain"
        }
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        for header in reqHeader {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }
        
        //set request body
        //TODO: make encoding explicit
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
                    HStack{
                        Form {
                            Section(header: Text(selectedReq?.name ?? "").font(.title)){
                                HStack {
                                    TextField("URL", text: $apiUrl){ //"URL", text: $apiUrl
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
                    TabView {
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
                    HStack{
                        Spacer()
                        Button(action: call){
                            Text("Request")
                        }
                    }
                    .disabled(!apiUrl.isValidURL)
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
                Button(action: { presentAddCallAlert = true })
                {
                    Image(systemName: "plus.square")
                }
                .disabled(apiGroups.count < 1)
            }
        }
        .sheet(isPresented: $presentAddAlert){
            VStack{
                Text("Enter the name of your new project").font(.headline)
                TextField("Group Name", text: $tempGroupName)
                HStack {
                    Spacer()
                    Button("Cancel", role: .cancel, action: cancelAddGroup)
                    Button("OK", action: addGroup)
                        .disabled(tempGroupName.isEmpty)
                }
            }
            .frame(width: 300, height: 100)
            .padding()
        }
        .sheet(isPresented: $presentAddCallAlert){
            VStack{
                Text("New API call").font(.headline)
                Picker(selection: $tempCallParent, label: Text("Project")) {
                    ForEach(apiGroups, id: \.self) { group in
                        Text(group.name ?? "").tag(group as RequestGroup?)
                    }
                }
                TextField("Name", text: $tempCallName)
                HStack {
                    Spacer()
                    Button("Cancel", role: .cancel, action: cancelAddCall)
                    Button("OK", action: addCall)
                        .disabled(tempCallName.isEmpty || tempCallParent == nil)
                }
            }
            .frame(width: 300, height: 100)
            .padding()
        }
        .confirmationDialog("Remove request", isPresented: $presentConfirmRemoveCall) {
            Button("Yes", action: removeReq)
        } message: {
            Text(getRemoveReqStr())
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
