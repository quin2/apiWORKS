//
//  NewRequestSheet.swift
//  apiWORKS
//
//  Created by Quinn Vinlove on 10/23/22.
//

import SwiftUI

struct NewRequestSheet: View {
    @State private var tempCallName = ""
    @State private var tempCallParent: RequestGroup?;
    
    @Binding public var presentAddCallAlert: Bool
    
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: []) var apiGroups: FetchedResults<RequestGroup>
    
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
    
    var body: some View {
        VStack{
            Text("New API call").font(.headline)
            Picker(selection: $tempCallParent, label: Text("Project")) {
                ForEach(apiGroups, id: \.self) { group in
                    Text(group.name ?? "").tag(group as RequestGroup?)
                }
            }
            .onAppear(perform: {tempCallParent = apiGroups[0]})
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
}

struct NewRequestSheet_Previews: PreviewProvider {
    static var previews: some View {
        NewRequestSheet(presentAddCallAlert: .constant(false))
    }
}
