import SwiftUI
import SceneKit
import AppKit

// MARK: - 3D Theme Attributes
struct ThemeAttributes3D {
    let baseImage: String
    let armImage: String
    let platterXRatio: CGFloat
    let platterYRatio: CGFloat
    let recordRadiusRatio: CGFloat
    let armPivotXRatio: CGFloat
    let armPivotYRatio: CGFloat
    let restAngle: Float
    let playAngle: Float
    let platterColor: NSColor
    let platterMetalness: CGFloat
    let bodyColor: NSColor
    let bodyMetalness: CGFloat
    let bodyRoughness: CGFloat
    let armColor: NSColor
}

extension TurntableTheme {
    var attributes3D: ThemeAttributes3D {
        switch self {
        case .technicsGold:
            return ThemeAttributes3D(
                baseImage: "turntable_bg.png", armImage: "tonearm.png",
                platterXRatio: 57.0/140.0, platterYRatio: 68.0/140.0,
                recordRadiusRatio: 82.0/280.0,
                armPivotXRatio: 114.0/140.0, armPivotYRatio: 70.5/140.0,
                restAngle: 0, playAngle: Float.pi * 38.0 / 180.0,
                platterColor: NSColor(white: 0.85, alpha: 1.0),
                platterMetalness: 0.95,
                bodyColor: NSColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0),
                bodyMetalness: 0.3, bodyRoughness: 0.6,
                armColor: NSColor(red: 0.85, green: 0.75, blue: 0.35, alpha: 1.0)
            )
        case .braunVintage:
            return ThemeAttributes3D(
                baseImage: "turntable_bg_braun.png", armImage: "tonearm_braun.png",
                platterXRatio: 88.9/140.0, platterYRatio: 69.5/140.0,
                recordRadiusRatio: 70.0/280.0,
                armPivotXRatio: 31.4/140.0, armPivotYRatio: 70.2/140.0,
                restAngle: 0, playAngle: -Float.pi * 40.0 / 180.0,
                platterColor: NSColor(white: 0.9, alpha: 1.0),
                platterMetalness: 0.3,
                bodyColor: NSColor(white: 0.92, alpha: 1.0),
                bodyMetalness: 0.05, bodyRoughness: 0.8,
                armColor: NSColor(white: 0.3, alpha: 1.0)
            )
        case .technicsAnni:
            return ThemeAttributes3D(
                baseImage: "turntable_bg_anni.png", armImage: "tonearm.png",
                platterXRatio: 57.7/140.0, platterYRatio: 67.8/140.0,
                recordRadiusRatio: 82.0/280.0,
                armPivotXRatio: 114.0/140.0, armPivotYRatio: 70.5/140.0,
                restAngle: 0, playAngle: Float.pi * 40.0 / 180.0,
                platterColor: NSColor(white: 0.1, alpha: 1.0),
                platterMetalness: 0.9,
                bodyColor: NSColor(white: 0.08, alpha: 1.0),
                bodyMetalness: 0.4, bodyRoughness: 0.5,
                armColor: NSColor(white: 0.85, alpha: 1.0)
            )
        case .regaModern:
            return ThemeAttributes3D(
                baseImage: "turntable_bg_rega.png", armImage: "tonearm_rega.png",
                platterXRatio: 53.9/140.0, platterYRatio: 69.7/140.0,
                recordRadiusRatio: 80.0/280.0,
                armPivotXRatio: 105.0/140.0, armPivotYRatio: 53.8/140.0,
                restAngle: 0, playAngle: Float.pi * 22.0 / 180.0,
                platterColor: NSColor.white,
                platterMetalness: 0.15,
                bodyColor: NSColor.white,
                bodyMetalness: 0.05, bodyRoughness: 0.9,
                armColor: NSColor(white: 0.2, alpha: 1.0)
            )
        }
    }
}

// MARK: - Builder Protocol
protocol Turntable3DBuilder {
    func buildScene(in scene: SCNScene, coordinator: SceneKitTurntableView.Coordinator)
    func updateThemeMaterials(coordinator: SceneKitTurntableView.Coordinator)
}

struct SceneKitTurntableView: NSViewRepresentable {
    let artworkImage: NSImage?
    let isPlaying: Bool
    let theme: TurntableTheme
    var onPlayPause: () -> Void = {}
    var onNext: () -> Void = {}
    var onPrevious: () -> Void = {}
    
    class Coordinator: NSObject {
        var scene: SCNScene?
        var scnView: SCNView?
        var platterNode: SCNNode?
        var vinylNode: SCNNode?
        var labelNode: SCNNode?
        var tonearmPivotNode: SCNNode?
        var baseNode: SCNNode?
        var bodyTopNode: SCNNode?
        var turntableContainer: SCNNode? // Holds all turntable geometry
        var isPlaying: Bool = false
        var currentTheme: TurntableTheme
        var builder: Turntable3DBuilder?
        
        var handleClickAction: (() -> Void)?
        var handleNextAction: (() -> Void)?
        var handlePrevAction: (() -> Void)?
        
        init(theme: TurntableTheme) {
            self.currentTheme = theme
        }
        
        @objc func handleClick(_ gesture: NSClickGestureRecognizer) {
            if gesture.state == .ended { handleClickAction?() }
        }
        
        @objc func handlePan(_ gesture: NSPanGestureRecognizer) {
            if gesture.state == .ended {
                let translation = gesture.translation(in: gesture.view)
                if translation.x < -20 { handleNextAction?() }
                else if translation.x > 20 { handlePrevAction?() }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(theme: theme)
    }
    
    func makeNSView(context: Context) -> SCNView {
        let view = SCNView()
        view.autoenablesDefaultLighting = false
        view.allowsCameraControl = false
        view.backgroundColor = .clear
        view.antialiasingMode = .multisampling4X
        view.preferredFramesPerSecond = 60
        
        let scene = SCNScene()
        scene.background.contents = NSColor.clear
        view.scene = scene
        context.coordinator.scene = scene
        context.coordinator.scnView = view
        
        setupCameraAndLights(in: scene)
        
        rebuildTurntable(for: theme, coordinator: context.coordinator, in: scene)
        
        // Gestures
        let click = NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleClick(_:)))
        view.addGestureRecognizer(click)
        let pan = NSPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        view.addGestureRecognizer(pan)
        
        context.coordinator.handleClickAction = onPlayPause
        context.coordinator.handleNextAction = onNext
        context.coordinator.handlePrevAction = onPrevious
        
        return view
    }
    
    func updateNSView(_ nsView: SCNView, context: Context) {
        let coord = context.coordinator
        
        coord.handleClickAction = onPlayPause
        coord.handleNextAction = onNext
        coord.handlePrevAction = onPrevious
        
        updateArtwork(coordinator: coord)
        
        if theme != coord.currentTheme {
            coord.currentTheme = theme
            if let scene = coord.scene {
                rebuildTurntable(for: theme, coordinator: coord, in: scene)
            }
        } else {
            // Only update materials if theme hasn't changed to avoid full rebuild
            coord.builder?.updateThemeMaterials(coordinator: coord)
        }
        
        if isPlaying != coord.isPlaying {
            coord.isPlaying = isPlaying
            animatePlayback(coordinator: coord, playing: isPlaying)
        }
    }
    
    // MARK: - Scene Construction
    
    private func setupCameraAndLights(in scene: SCNScene) {
        let cameraNode = SCNNode()
        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 9.0
        camera.zNear = 0.1
        camera.zFar = 100
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 14, 6)
        cameraNode.eulerAngles = SCNVector3(-Float.pi / 2.8, 0, 0)
        scene.rootNode.addChildNode(cameraNode)
        
        let keyLightNode = SCNNode()
        let keyLight = SCNLight()
        keyLight.type = .directional
        keyLight.intensity = 1200
        keyLight.color = NSColor(white: 1.0, alpha: 1.0)
        keyLight.castsShadow = true
        keyLight.shadowMode = .deferred
        keyLight.shadowColor = NSColor.black.withAlphaComponent(0.5)
        keyLight.shadowRadius = 6.0
        keyLight.shadowSampleCount = 8
        keyLightNode.light = keyLight
        keyLightNode.eulerAngles = SCNVector3(-Float.pi / 2.5, -Float.pi / 5, 0)
        scene.rootNode.addChildNode(keyLightNode)
        
        let fillNode = SCNNode()
        let fillLight = SCNLight()
        fillLight.type = .ambient
        fillLight.intensity = 500
        fillLight.color = NSColor(white: 0.9, alpha: 1.0)
        fillNode.light = fillLight
        scene.rootNode.addChildNode(fillNode)
        
        let rimNode = SCNNode()
        let rimLight = SCNLight()
        rimLight.type = .directional
        rimLight.intensity = 600
        rimLight.color = NSColor(calibratedHue: 0.6, saturation: 0.1, brightness: 1.0, alpha: 1.0)
        rimNode.light = rimLight
        rimNode.eulerAngles = SCNVector3(-Float.pi / 4, Float.pi / 3, 0)
        scene.rootNode.addChildNode(rimNode)
        
        let floorGeo = SCNFloor()
        floorGeo.reflectivity = 0.15
        floorGeo.reflectionFalloffEnd = 3.0
        let floorMat = SCNMaterial()
        floorMat.lightingModel = .physicallyBased
        floorMat.diffuse.contents = NSColor.clear
        floorMat.transparency = 0.0
        floorGeo.materials = [floorMat]
        let floorNode = SCNNode(geometry: floorGeo)
        floorNode.position = SCNVector3(0, -1.35, 0)
        scene.rootNode.addChildNode(floorNode)
    }
    
    private func rebuildTurntable(for theme: TurntableTheme, coordinator: Coordinator, in scene: SCNScene) {
        coordinator.turntableContainer?.removeFromParentNode()
        
        let container = SCNNode()
        scene.rootNode.addChildNode(container)
        coordinator.turntableContainer = container
        
        let builder: Turntable3DBuilder
        if theme == .braunVintage {
            builder = BraunTurntableBuilder()
        } else {
            builder = GenericTurntableBuilder()
        }
        
        builder.buildScene(in: scene, coordinator: coordinator)
        coordinator.builder = builder
        
        // Ensure artwork is applied to the newly built label
        updateArtwork(coordinator: coordinator)
        
        // Ensure playback animation state is correct
        animatePlayback(coordinator: coordinator, playing: coordinator.isPlaying)
    }
    
    private func updateArtwork(coordinator: Coordinator) {
        if let labelMats = coordinator.labelNode?.geometry?.materials,
           let topMat = labelMats.first {
            if let img = artworkImage {
                topMat.diffuse.contents = img
            } else {
                topMat.diffuse.contents = NSColor.darkGray
            }
        }
    }
    
    private func animatePlayback(coordinator: Coordinator, playing: Bool) {
        let a = coordinator.currentTheme.attributes3D
        
        if playing {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.4
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            coordinator.tonearmPivotNode?.eulerAngles.y = CGFloat(-a.playAngle)
            SCNTransaction.commit()
            
            let spin = SCNAction.rotateBy(x: 0, y: -CGFloat.pi * 2, z: 0, duration: 1.8)
            let rep = SCNAction.repeatForever(spin)
            coordinator.platterNode?.runAction(rep, forKey: "spin")
        } else {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.4
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            coordinator.tonearmPivotNode?.eulerAngles.y = CGFloat(-a.restAngle)
            SCNTransaction.commit()
            
            coordinator.platterNode?.removeAction(forKey: "spin")
        }
    }
}

// MARK: - Generic Turntable Builder
class GenericTurntableBuilder: Turntable3DBuilder {
    func buildScene(in scene: SCNScene, coordinator: SceneKitTurntableView.Coordinator) {
        guard let container = coordinator.turntableContainer else { return }
        let a = coordinator.currentTheme.attributes3D
        
        let baseW: CGFloat = 14.0
        let baseD: CGFloat = 14.0
        let baseH: CGFloat = 1.2
        let baseGeo = SCNBox(width: baseW, height: baseH, length: baseD, chamferRadius: 0.4)
        let baseMat = SCNMaterial()
        baseMat.lightingModel = .physicallyBased
        baseMat.diffuse.contents = a.bodyColor
        baseMat.metalness.contents = a.bodyMetalness
        baseMat.roughness.contents = a.bodyRoughness
        baseGeo.materials = [baseMat]
        let baseNode = SCNNode(geometry: baseGeo)
        baseNode.position = SCNVector3(0, -baseH / 2.0, 0)
        container.addChildNode(baseNode)
        coordinator.baseNode = baseNode
        
        let topGeo = SCNBox(width: baseW - 0.2, height: 0.08, length: baseD - 0.2, chamferRadius: 0.3)
        let topMat = SCNMaterial()
        topMat.lightingModel = .physicallyBased
        if let path = Bundle.main.path(forResource: a.baseImage, ofType: nil),
           let img = NSImage(contentsOfFile: path) {
            topMat.diffuse.contents = img
        } else {
            topMat.diffuse.contents = a.bodyColor
        }
        topMat.metalness.contents = 0.15
        topMat.roughness.contents = 0.5
        topGeo.materials = [topMat]
        let topNode = SCNNode(geometry: topGeo)
        topNode.position = SCNVector3(0, 0.04, 0)
        container.addChildNode(topNode)
        coordinator.bodyTopNode = topNode
        
        let platterX = Float(a.platterXRatio * baseW - baseW / 2.0)
        let platterZ = Float(a.platterYRatio * baseD - baseD / 2.0)
        let platterRadius = CGFloat(a.recordRadiusRatio * baseW) + 0.4
        
        let platterGeo = SCNCylinder(radius: platterRadius, height: 0.25)
        platterGeo.radialSegmentCount = 72
        let platterMat = SCNMaterial()
        platterMat.lightingModel = .physicallyBased
        platterMat.diffuse.contents = a.platterColor
        platterMat.metalness.contents = a.platterMetalness
        platterMat.roughness.contents = 0.12
        let platterSideMat = SCNMaterial()
        platterSideMat.lightingModel = .physicallyBased
        platterSideMat.diffuse.contents = NSColor(white: 0.4, alpha: 1.0)
        platterSideMat.metalness.contents = 0.8
        platterSideMat.roughness.contents = 0.2
        platterGeo.materials = [platterMat, platterSideMat, platterMat]
        
        let platterNode = SCNNode(geometry: platterGeo)
        platterNode.position = SCNVector3(platterX, 0.2, platterZ)
        container.addChildNode(platterNode)
        coordinator.platterNode = platterNode
        
        let vinylRadius = platterRadius - 0.15
        let vinylGeo = SCNCylinder(radius: vinylRadius, height: 0.12)
        vinylGeo.radialSegmentCount = 72
        let vinylTopMat = SCNMaterial()
        vinylTopMat.lightingModel = .physicallyBased
        vinylTopMat.diffuse.contents = NSColor(white: 0.03, alpha: 1.0)
        vinylTopMat.metalness.contents = 0.25
        vinylTopMat.roughness.contents = 0.35
        vinylTopMat.specular.contents = NSColor(white: 0.6, alpha: 1.0)
        let vinylSideMat = SCNMaterial()
        vinylSideMat.lightingModel = .physicallyBased
        vinylSideMat.diffuse.contents = NSColor(white: 0.02, alpha: 1.0)
        vinylSideMat.metalness.contents = 0.1
        vinylSideMat.roughness.contents = 0.5
        vinylGeo.materials = [vinylTopMat, vinylSideMat, vinylTopMat]
        let vinylNode = SCNNode(geometry: vinylGeo)
        vinylNode.position = SCNVector3(0, 0.18, 0)
        platterNode.addChildNode(vinylNode)
        coordinator.vinylNode = vinylNode
        
        for i in stride(from: 1.5, to: Double(vinylRadius) - 0.5, by: 0.5) {
            let grooveGeo = SCNTorus(ringRadius: CGFloat(i), pipeRadius: 0.015)
            let grooveMat = SCNMaterial()
            grooveMat.lightingModel = .physicallyBased
            grooveMat.diffuse.contents = NSColor(white: 0.08, alpha: 1.0)
            grooveMat.metalness.contents = 0.4
            grooveMat.roughness.contents = 0.2
            grooveMat.specular.contents = NSColor(white: 0.9, alpha: 1.0)
            grooveGeo.materials = [grooveMat]
            let grooveNode = SCNNode(geometry: grooveGeo)
            grooveNode.position = SCNVector3(0, 0.065, 0)
            vinylNode.addChildNode(grooveNode)
        }
        
        let labelRadius: CGFloat = vinylRadius * 0.35
        let labelGeo = SCNCylinder(radius: labelRadius, height: 0.14)
        labelGeo.radialSegmentCount = 48
        let labelMat = SCNMaterial()
        labelMat.lightingModel = .physicallyBased
        labelMat.diffuse.contents = NSColor.darkGray
        labelMat.metalness.contents = 0.0
        labelMat.roughness.contents = 0.7
        let labelSideMat = SCNMaterial()
        labelSideMat.lightingModel = .physicallyBased
        labelSideMat.diffuse.contents = NSColor(white: 0.15, alpha: 1.0)
        labelGeo.materials = [labelMat, labelSideMat, labelMat]
        let labelNode = SCNNode(geometry: labelGeo)
        labelNode.position = SCNVector3(0, 0.01, 0)
        vinylNode.addChildNode(labelNode)
        coordinator.labelNode = labelNode
        
        let spindleGeo = SCNCylinder(radius: 0.12, height: 0.6)
        let spindleMat = SCNMaterial()
        spindleMat.lightingModel = .physicallyBased
        spindleMat.diffuse.contents = NSColor(white: 0.8, alpha: 1.0)
        spindleMat.metalness.contents = 1.0
        spindleMat.roughness.contents = 0.05
        spindleGeo.materials = [spindleMat]
        let spindleNode = SCNNode(geometry: spindleGeo)
        spindleNode.position = SCNVector3(0, 0.3, 0)
        platterNode.addChildNode(spindleNode)
        
        let armPivotX = Float(a.armPivotXRatio * baseW - baseW / 2.0)
        let armPivotZ = Float(a.armPivotYRatio * baseD - baseD / 2.0)
        let tonearmPivot = SCNNode()
        tonearmPivot.position = SCNVector3(armPivotX, 0.5, armPivotZ)
        container.addChildNode(tonearmPivot)
        coordinator.tonearmPivotNode = tonearmPivot
        
        let pivotBaseGeo = SCNCylinder(radius: 0.6, height: 0.7)
        let pivotBaseMat = SCNMaterial()
        pivotBaseMat.lightingModel = .physicallyBased
        pivotBaseMat.diffuse.contents = NSColor(white: 0.15, alpha: 1.0)
        pivotBaseMat.metalness.contents = 0.9
        pivotBaseMat.roughness.contents = 0.15
        pivotBaseGeo.materials = [pivotBaseMat]
        let pivotBaseNode = SCNNode(geometry: pivotBaseGeo)
        tonearmPivot.addChildNode(pivotBaseNode)
        
        let armLength: CGFloat = CGFloat(abs(armPivotX - platterX)) + platterRadius * 0.6
        let armGeo = SCNCylinder(radius: 0.08, height: armLength)
        let armMat = SCNMaterial()
        armMat.lightingModel = .physicallyBased
        armMat.diffuse.contents = a.armColor
        armMat.metalness.contents = 1.0
        armMat.roughness.contents = 0.08
        armGeo.materials = [armMat]
        let armTubeNode = SCNNode(geometry: armGeo)
        armTubeNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
        armTubeNode.position = SCNVector3(-Float(armLength / 2.0), 0.45, 0)
        tonearmPivot.addChildNode(armTubeNode)
        
        let cwGeo = SCNCylinder(radius: 0.35, height: 0.5)
        let cwMat = SCNMaterial()
        cwMat.lightingModel = .physicallyBased
        cwMat.diffuse.contents = NSColor(white: 0.2, alpha: 1.0)
        cwMat.metalness.contents = 0.85
        cwGeo.materials = [cwMat]
        let cwNode = SCNNode(geometry: cwGeo)
        cwNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
        cwNode.position = SCNVector3(0.8, 0.45, 0)
        tonearmPivot.addChildNode(cwNode)
        
        let headGeo = SCNBox(width: 0.8, height: 0.15, length: 0.45, chamferRadius: 0.03)
        let headMat = SCNMaterial()
        headMat.lightingModel = .physicallyBased
        headMat.diffuse.contents = NSColor(white: 0.08, alpha: 1.0)
        headMat.metalness.contents = 0.6
        headGeo.materials = [headMat]
        let headNode = SCNNode(geometry: headGeo)
        headNode.position = SCNVector3(-Float(armLength) - 0.4, 0.45, 0)
        tonearmPivot.addChildNode(headNode)
        
        let stylusGeo = SCNCone(topRadius: 0.01, bottomRadius: 0.03, height: 0.3)
        let stylusMat = SCNMaterial()
        stylusMat.lightingModel = .physicallyBased
        stylusMat.diffuse.contents = NSColor(white: 0.9, alpha: 1.0)
        stylusMat.metalness.contents = 1.0
        stylusGeo.materials = [stylusMat]
        let stylusNode = SCNNode(geometry: stylusGeo)
        stylusNode.position = SCNVector3(-Float(armLength) - 0.7, 0.3, 0)
        tonearmPivot.addChildNode(stylusNode)
    }
    
    func updateThemeMaterials(coordinator: SceneKitTurntableView.Coordinator) {
        let a = coordinator.currentTheme.attributes3D
        if let baseMat = coordinator.baseNode?.geometry?.materials.first {
            baseMat.diffuse.contents = a.bodyColor
        }
        if let topMat = coordinator.bodyTopNode?.geometry?.materials.first {
            if let path = Bundle.main.path(forResource: a.baseImage, ofType: nil),
               let img = NSImage(contentsOfFile: path) {
                topMat.diffuse.contents = img
            }
        }
        if let platterMats = coordinator.platterNode?.geometry?.materials,
           let mat = platterMats.first {
            mat.diffuse.contents = a.platterColor
        }
    }
}

// MARK: - Braun SK4 Turntable Builder
class BraunTurntableBuilder: Turntable3DBuilder {
    func buildScene(in scene: SCNScene, coordinator: SceneKitTurntableView.Coordinator) {
        guard let container = coordinator.turntableContainer else { return }
        
        // 1. 전체 크기 1.3배 확대
        container.scale = SCNVector3(1.3, 1.3, 1.3)
        
        let baseW: CGFloat = 16.0
        let baseD: CGFloat = 14.0
        let baseH: CGFloat = 1.2
        
        // 1. Main Grey Body
        let bodyGeo = SCNBox(width: baseW, height: baseH, length: baseD, chamferRadius: 0.1)
        let bodyMat = SCNMaterial()
        bodyMat.lightingModel = .physicallyBased
        bodyMat.diffuse.contents = NSColor(white: 0.92, alpha: 1.0)
        bodyMat.metalness.contents = 0.1
        bodyMat.roughness.contents = 0.8
        bodyGeo.materials = [bodyMat]
        let bodyNode = SCNNode(geometry: bodyGeo)
        bodyNode.position = SCNVector3(0, -baseH / 2.0, 0)
        container.addChildNode(bodyNode)
        coordinator.baseNode = bodyNode
        
        // 2. Wood Side Panels
        let woodMat = SCNMaterial()
        woodMat.lightingModel = .physicallyBased
        woodMat.diffuse.contents = NSColor(red: 0.75, green: 0.55, blue: 0.35, alpha: 1.0)
        woodMat.metalness.contents = 0.05
        woodMat.roughness.contents = 0.9
        
        let sideW: CGFloat = 0.6
        let sideH: CGFloat = baseH + 0.2
        let sideD: CGFloat = baseD + 0.2
        let panelGeo = SCNBox(width: sideW, height: sideH, length: sideD, chamferRadius: 0.1)
        panelGeo.materials = [woodMat]
        
        let leftPanel = SCNNode(geometry: panelGeo)
        leftPanel.position = SCNVector3(-Float(baseW / 2.0) - Float(sideW / 2.0), -Float(baseH / 2.0) + 0.1, 0)
        container.addChildNode(leftPanel)
        
        let rightPanel = SCNNode(geometry: panelGeo)
        rightPanel.position = SCNVector3(Float(baseW / 2.0) + Float(sideW / 2.0), -Float(baseH / 2.0) + 0.1, 0)
        container.addChildNode(rightPanel)
        
        // 3. Front Control Panel (음각 패널 박스)
        let frontPanelGeo = SCNBox(width: baseW - 1.0, height: 0.05, length: 2.0, chamferRadius: 0.0)
        let frontPanelMat = SCNMaterial()
        frontPanelMat.lightingModel = .physicallyBased
        frontPanelMat.diffuse.contents = NSColor(white: 0.88, alpha: 1.0)
        frontPanelMat.metalness.contents = 0.1
        frontPanelMat.roughness.contents = 0.8
        frontPanelGeo.materials = [frontPanelMat]
        let frontPanelNode = SCNNode(geometry: frontPanelGeo)
        frontPanelNode.position = SCNVector3(0, 0.02, Float(baseD / 2.0) - 1.5)
        container.addChildNode(frontPanelNode)
        
        // 4. White Platter (좌측 중심)
        let platterX: Float = -2.0
        let platterZ: Float = -1.0
        let platterRadius: CGFloat = 5.6
        
        let platterGeo = SCNCylinder(radius: platterRadius, height: 0.2)
        platterGeo.radialSegmentCount = 72
        let platterMat = SCNMaterial()
        platterMat.lightingModel = .physicallyBased
        platterMat.diffuse.contents = NSColor(white: 0.95, alpha: 1.0)
        platterMat.metalness.contents = 0.1
        platterMat.roughness.contents = 0.3
        platterGeo.materials = [platterMat]
        let platterNode = SCNNode(geometry: platterGeo)
        platterNode.position = SCNVector3(platterX, 0.1, platterZ)
        container.addChildNode(platterNode)
        coordinator.platterNode = platterNode
        
        // Vinyl Record
        let vinylRadius = platterRadius - 0.2
        let vinylGeo = SCNCylinder(radius: vinylRadius, height: 0.05)
        vinylGeo.radialSegmentCount = 72
        let vinylMat = SCNMaterial()
        vinylMat.lightingModel = .physicallyBased
        vinylMat.diffuse.contents = NSColor(white: 0.05, alpha: 1.0)
        vinylMat.metalness.contents = 0.3
        vinylMat.roughness.contents = 0.4
        vinylMat.specular.contents = NSColor(white: 0.6, alpha: 1.0)
        vinylGeo.materials = [vinylMat]
        let vinylNode = SCNNode(geometry: vinylGeo)
        vinylNode.position = SCNVector3(0, 0.125, 0)
        platterNode.addChildNode(vinylNode)
        coordinator.vinylNode = vinylNode
        
        // Record Label
        let labelRadius: CGFloat = vinylRadius * 0.35
        let labelGeo = SCNCylinder(radius: labelRadius, height: 0.06)
        labelGeo.radialSegmentCount = 48
        let labelMat = SCNMaterial()
        labelMat.lightingModel = .physicallyBased
        labelMat.diffuse.contents = NSColor.darkGray
        labelGeo.materials = [labelMat]
        let labelNode = SCNNode(geometry: labelGeo)
        labelNode.position = SCNVector3(0, 0.03, 0)
        vinylNode.addChildNode(labelNode)
        coordinator.labelNode = labelNode
        
        // Spindle
        let spindleGeo = SCNCylinder(radius: 0.12, height: 0.5)
        let spindleMat = SCNMaterial()
        spindleMat.lightingModel = .physicallyBased
        spindleMat.diffuse.contents = NSColor(white: 0.8, alpha: 1.0)
        spindleMat.metalness.contents = 1.0
        spindleMat.roughness.contents = 0.1
        spindleGeo.materials = [spindleMat]
        let spindleNode = SCNNode(geometry: spindleGeo)
        spindleNode.position = SCNVector3(0, 0.25, 0)
        platterNode.addChildNode(spindleNode)
        
        // 5. Tonearm (우측 상단)
        let armPivotX: Float = 5.5
        let armPivotZ: Float = -4.5
        
        let tonearmPivot = SCNNode()
        tonearmPivot.position = SCNVector3(armPivotX, 0.3, armPivotZ)
        container.addChildNode(tonearmPivot)
        coordinator.tonearmPivotNode = tonearmPivot
        
        // Pivot Base
        let pivotBaseGeo = SCNCylinder(radius: 0.8, height: 0.6)
        let pivotBaseMat = SCNMaterial()
        pivotBaseMat.lightingModel = .physicallyBased
        pivotBaseMat.diffuse.contents = NSColor(white: 0.85, alpha: 1.0)
        pivotBaseMat.metalness.contents = 0.6
        pivotBaseMat.roughness.contents = 0.3
        pivotBaseGeo.materials = [pivotBaseMat]
        let pivotBaseNode = SCNNode(geometry: pivotBaseGeo)
        tonearmPivot.addChildNode(pivotBaseNode)
        
        // Arm Tube (앞쪽 +Z 방향으로 뻗음)
        let armLength: CGFloat = 10.0
        let armGeo = SCNCylinder(radius: 0.1, height: armLength)
        let armMat = SCNMaterial()
        armMat.lightingModel = .physicallyBased
        armMat.diffuse.contents = NSColor(white: 0.9, alpha: 1.0)
        armMat.metalness.contents = 0.4
        armMat.roughness.contents = 0.3
        armGeo.materials = [armMat]
        let armTubeNode = SCNNode(geometry: armGeo)
        armTubeNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0) // 실린더를 눕혀서 +Z 방향으로 향하게 함
        armTubeNode.position = SCNVector3(0, 0.5, Float(armLength / 2.0) - 1.5) // 피벗에서 앞쪽으로 중심 이동
        tonearmPivot.addChildNode(armTubeNode)
        
        // Counterweight (뒤쪽 -Z 방향)
        let cwGeo = SCNCylinder(radius: 0.4, height: 0.8)
        let cwMat = SCNMaterial()
        cwMat.lightingModel = .physicallyBased
        cwMat.diffuse.contents = NSColor(white: 0.9, alpha: 1.0)
        cwMat.metalness.contents = 0.8
        cwGeo.materials = [cwMat]
        let cwNode = SCNNode(geometry: cwGeo)
        cwNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
        cwNode.position = SCNVector3(0, 0.5, -1.2)
        tonearmPivot.addChildNode(cwNode)
        
        // Headshell & Stylus Box (+Z 끝단)
        let headGeo = SCNBox(width: 0.5, height: 0.2, length: 1.0, chamferRadius: 0.05)
        let headMat = SCNMaterial()
        headMat.lightingModel = .physicallyBased
        headMat.diffuse.contents = NSColor(white: 0.85, alpha: 1.0)
        headMat.metalness.contents = 0.4
        headGeo.materials = [headMat]
        let headNode = SCNNode(geometry: headGeo)
        headNode.position = SCNVector3(0, 0.5, Float(armLength) - 1.5)
        tonearmPivot.addChildNode(headNode)
        
        // Stylus needle
        let stylusGeo = SCNCone(topRadius: 0.02, bottomRadius: 0.05, height: 0.4)
        let stylusMat = SCNMaterial()
        stylusMat.lightingModel = .physicallyBased
        stylusMat.diffuse.contents = NSColor(white: 0.5, alpha: 1.0)
        stylusMat.metalness.contents = 0.9
        stylusGeo.materials = [stylusMat]
        let stylusNode = SCNNode(geometry: stylusGeo)
        stylusNode.position = SCNVector3(0, -0.2, 0)
        headNode.addChildNode(stylusNode)
        
        // 6. Buttons / Switches on Front Panel
        // Power/Volume Knob (Left)
        let knobGeo = SCNCylinder(radius: 0.4, height: 0.3)
        let knobMat = SCNMaterial()
        knobMat.lightingModel = .physicallyBased
        knobMat.diffuse.contents = NSColor(white: 0.8, alpha: 1.0)
        knobGeo.materials = [knobMat]
        let knobNode = SCNNode(geometry: knobGeo)
        knobNode.position = SCNVector3(-Float(baseW / 2.0) + 2.0, 0.2, Float(baseD / 2.0) - 1.5)
        container.addChildNode(knobNode)
        
        // Slide Switch (Center)
        let switchGeo = SCNBox(width: 1.2, height: 0.15, length: 0.4, chamferRadius: 0.02)
        let switchMat = SCNMaterial()
        switchMat.lightingModel = .physicallyBased
        switchMat.diffuse.contents = NSColor(white: 0.7, alpha: 1.0)
        switchGeo.materials = [switchMat]
        let switchNode = SCNNode(geometry: switchGeo)
        switchNode.position = SCNVector3(0, 0.1, Float(baseD / 2.0) - 1.5)
        container.addChildNode(switchNode)
    }
    
    func updateThemeMaterials(coordinator: SceneKitTurntableView.Coordinator) {
        // Not needed for Braun as it ignores external theme attributes and uses its own materials
    }
}
