//
//  ContentView.swift
//  Handy
//
//  Created by Mahmoud Aoata on 1.09.2024.
//

import SwiftUI

struct ContentView: View {
    
    @State private var labelText: String = ""
    var body: some View {
        
        ZStack {
            ARViewContainer(labelText: $labelText)
                .edgesIgnoringSafeArea(.all)
            VStack {
               // TextField("Enter text", text: $labelText)
               //     .padding()
                Spacer()
            }
            .padding()
        }
        
    }
}

#Preview {
    ContentView()
}
