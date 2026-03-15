//
//  ContentView.swift
//  nomi-mane２
//
//  Created by 川本晴春 on 2026/03/16.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("飲みマネ")
                    .font(.system(size: 40, weight: .bold))
                    .padding(.top, 50)
                
                Spacer()
                
                NavigationLink(destination: HostView()) {
                    HomeButton(title: "幹事になる（発信）", icon: "person.fill.badge.plus", color: .blue)
                }
                
                NavigationLink(destination: GuestView()) {
                    HomeButton(title: "参加する（受信）", icon: "person.2.fill", color: .green)
                }
                
                Spacer()
                Spacer()
            }
            .padding()
        }
    }
}

struct HomeButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title)
            Text(title)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 25)
        .background(color)
        .foregroundColor(.white)
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

#Preview {
    ContentView()
}
