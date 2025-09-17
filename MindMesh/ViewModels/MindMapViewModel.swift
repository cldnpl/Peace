import SwiftUI
import Combine

@MainActor
final class MindMapStore: ObservableObject {
    static let shared = MindMapStore()

    @Published var maps: [MindMap] = MindMap.sampleMaps

    private init() {}

    @discardableResult
    func createMap(title: String = "Nuova mappa") -> UUID {
        let rootID = UUID()
        let initialTitle = Self.normalizedMapTitle(from: title)
        let newMap = MindMap(
            title: initialTitle,
            nodes: [
                MapNode(
                    id: rootID,
                    label: initialTitle,
                    color: .mmAccent,
                    position: CGPoint(x: 0.5, y: 0.5),
                    size: 72,
                    isRoot: true
                )
            ]
        )
        withAnimation(.snappy) {
            maps.insert(newMap, at: 0)
        }
        return newMap.id
    }

    func deleteMap(id: UUID) {
        withAnimation(.snappy) {
            maps.removeAll { $0.id == id }
        }
    }

    func deleteMaps(at offsets: IndexSet) {
        withAnimation(.snappy) {
            maps.remove(atOffsets: offsets)
        }
    }

    static func normalizedMapTitle(from rawTitle: String) -> String {
        let trimmed = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Mappa" : trimmed
    }
}

@MainActor
final class MindMapViewModel: ObservableObject {
    private var mapBinding: Binding<MindMap>

    @Published var selectedNodeID: UUID?
    @Published var canvasSize: CGSize = .zero
    @Published var toolMode: ToolMode = .select

    var map: MindMap { mapBinding.wrappedValue }
    var rootNode: MapNode? { map.nodes.first(where: \.isRoot) }

    enum ToolMode: String, CaseIterable {
        case select = "hand.tap"
        case edit = "pencil"

        var label: String {
            switch self {
            case .select: return "Muovi"
            case .edit: return "Modifica"
            }
        }
    }

    init(map: Binding<MindMap>) {
        self.mapBinding = map
    }

    init(map: MindMap = .sample) {
        self.mapBinding = .constant(map)
    }

    func position(for node: MapNode) -> CGPoint {
        CGPoint(
            x: node.position.x * canvasSize.width,
            y: node.position.y * canvasSize.height
        )
    }

    func addNode(label: String, color: Color = .mmAccent2) {
        var updatedMap = map
        let newNode = MapNode(
            label: label,
            color: color,
            position: CGPoint(x: Double.random(in: 0.2...0.8), y: Double.random(in: 0.2...0.8)),
            size: 48
        )
        updatedMap.nodes.append(newNode)
        if let rootID = updatedMap.nodes.first(where: { $0.isRoot })?.id {
            updatedMap.edges.append(MapEdge(from: rootID, to: newNode.id))
        }
        withAnimation(.snappy) {
            objectWillChange.send()
            mapBinding.wrappedValue = updatedMap
        }
    }

    func renameNode(id: UUID, label: String) {
        guard let index = map.nodes.firstIndex(where: { $0.id == id }) else { return }
        var updatedMap = map
        let normalizedLabel = MindMapStore.normalizedMapTitle(from: label)
        updatedMap.nodes[index].label = normalizedLabel
        if updatedMap.nodes[index].isRoot {
            updatedMap.title = normalizedLabel
        }
        withAnimation(.easeInOut(duration: 0.2)) {
            objectWillChange.send()
            mapBinding.wrappedValue = updatedMap
        }
    }

    func deleteNode(id: UUID) {
        guard let node = map.nodes.first(where: { $0.id == id }), !node.isRoot else { return }
        var updatedMap = map
        updatedMap.nodes.removeAll { $0.id == id }
        updatedMap.edges.removeAll { $0.fromID == id || $0.toID == id }
        if selectedNodeID == id {
            selectedNodeID = nil
        }
        withAnimation(.snappy) {
            objectWillChange.send()
            mapBinding.wrappedValue = updatedMap
        }
    }

    func renameMap(title: String) {
        var updatedMap = map
        updatedMap.title = title
        if let rootIndex = updatedMap.nodes.firstIndex(where: \.isRoot) {
            updatedMap.nodes[rootIndex].label = MindMapStore.normalizedMapTitle(from: title)
        }
        withAnimation(.easeInOut(duration: 0.2)) {
            objectWillChange.send()
            mapBinding.wrappedValue = updatedMap
        }
    }

    func node(with id: UUID?) -> MapNode? {
        guard let id else { return nil }
        return map.nodes.first { $0.id == id }
    }

    func centeredCanvasOffset(for size: CGSize) -> CGSize {
        guard let rootNode else { return .zero }
        return CGSize(
            width: (size.width * 0.5) - (rootNode.position.x * size.width),
            height: (size.height * 0.5) - (rootNode.position.y * size.height)
        )
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
