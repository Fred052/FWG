//
//  StartScreenView.swift
//  FWG
//
//  Created by Ferid Suleymanzade on 03.12.24.
//

import SwiftUI

struct StartScreenView: View {
    @State private var startGame = false
    @State private var startARGame = false
    
    var body: some View {
        if startGame {
            ContentView()
        } else if startARGame {
            ARGameView()
        } else {
            VStack(spacing: 30) {
                Text("Pentominoes Puzzle")
                    .font(.largeTitle)
                    .padding()
                
                Button(action: {
                    withAnimation {
                        startGame = true
                    }
                }) {
                    GameButton(title: "Play Game")
                }
                
                Button(action: {
                    withAnimation {
                        startARGame = true
                    }
                }) {
                    GameButton(title: "Play with AR")
                }
            }
        }
    }
}

// Button Style Component

struct GameButton: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.title)
            .foregroundColor(.white)
            .padding()
            .frame(width: 200)
            .background(Color.blue)
            .cornerRadius(10)
    }
}

#Preview {
    StartScreenView()
}
