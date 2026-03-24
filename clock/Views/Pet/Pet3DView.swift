//
//  Pet3DView.swift
//  下班助手
//
//  3D 宠物视图，使用 SceneKit 显示静态 3D 模型
//

import SwiftUI
import SceneKit

/// SceneKit 视图封装
struct Pet3DView: NSViewRepresentable {
    @EnvironmentObject var petManager: PetManager

    func makeNSView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.allowsCameraControl = false
        scnView.scene = Pet3DScene(petType: petManager.config.petType)

        // 完全透明背景
        scnView.scene?.background.contents = NSColor.clear

        // 关闭裁切
        scnView.wantsLayer = true
        scnView.layer?.masksToBounds = false

        return scnView
    }

    func updateNSView(_ nsView: SCNView, context: Context) {
        guard let scene = nsView.scene as? Pet3DScene else { return }

        if scene.petType != petManager.config.petType {
            nsView.scene = Pet3DScene(petType: petManager.config.petType)
            nsView.scene?.background.contents = NSColor.clear
            nsView.layer?.masksToBounds = false
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var scene: Pet3DScene?
    }
}

/// 3D 宠物场景
class Pet3DScene: SCNScene {
    let petType: PetType
    private var characterNode: SCNNode?

    init(petType: PetType) {
        self.petType = petType
        super.init()
        setupScene()
        loadCharacter()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupScene() {
        self.background.contents = NSColor.clear

        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.light?.intensity = 1000
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        rootNode.addChildNode(lightNode)

        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = .ambient
        ambientLightNode.light?.intensity = 300
        ambientLightNode.light?.color = NSColor.white
        rootNode.addChildNode(ambientLightNode)

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.usesOrthographicProjection = true
        cameraNode.camera?.orthographicScale = 2.0
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 5)
        rootNode.addChildNode(cameraNode)
    }

    private func loadCharacter() {
        let characterNode = createCharacter(for: petType)
        characterNode.position = SCNVector3(x: 0, y: 0, z: 0)
        rootNode.addChildNode(characterNode)
        self.characterNode = characterNode
    }

    private func createCharacter(for type: PetType) -> SCNNode {
        let containerNode = SCNNode()
        createCustomCharacter(in: containerNode)
        return containerNode
    }

    private func createCustomCharacter(in containerNode: SCNNode) {
        if loadModelFromBundle(into: containerNode) {
            return
        }
        createPlaceholderCharacter(in: containerNode)
    }

    private func createPlaceholderCharacter(in containerNode: SCNNode) {
        let sphere = SCNSphere(radius: 0.8)
        sphere.firstMaterial?.diffuse.contents = NSColor.systemGray
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = SCNVector3(x: 0, y: 0, z: 0)
        containerNode.addChildNode(sphereNode)
    }

    private func loadModelFromBundle(into containerNode: SCNNode) -> Bool {
        let supportedFormats = ["scn", "usdz", "dae", "obj"]
        print("📦 Bundle 资源路径: \(Bundle.main.bundlePath)")
        listBundleContents()

        for format in supportedFormats {
            print("🔍 尝试加载: customPet.\(format)")
            if let sceneURL = Bundle.main.url(forResource: "customPet", withExtension: format) {
                print("✅ 找到文件: \(sceneURL.path)")
                do {
                    let scene = try SCNScene(url: sceneURL, options: [.checkConsistency: true])
                    addSceneNodes(from: scene, to: containerNode)
                    print("🎉 成功加载模型: customPet.\(format)")
                    return true
                } catch {
                    print("❌ 加载模型失败: \(error.localizedDescription)")
                }
            } else {
                print("❌ 未找到文件: customPet.\(format)")
            }
        }
        return false
    }

    private func listBundleContents() {
        print("\n📋 应用包中的所有资源文件:")
        if let resourcePath = Bundle.main.resourcePath,
           let contents = try? FileManager.default.contentsOfDirectory(atPath: resourcePath) {
            for item in contents {
                print("   - \(item)")
            }
        } else {
            print("   ❌ 无法获取资源文件夹内容")
        }
        print("")
    }

    private func addSceneNodes(from scene: SCNScene, to containerNode: SCNNode) {
        for childNode in scene.rootNode.childNodes {
            let clonedNode = childNode.clone()
            containerNode.addChildNode(clonedNode)
        }
        adjustModelScale(containerNode)
    }

    private func adjustModelScale(_ containerNode: SCNNode) {
        let boundingBox = containerNode.boundingBox
        let size = SCNVector3(
            boundingBox.max.x - boundingBox.min.x,
            boundingBox.max.y - boundingBox.min.y,
            boundingBox.max.z - boundingBox.min.z
        )
        let maxDimension = max(size.x, max(size.y, size.z))
        let targetSize = 2.0
        var finalScaleFactor: Double = 1.0
        if maxDimension > 0 {
            finalScaleFactor = targetSize / maxDimension
            print("🔍 模型原尺寸: \(size), 缩放比例: \(finalScaleFactor)")
        }

        let transformNode = SCNNode()
        for childNode in containerNode.childNodes {
            childNode.removeFromParentNode()
            transformNode.addChildNode(childNode)
        }
        transformNode.scale = SCNVector3(finalScaleFactor, finalScaleFactor, finalScaleFactor)
        transformNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: -CGFloat.pi / 2)
        let center = SCNVector3(
            (boundingBox.max.x + boundingBox.min.x) / 2.0,
            (boundingBox.max.y + boundingBox.min.y) / 2.0,
            (boundingBox.max.z + boundingBox.min.z) / 2.0
        )
        transformNode.position = SCNVector3(-center.x, -center.y, -center.z)
        containerNode.addChildNode(transformNode)
    }
}

// MARK: - Preview
struct Pet3DView_Previews: PreviewProvider {
    static var previews: some View {
        Pet3DView()
            .environmentObject(PetManager.shared)
            .frame(width: 200, height: 200)
            .background(Color.gray.opacity(0.1))
    }
}
