//
//  ContentView.swift
//  FWG
//
//  Created by Ferid Suleymanzade on 02.12.24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var gameViewModel = GameViewModel()
    
    var body: some View {
        VStack {
            HeaderView()
            GameBoardView(viewModel: gameViewModel)
            ControlButtonsView(viewModel: gameViewModel)
            PieceSelectorView(viewModel: gameViewModel)
        }
    }
}

// Header View
struct HeaderView: View {
    var body: some View {
        Text("Pentominoes")
            .font(.largeTitle)
            .padding()
    }
}

// Control Buttons View
struct ControlButtonsView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        HStack {
            Button(action: {
                viewModel.undoLastPlacement()
            }) {
                Image(systemName: "arrow.uturn.backward")
                Text("Geri Al")
            }
            .disabled(!viewModel.canUndo)
            .padding()
            
            Spacer()
        }
    }
}

// Game Board View
struct GameBoardView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var dragLocation: CGPoint?
    @State private var highlightedCell: (row: Int, col: Int)?
    
    var body: some View {
        BoardGridView(viewModel: viewModel, highlightedCell: highlightedCell)
            .padding()
            .dropDestination(for: PentominoPiece.self) { pieces, location in
                handleDrop(pieces: pieces, location: location)
            } isTargeted: { isTargeted in
                if !isTargeted {
                    highlightedCell = nil
                }
            }
            .gesture(makeDragGesture())
    }
    
    private func handleDrop(pieces: [PentominoPiece], location: CGPoint) -> Bool {
        guard let piece = pieces.first else { return false }
        
        let gridSize: CGFloat = 40
        let padding: CGFloat = 16
        
        var row = Int((location.y - padding) / gridSize)
        var column = Int((location.x - padding) / gridSize)
        
        row = max(0, min(row, 5))
        column = max(0, min(column, 9))
        
        DispatchQueue.main.async {
            viewModel.placePiece(piece, at: (row, column))
        }
        
        return true
    }
    
    private func makeDragGesture() -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let gridSize: CGFloat = 40
                let padding: CGFloat = 16
                
                let row = Int((value.location.y - padding) / gridSize)
                let column = Int((value.location.x - padding) / gridSize)
                
                if row >= 0 && row < 6 && column >= 0 && column < 10 {
                    highlightedCell = (row, column)
                }
            }
            .onEnded { _ in
                highlightedCell = nil
            }
    }
}

// Board Grid View
struct BoardGridView: View {
    let viewModel: GameViewModel
    let highlightedCell: (row: Int, col: Int)?
    
    var body: some View {
        Grid(horizontalSpacing: 1, verticalSpacing: 1) {
            ForEach(0..<6) { row in
                GridRow {
                    ForEach(0..<10) { column in
                        CellView(
                            filled: viewModel.isCellFilled(row: row, column: column),
                            isHighlighted: highlightedCell?.row == row && highlightedCell?.col == column
                        )
                    }
                }
            }
        }
    }
}

// Cell View
struct CellView: View {
    let filled: Bool
    let isHighlighted: Bool
    
    var body: some View {
        Rectangle()
            .fill(filled ? Color.blue : (isHighlighted ? Color.green.opacity(0.3) : Color.gray.opacity(0.3)))
            .frame(width: 40, height: 40)
            .border(isHighlighted ? Color.green : Color.black, width: 0.5)
            .animation(.easeInOut, value: filled)
            .animation(.easeInOut, value: isHighlighted)
    }
}

// Piece Selector View
struct PieceSelectorView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(viewModel.availablePieces) { piece in
                    PieceView(piece: piece, viewModel: viewModel)
                }
            }
        }
        .padding()
    }
}

// Piece View
struct PieceView: View {
    let piece: PentominoPiece
    @ObservedObject var viewModel: GameViewModel
    @State private var isDragging = false
    
    var isSelected: Bool {
        viewModel.selectedPiece?.id == piece.id
    }
    
    var body: some View {
        PieceShapeView(piece: piece, isSelected: isSelected)
            .padding(5)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(5)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isDragging ? 1.2 : 1.0)
            .contextMenu { PieceContextMenu(viewModel: viewModel) }
            .onTapGesture { viewModel.selectPiece(piece) }
            .addPieceKeyboardControls(viewModel: viewModel, isSelected: isSelected)
            .draggable(piece) {
                DraggablePieceView(piece: piece, viewModel: viewModel, isDragging: $isDragging)
            }
    }
}

// Piece Shape View
struct PieceShapeView: View {
    let piece: PentominoPiece
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 1) {
            ForEach(0..<piece.shape.count, id: \.self) { row in
                HStack(spacing: 1) {
                    ForEach(0..<piece.shape[row].count, id: \.self) { col in
                        Rectangle()
                            .fill(piece.shape[row][col] ? (isSelected ? Color.green : Color.blue) : Color.clear)
                            .frame(width: 20, height: 20)
                    }
                }
            }
        }
    }
}

// Piece Context Menu
struct PieceContextMenu: View {
    let viewModel: GameViewModel
    
    var body: some View {
        Button("90° Döndür") {
            withAnimation {
                viewModel.rotateSelectedPiece()
            }
        }
        Button("Yatay Çevir") {
            withAnimation {
                viewModel.flipSelectedPieceHorizontally()
            }
        }
        Button("Dikey Çevir") {
            withAnimation {
                viewModel.flipSelectedPieceVertically()
            }
        }
    }
}

// Draggable Piece View
struct DraggablePieceView: View {
    let piece: PentominoPiece
    let viewModel: GameViewModel
    @Binding var isDragging: Bool
    
    var body: some View {
        PieceShapeView(piece: piece, isSelected: true)
            .opacity(0.8)
            .onAppear {
                withAnimation {
                    isDragging = true
                    viewModel.selectPiece(piece)
                }
            }
            .onDisappear {
                withAnimation {
                    isDragging = false
                }
            }
    }
}

// Keyboard Controls View Modifier
extension View {
    func addPieceKeyboardControls(viewModel: GameViewModel, isSelected: Bool) -> some View {
        self
            .onKeyPress("r") { 
                if isSelected {
                    viewModel.rotateSelectedPiece()
                    return .handled
                }
                return .ignored
            }
            .onKeyPress("h") { 
                if isSelected {
                    viewModel.flipSelectedPieceHorizontally()
                    return .handled
                }
                return .ignored
            }
            .onKeyPress("v") { 
                if isSelected {
                    viewModel.flipSelectedPieceVertically()
                    return .handled
                }
                return .ignored
            }
    }
}

#Preview {
    ContentView()
}
