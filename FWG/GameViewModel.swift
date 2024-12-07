import SwiftUI
import UniformTypeIdentifiers

class GameViewModel: ObservableObject {
    @Published var board: [[Bool]] = Array(repeating: Array(repeating: false, count: 10), count: 6)
    @Published var selectedPiece: PentominoPiece?
    @Published var availablePieces: [PentominoPiece] = []
    @Published  private var moves: [Move] = []
    
    // Son hamleyi takip etmek için
    private var lastPlacement: (piece: PentominoPiece, position: (row: Int, col: Int))?
    
    // Parçanın mevcut rotasyon durumunu takip etmek için
    @Published var pieceRotations: [Int: Int] = [:] // [pieceId: rotationState]
    
    init() {
        setupPieces()
    }
    
    struct Move {
        let piece: PentominoPiece
        let position: (row: Int, col: Int)
    }
    
    func setupPieces() {
        // Standart pentomino parçaları (her biri 5 kareden oluşur)
        availablePieces = [
            // F parçası
            PentominoPiece(id: 1, shape: [
                [false, true, true],
                [true, true, false],
                [false, true, false]
            ]),
            
            // I parçası
            PentominoPiece(id: 2, shape: [
                [true, true, true, true, true]
            ]),
            
            // L parçası
            PentominoPiece(id: 3, shape: [
                [true, false, false, false],
                [true, true, true, true]
            ]),
            
            // N parçası
            PentominoPiece(id: 4, shape: [
                [false, false, true],
                [true, true, true],
                [true, false, false]
            ]),
            
            // P parçası
            PentominoPiece(id: 5, shape: [
                [true, true],
                [true, true],
                [true, false]
            ]),
            
            // T parçası
            PentominoPiece(id: 6, shape: [
                [true, true, true],
                [false, true, false],
                [false, true, false]
            ]),
            
            // U parçası
            PentominoPiece(id: 7, shape: [
                [true, false, true],
                [true, true, true]
            ]),
            
            // V parçası
            PentominoPiece(id: 8, shape: [
                [true, false, false],
                [true, false, false],
                [true, true, true]
            ]),
            
            // W parçası
            PentominoPiece(id: 9, shape: [
                [true, false, false],
                [true, true, false],
                [false, true, true]
            ]),
            
            // X parçası
            PentominoPiece(id: 10, shape: [
                [false, true, false],
                [true, true, true],
                [false, true, false]
            ]),
            
            // Y parçası
            PentominoPiece(id: 11, shape: [
                [false, true],
                [true, true],
                [false, true],
                [false, true]
            ]),
            
            // Z parçası
            PentominoPiece(id: 12, shape: [
                [true, true, false],
                [false, true, false],
                [false, true, true]
            ])
        ]
        
        // Parçaları rastgele karıştır
        availablePieces.shuffle()
    }
    
    // Parçayı döndürme fonksiyonu
    func rotatePiece(_ piece: PentominoPiece) -> [[Bool]] {
        // Mevcut rotasyon durumunu al veya 0'dan başla
        let currentRotation = pieceRotations[piece.id] ?? 0
        // Yeni rotasyon durumu (0, 1, 2, 3)
        let newRotation = (currentRotation + 1) % 4
        
        var rotatedShape = piece.shape
        
        switch newRotation {
        case 0: // Orijinal pozisyon
            rotatedShape = piece.shape
        case 1: // 90 derece saat yönünde
            rotatedShape = rotate90Clockwise(piece.shape)
        case 2: // 180 derece
            rotatedShape = rotate90Clockwise(rotate90Clockwise(piece.shape))
        case 3: // 270 derece
            rotatedShape = rotate90Clockwise(rotate90Clockwise(rotate90Clockwise(piece.shape)))
        default:
            break
        }
        
        // Yeni rotasyon durumunu kaydet
        pieceRotations[piece.id] = newRotation
        
        return rotatedShape
    }
    
    private func rotate90Clockwise(_ shape: [[Bool]]) -> [[Bool]] {
        let rows = shape.count
        let cols = shape[0].count
        var rotated = Array(repeating: Array(repeating: false, count: rows), count: cols)
        
        for i in 0..<rows {
            for j in 0..<cols {
                rotated[j][rows - 1 - i] = shape[i][j]
            }
        }
        return rotated
    }
    
    // Parçayı yatay çevirme fonksiyonu
    func flipPieceHorizontally(_ piece: PentominoPiece) -> [[Bool]] {
        return piece.shape.map { $0.reversed() }
    }
    
    func flipPieceVertically(_ piece: PentominoPiece) -> [[Bool]] {
        // Dikey çevirme
        return piece.shape.reversed()
    }
    
    func isCellFilled(row: Int, column: Int) -> Bool {
        return board[row][column]
    }
    
    func selectPiece(_ piece: PentominoPiece) {
        print("Selecting piece: \(piece.id)")
        selectedPiece = piece
    }
    
    // Parçanın yerleştirilebilir olup olmadığını kontrol et
    func canPlacePiece(_ piece: PentominoPiece, at position: (row: Int, col: Int)) -> Bool {
        let shape = piece.shape
        let rows = shape.count
        let cols = shape[0].count
        
        // Önce sınırları kontrol et (6x10 için güncellendi)
        if position.row < 0 || position.row + rows > 6 || 
           position.col < 0 || position.col + cols > 10 {
            print("Out of bounds check failed")
            return false
        }
        
        // Çakışma kontrolü
        for i in 0..<rows {
            for j in 0..<cols {
                if shape[i][j] {
                    let boardRow = position.row + i
                    let boardCol = position.col + j
                    
                    // Ekstra sınır kontrolü
                    if boardRow < 0 || boardRow >= board.count || 
                       boardCol < 0 || boardCol >= board[0].count {
                        print("Position would be out of bounds: \(boardRow), \(boardCol)")
                        return false
                    }
                    
                    // Çakışma kontrolü
                    if board[boardRow][boardCol] {
                        print("Collision detected at: \(boardRow), \(boardCol)")
                        return false
                    }
                }
            }
        }
        
        return true
    }
    
    // Parçayı yerleştir
    func placePiece(_ piece: PentominoPiece, at position: (row: Int, col: Int)) {
        print("Trying to place piece at position: \(position.row), \(position.col)")
        
        // Parçanın şeklini al
        let shape = piece.shape
        let rows = shape.count
        let cols = shape[0].count
        
        // Parçanın merkezini hesapla
        let centerRow = max(0, min(position.row - rows/2, board.count - rows))
        let centerCol = max(0, min(position.col - cols/2, board[0].count - cols))
        
        // Yeni pozisyonu kontrol et
        guard canPlacePiece(piece, at: (centerRow, centerCol)) else {
            print("Cannot place piece at this position")
            return
        }
        
        // Tahtayı güncelle
        objectWillChange.send()
        
        // Geçici bir board kopyası oluştur
        var newBoard = board
        
        // Parçayı yerleştirmeyi dene
        for i in 0..<rows {
            for j in 0..<cols {
                if shape[i][j] {
                    let boardRow = centerRow + i
                    let boardCol = centerCol + j
                    
                    // Son bir sınır kontrolü daha
                    guard boardRow >= 0 && boardRow < board.count && 
                          boardCol >= 0 && boardCol < board[0].count else {
                        print("Final bounds check failed")
                        return
                    }
                    
                    newBoard[boardRow][boardCol] = true
                }
            }
        }
        
        // Yerleştirme başarılı olduysa değişiklikleri uygula
        board = newBoard
        
        addMove(piece: piece, at: (centerRow, centerCol))
        
        // Son hamleyi kaydet
        lastPlacement = (piece, (centerRow, centerCol))
        
        // Yerleştirilen parçayı available pieces'dan kaldır
        if let index = availablePieces.firstIndex(where: { $0.id == piece.id }) {
            availablePieces.remove(at: index)
        }
        
        selectedPiece = nil
        print("Piece placed successfully")
    }
    
    // Son hamleyi geri al
    func undoLastPlacement() {
        guard let lastMove = moves.last else { return }
        
        let shape = lastMove.piece.shape
        for i in 0..<shape.count {
            for j in 0..<shape[0].count {
                if shape[i][j] {
                    board[lastMove.position.row + i][lastMove.position.col + j] = false
                }
            }
        }
        
        // Parçayı tekrar kullanılabilir parçalara ekle
        availablePieces.append(lastMove.piece)
        
        moves.removeLast()
        
        // Son hamleyi temizle
        selectedPiece = nil
    }
    
    func addMove(piece: PentominoPiece, at position: (row: Int, col: Int)) {
        let move = Move(piece: piece, position: position)
        moves.append(move)
    }
    
    // Yerleştirmenin geçerli olup olmadığını kontrol et
    func isValidPlacement() -> Bool {
        // Burada çözülebilirlik kontrolü yapılabilir
        // Şimdilik basit bir kontrol ekleyelim
        
        // Boş hücrelerin sayısını kontrol et
        var emptyCount = 0
        for row in board {
            for cell in row {
                if !cell {
                    emptyCount += 1
                }
            }
        }
        
        // Kalan boş hücre sayısı 5'in katı olmalı
        // (her pentomino parçası 5 hücre kaplar)
        return emptyCount % 5 == 0
    }
    
    // Geri alma butonu için kontrol
    var canUndo: Bool {
        !moves.isEmpty
    }
    
    // Seçili parçayı döndür
    func rotateSelectedPiece() {
        guard let selected = selectedPiece else { return }
        let rotatedShape = rotatePiece(selected)
        selectedPiece = PentominoPiece(id: selected.id, shape: rotatedShape)
        
        if let index = availablePieces.firstIndex(where: { $0.id == selected.id }) {
            availablePieces[index] = selectedPiece!
        }
    }
    
    // Seçili parçayı yatay çevir
    func flipSelectedPieceHorizontally() {
        guard let selected = selectedPiece else { return }
        let flippedShape = flipPieceHorizontally(selected)
        selectedPiece = PentominoPiece(id: selected.id, shape: Array(flippedShape))
        
        if let index = availablePieces.firstIndex(where: { $0.id == selected.id }) {
            availablePieces[index] = selectedPiece!
        }
    }
    
    // Seçili parçayı dikey çevir
    func flipSelectedPieceVertically() {
        guard let selected = selectedPiece else { return }
        let flippedShape = flipPieceVertically(selected)
        selectedPiece = PentominoPiece(id: selected.id, shape: Array(flippedShape))
        
        if let index = availablePieces.firstIndex(where: { $0.id == selected.id }) {
            availablePieces[index] = selectedPiece!
        }
    }
}

struct PentominoPiece: Identifiable, Transferable, Codable {
    let id: Int
    let shape: [[Bool]]
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(for: PentominoPiece.self, contentType: .pentominoPiece)
    }
}

extension UTType {
    static var pentominoPiece: UTType {
        UTType(exportedAs: "com.yourdomain.pentominopiece")
    }
} 
