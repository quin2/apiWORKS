//
//  GroupSettingsSheet.swift
//  apiWORKS
//
//  Created by Quinn Vinlove on 10/23/22.
//

import SwiftUI

struct GroupSettingsSheet: View {
    
    @State private var tempRequestMode: ApiMode = ApiMode.Development;
    @State private var tempGroupEditName = ""
    @State private var tempDevPrefix = ""
    @State private var tempProdPrefix = ""
    
    @Binding public var presentGroupSettings: Bool
    @Binding public var presentConfirmRemoveGroup: Bool
    @Binding public var selectedReq: Request?;
    
    @Environment(\.managedObjectContext) var moc
    
    func loadGroupSettings(){
        tempGroupEditName = selectedReq?.group?.name ?? ""
        
        if isTrue(selectedReq?.group?.devMode) {
            tempRequestMode = ApiMode.Development
        } else {
            tempRequestMode = ApiMode.Production
        }
        tempDevPrefix = selectedReq?.group?.devPrefix ?? ""
        tempProdPrefix = selectedReq?.group?.prodPrefix ?? ""
    }
    
    func saveGroupSettings(){
        selectedReq?.group?.name = tempGroupEditName
        if(tempRequestMode == ApiMode.Development){
            selectedReq?.group?.devMode = true;
        } else {
            selectedReq?.group?.devMode = false;
        }
        selectedReq?.group?.devPrefix = tempDevPrefix
        selectedReq?.group?.prodPrefix = tempProdPrefix

        presentGroupSettings = false
        
        try? moc.save()
    }
    
    func cancelGroupSettings(){
        presentGroupSettings = false
    }
    
    func startRemoveGroup(){
        presentGroupSettings = false
        presentConfirmRemoveGroup = true
    }
    
    func isTrue(_ bool: Bool?) -> Bool {
        guard let b = bool else {
            return false
        }
        return b
    }
    
    var body: some View {
        VStack{
            Text("Project settings")
                .font(.title)
            
            Form{
                TextField(text: $tempGroupEditName, prompt: Text("Name")){
                    Text("Project name:")
                }
                Picker(selection: $tempRequestMode, label: Text("Mode:")) {
                    Text("Development").tag(ApiMode.Development)
                    Text("Production").tag(ApiMode.Production)
                }.pickerStyle(RadioGroupPickerStyle())
                
                TextField(text: $tempDevPrefix, prompt: Text("http://")){
                    Text("Development root:")
                }
                TextField(text: $tempProdPrefix, prompt: Text("http://")){
                    Text("Production root:")
                }
            }
            
            Spacer()
            
            HStack{
                Button("Delete group", action: startRemoveGroup)
                Spacer()
                Button("Cancel", role: .cancel, action: cancelGroupSettings)
                Button("OK", action: saveGroupSettings)
            }
        }
        .frame(width: 350, height: 250)
        .padding()
        .onAppear(perform: loadGroupSettings)
    }
}

struct GroupSettingsSheet_Previews: PreviewProvider {
    static var previews: some View {
        GroupSettingsSheet(presentGroupSettings: .constant(false), presentConfirmRemoveGroup: .constant(false), selectedReq: .constant(nil))
    }
}
