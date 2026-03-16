//
//  ContentView.swift
//  nomi-mane２
//
//  Created by 川本晴春 on 2026/03/16.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @AppStorage("user_nickname") var nickname: String = ""
    @AppStorage("setup_completed") var setupCompleted: Bool = false
    @State private var isShowingProfile = false
    
    var body: some View {
        if !setupCompleted {
            ProfileSetupView()
        } else {
            NavigationStack {
                VStack(spacing: 60) {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Image(systemName: "hand.wave.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.themeAccentRed)
                        
                        Text("飲みマネ")
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(.themeTextPrimary)
                        
                        Text("こんにちは、\(nickname) さん")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.themeTextSecondary)
                    }
                    
                    VStack(spacing: 20) {
                        NavigationLink(destination: HostView()) {
                            HStack {
                                Image(systemName: "person.2.fill")
                                Text("幹事になる")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PremiumButtonStyle(variant: .solid))
                        
                        NavigationLink(destination: GuestView()) {
                            HStack {
                                Image(systemName: "person.fill.checkmark")
                                Text("参加する")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PremiumButtonStyle(variant: .outlined))
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                    Spacer()
                }
                .appBackground()
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            isShowingProfile = true
                        }) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.themeTextSecondary)
                        }
                    }
                }
                .sheet(isPresented: $isShowingProfile) {
                    NavigationStack {
                        ProfileView()
                    }
                }
            }
            .accentColor(.themeAccentRed)
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
