//
//  ARGameView.swift
//  FWG
//
//  Created by Ferid Suleymanzade on 03.12.24.
//

import SwiftUI
import RealityKit
import ARKit

struct ARGameView: View {
    @StateObject private var viewModel = GameViewModel()
    
    var body: some View {
        ZStack {
            ARViewContainer(viewModel: viewModel)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                PieceSelectorView(viewModel: viewModel)
                    .background(Color.black.opacity(0.5))
                    .padding()
            }
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    let viewModel: GameViewModel
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.vertical]
        arView.session.run(config)
        
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .verticalPlane
        arView.addSubview(coachingOverlay)
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        return arView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    class Coordinator: NSObject {
        let parent: ARViewContainer
        var gridAnchor: AnchorEntity?
        var gridCells: [[ModelEntity]] = []
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
            super.init()
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = gesture.view as? ARView else { return }
            
            let location = gesture.location(in: arView)
            
            if let result = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .vertical).first {
                // Remove existing grid if any
                gridAnchor?.removeFromParent()
                
                // Create new anchor with adjusted position
                var transform = result.worldTransform
                transform.columns.3.y += 0.1 // Slightly raise the grid
                gridAnchor = AnchorEntity(world: transform)
                
                // Create grid
                createGrid(in: arView)
            }
        }
        
        func createGrid(in arView: ARView) {
            guard let gridAnchor = gridAnchor else { return }

            let cellSize: Float = 0.05 // 5cm per cell
            let gridWidth: Float = cellSize * 10 // 10 columns
            let gridHeight: Float = cellSize * 6 // 6 rows

            // Izgaranın arka planı
            let backgroundMesh = MeshResource.generatePlane(width: gridWidth, height: gridHeight)
            let backgroundMaterial = SimpleMaterial(color: .white.withAlphaComponent(0.3), isMetallic: false)
            let backgroundEntity = ModelEntity(mesh: backgroundMesh, materials: [backgroundMaterial])

            // Arka planı dikey formatta döndür
            backgroundEntity.transform.rotation = simd_quatf(angle: 0, axis: [1, 0, 0])
            backgroundEntity.position = [0, 0, 0] // Izgarayı merkezde tut

            gridAnchor.addChild(backgroundEntity)

            // Izgara çizgilerini oluştur
            let lineThickness: Float = 0.001

            // Dikey çizgiler
            for col in 0...10 {
                let x = (Float(col) * cellSize) - (gridWidth / 2)
                let lineMesh = MeshResource.generateBox(size: [lineThickness, lineThickness, gridHeight])
                let lineEntity = ModelEntity(mesh: lineMesh, materials: [SimpleMaterial(color: .black, isMetallic: false)])
                lineEntity.position = [x, 0, 0]
                gridAnchor.addChild(lineEntity)
            }

            // Yatay çizgiler
            for row in 0...6 {
                let y = (Float(row) * cellSize) - (gridHeight / 2)
                let lineMesh = MeshResource.generateBox(size: [gridWidth, lineThickness, lineThickness])
                let lineEntity = ModelEntity(mesh: lineMesh, materials: [SimpleMaterial(color: .black, isMetallic: false)])
                lineEntity.position = [0, 0, y]
                gridAnchor.addChild(lineEntity)
            }

            // Izgara hücrelerini oluştur
            gridCells = Array(repeating: Array(repeating: ModelEntity(), count: 10), count: 6)

            for row in 0..<6 {
                for col in 0..<10 {
                    let cellEntity = createGridCell(size: cellSize)
                    let x = Float(col) * cellSize - (gridWidth / 2) + (cellSize / 2)
                    let y = Float(row) * cellSize - (gridHeight / 2) + (cellSize / 2)
                    cellEntity.position = [x, 0, y] // Hücreleri dikey formatta hizala
                    gridAnchor.addChild(cellEntity)
                    gridCells[row][col] = cellEntity
                }
            }

            arView.scene.addAnchor(gridAnchor)
        }

        
        func createGridCell(size: Float) -> ModelEntity {
            let mesh = MeshResource.generatePlane(width: size * 0.95, height: size * 0.95)
            let material = SimpleMaterial(color: .gray.withAlphaComponent(0.2), isMetallic: false)
            let cellEntity = ModelEntity(mesh: mesh, materials: [material])
            return cellEntity
        }
    }
}

#Preview {
    ARGameView()
}
