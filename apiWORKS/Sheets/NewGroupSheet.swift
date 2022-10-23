//
//  NewGroupSheet.swift
//  apiWORKS
//
//  Created by Quinn Vinlove on 10/23/22.
//

import SwiftUI

struct NewGroupSheet: View {
    @State private var tempGroupName = ""
    @Binding public var presentAddAlert: Bool
    
    @Environment(\.managedObjectContext) var moc
    
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
    
    var body: some View {
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
}

struct NewGroupSheet_Previews: PreviewProvider {
    static var previews: some View {
        NewGroupSheet(presentAddAlert: .constant(false))
    }
}
