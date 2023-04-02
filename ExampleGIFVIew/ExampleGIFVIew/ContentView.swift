//
//  ContentView.swift
//  ExampleGIFVIew
//
//  Created by Metin Güler on 01.04.23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            GIFView(name: "demo")
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
