import SwiftUI

struct MindMapListView: View {
    @ObservedObject private var store = MindMapStore.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()
                
                List {
                    ForEach(store.maps) { map in
                        if let index = store.maps.firstIndex(where: { $0.id == map.id }) {
                            NavigationLink {
                                MindMapView(vm: MindMapViewModel(map: $store.maps[index]))
                            } label: {
                                MapRow(map: map)
                            }
                        }
                    }
                    .onDelete(perform: store.deleteMaps)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
            .navigationTitle("Mappe")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.createMap()
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(.mmAccent)
                    }
                    .accessibilityLabel("Nuova mappa")
                }
            }
        }
    }
    
    
    private struct MapRow: View {
        let map: MindMap
        
        private var displayTitle: String {
            MindMapStore.normalizedMapTitle(from: map.title)
        }
        
        var body: some View {
            HStack(spacing: MMSpacing.md) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.mmSurface)
                    .frame(width: 42, height: 42)
                    .overlay(
                        Image(systemName: map.symbolName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.mmAccent)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(displayTitle)
                        .font(MMFont.title(16, weight: .semibold))
                        .foregroundStyle(.mmTextPrimary)
                    
                    Text("\(map.nodeCount) nodi")
                        .font(MMFont.caption(12, weight: .medium))
                        .foregroundStyle(.mmTextMuted)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    struct MindMapView: View {
        @StateObject var vm: MindMapViewModel
        @ObservedObject private var store = MindMapStore.shared
        @Environment(\.dismiss) private var dismiss
        
        @State private var showAddNode = false
        @State private var showEditNode = false
        @State private var showDeleteNodeConfirmation = false
        @State private var showDeleteMapConfirmation = false
        
        @State private var draftNodeLabel = ""
        @State private var toolFeedback = 0
        @State private var canvasOffset: CGSize = .zero
        @State private var lastCanvasOffset: CGSize = .zero
        
        private var selectedNode: MapNode? {
            vm.node(with: vm.selectedNodeID)
        }
        
        private var titleBinding: Binding<String> {
            Binding(
                get: { vm.map.title },
                set: { vm.renameMap(title: $0) }
            )
        }
        
        private var navigationTitleText: String {
            MindMapStore.normalizedMapTitle(from: vm.map.title)
        }
        
        var body: some View {
            ZStack {
                mapBackground
                
                VStack(spacing: 0) {
                    headerEditor
                    
                    GeometryReader { geo in
                        ZStack {
                            Rectangle()
                                .fill(Color.clear)
                                .contentShape(Rectangle())
                                .simultaneousGesture(canvasPanGesture)
                            
                            ZStack {
                                Canvas { ctx, size in
                                    for edge in vm.map.edges {
                                        guard
                                            let fromNode = vm.map.nodes.first(where: { $0.id == edge.fromID }),
                                            let toNode = vm.map.nodes.first(where: { $0.id == edge.toID })
                                        else {
                                            continue
                                        }
                                        
                                        let from = CGPoint(x: fromNode.position.x * size.width, y: fromNode.position.y * size.height)
                                        let to = CGPoint(x: toNode.position.x * size.width, y: toNode.position.y * size.height)
                                        
                                        var path = Path()
                                        path.move(to: from)
                                        let cp1 = CGPoint(x: from.x + (to.x - from.x) * 0.5, y: from.y)
                                        let cp2 = CGPoint(x: from.x + (to.x - from.x) * 0.5, y: to.y)
                                        path.addCurve(to: to, control1: cp1, control2: cp2)
                                        
                                        ctx.stroke(
                                            path,
                                            with: .color(fromNode.color.opacity(0.28)),
                                            style: StrokeStyle(lineWidth: 1.5, dash: [4, 5])
                                        )
                                    }
                                }
                                .allowsHitTesting(false)
                                
                                ForEach(vm.map.nodes) { node in
                                    NodeView(node: node, isSelected: vm.selectedNodeID == node.id)
                                        .position(
                                            x: node.position.x * geo.size.width,
                                            y: node.position.y * geo.size.height
                                        )
                                        .contentShape(Circle())
                                        .simultaneousGesture(canvasPanGesture)
                                        .onTapGesture {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                                                vm.selectedNodeID = vm.selectedNodeID == node.id ? nil : node.id
                                            }
                                        }
                                }
                            }
                            .offset(canvasOffset)
                        }
                        .coordinateSpace(name: "mindMapCanvas")
                        .clipped()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onAppear {
                            vm.canvasSize = geo.size
                            let centeredOffset = vm.centeredCanvasOffset(for: geo.size)
                            canvasOffset = centeredOffset
                            lastCanvasOffset = centeredOffset
                        }
                        .onChange(of: geo.size) { _, newSize in
                            vm.canvasSize = newSize
                            let centeredOffset = vm.centeredCanvasOffset(for: newSize)
                            canvasOffset = centeredOffset
                            lastCanvasOffset = centeredOffset
                        }
                    }
                    
                    toolbarView
                }
            }
            .navigationTitle(navigationTitleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        showDeleteMapConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                    .accessibilityLabel("Elimina mappa")
                }
            }
            .alert("Nuovo nodo", isPresented: $showAddNode) {
                TextField("Come lo vuoi chiamare?", text: $draftNodeLabel)
                
                Button("Salva") {
                    let trimmed = draftNodeLabel.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        vm.addNode(label: trimmed)
                        draftNodeLabel = ""
                    }
                }
                
                Button("Annulla", role: .cancel) {
                    draftNodeLabel = ""
                }
            }
            .alert("Modifica nodo", isPresented: $showEditNode) {
                TextField("Nome nodo", text: $draftNodeLabel)
                
                Button("Salva") {
                    let trimmed = draftNodeLabel.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let selectedID = vm.selectedNodeID, !trimmed.isEmpty {
                        vm.renameNode(id: selectedID, label: trimmed)
                    }
                }
                
                Button("Annulla", role: .cancel) {}
            }
            .confirmationDialog("Vuoi eliminare questo nodo?", isPresented: $showDeleteNodeConfirmation) {
                Button("Elimina", role: .destructive) {
                    if let selectedID = vm.selectedNodeID {
                        vm.deleteNode(id: selectedID)
                    }
                }
                Button("Annulla", role: .cancel) {}
            }
            .confirmationDialog("Vuoi eliminare questa mappa?", isPresented: $showDeleteMapConfirmation) {
                Button("Elimina", role: .destructive) {
                    let mapID = vm.map.id
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        store.deleteMap(id: mapID)
                    }
                }
                Button("Annulla", role: .cancel) {}
            }
            .sensoryFeedback(.selection, trigger: toolFeedback)
            .sensoryFeedback(.selection, trigger: vm.selectedNodeID)
        }
        
        private var headerEditor: some View {
            VStack(alignment: .leading, spacing: MMSpacing.md) {
                TextField("Titolo mappa", text: titleBinding)
                    .font(MMFont.display(26, weight: .bold))
                    .foregroundStyle(.mmTextPrimary)
                    .textFieldStyle(.plain)
                
                Text("Trascina la mappa da qualsiasi punto. Se rinomini il nodo centrale, cambia anche il titolo qui sopra.")
                    .font(MMFont.body(13))
                    .foregroundStyle(.mmTextMuted)
                    .lineSpacing(3)
                
                if let selectedNode {
                    MMCard(padding: MMSpacing.lg, cornerRadius: MMRadius.md, backgroundColor: Color.mmCard.opacity(0.86)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Nodo selezionato")
                                    .font(MMFont.caption(12, weight: .semibold))
                                    .foregroundStyle(.mmTextMuted)
                                
                                Text(selectedNode.label)
                                    .font(MMFont.title(17, weight: .semibold))
                                    .foregroundStyle(.mmTextPrimary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "circle.inset.filled")
                                .foregroundStyle(selectedNode.color)
                        }
                    }
                }
            }
            .padding(.horizontal, MMSpacing.lg)
            .padding(.top, MMSpacing.lg)
            .padding(.bottom, MMSpacing.md)
            .background(Color.clear)
        }
        
        private var mapBackground: some View {
            ZStack {
                LinearGradient(
                    colors: [Color.mmBackground, Color.mmSurface, Color.mmCard],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                EllipticalGradient(
                    colors: [Color.mmAccent2.opacity(0.20), .clear],
                    center: .init(x: 0.2, y: 0.16),
                    endRadiusFraction: 0.72
                )
                .ignoresSafeArea()
                
                EllipticalGradient(
                    colors: [Color.mmTeal.opacity(0.14), .clear],
                    center: .init(x: 0.84, y: 0.76),
                    endRadiusFraction: 0.60
                )
                .ignoresSafeArea()
            }
        }
        
        private var toolbarView: some View {
            HStack(spacing: 10) {
                toolbarButton(
                    title: "Nuovo nodo",
                    icon: "plus.circle.fill",
                    isPrimary: true
                ) {
                    draftNodeLabel = ""
                    showAddNode = true
                    toolFeedback += 1
                }
                
                toolbarButton(
                    title: "Modifica",
                    icon: "pencil",
                    isEnabled: selectedNode != nil
                ) {
                    if let selectedNode {
                        draftNodeLabel = selectedNode.label
                        showEditNode = true
                        toolFeedback += 1
                    }
                }
                
                toolbarButton(
                    title: "Elimina",
                    icon: "trash",
                    tint: .red,
                    isEnabled: selectedNode?.isRoot == false
                ) {
                    showDeleteNodeConfirmation = true
                    toolFeedback += 1
                }
            }
            .padding(.horizontal, MMSpacing.lg)
            .padding(.vertical, MMSpacing.md)
            .safeAreaPadding(.bottom, MMSpacing.xs)
            .background(.ultraThinMaterial)
            .overlay(Divider().opacity(0.08), alignment: .top)
        }
        
        private func toolbarButton(
            title: String,
            icon: String,
            tint: Color = .mmTextPrimary,
            isPrimary: Bool = false,
            isEnabled: Bool = true,
            action: @escaping () -> Void
        ) -> some View {
            Button(action: action) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                    Text(title)
                        .font(MMFont.caption(14, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(isPrimary ? Color.white : tint.opacity(isEnabled ? 1 : 0.45))
                .background(
                    RoundedRectangle(cornerRadius: MMRadius.md, style: .continuous)
                        .fill(
                            isPrimary
                            ? AnyShapeStyle(LinearGradient.mmAccentGradient)
                            : AnyShapeStyle(Color.mmCard.opacity(isEnabled ? 0.88 : 0.45))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: MMRadius.md, style: .continuous)
                                .strokeBorder(isPrimary ? Color.clear : Color.mmBorderStrong, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled)
        }
        
        private var canvasPanGesture: some Gesture {
            DragGesture()
                .onChanged { value in
                    canvasOffset = CGSize(
                        width: lastCanvasOffset.width + value.translation.width,
                        height: lastCanvasOffset.height + value.translation.height
                    )
                }
                .onEnded { _ in
                    lastCanvasOffset = canvasOffset
                }
        }
    }
    
    private struct NodeView: View {
        let node: MapNode
        let isSelected: Bool
        
        private var displaySize: CGFloat {
            node.isRoot ? max(node.size, 88) : node.size
        }
        
        var body: some View {
            ZStack {
                if isSelected {
                    Circle()
                        .stroke(node.color.opacity(0.38), lineWidth: 2)
                        .frame(width: displaySize + 16, height: displaySize + 16)
                }
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [node.color, node.color.opacity(0.64)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: displaySize, height: displaySize)
                    .shadow(color: node.color.opacity(node.isRoot ? 0.30 : 0.18), radius: node.isRoot ? 14 : 6, x: 0, y: 0)
                
                Text(node.label)
                    .font(MMFont.caption(node.isRoot ? 11 : 8, weight: .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(6)
                    .frame(width: displaySize, height: displaySize)
                    .lineLimit(node.isRoot ? 4 : 3)
                    .minimumScaleFactor(0.6)
            }
            .scaleEffect(isSelected ? 1.08 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.78), value: isSelected)
        }
    }
    
    struct MindMapView_Previews: PreviewProvider {
        static var previews: some View {
            MindMapListView()
        }
    }
}
