// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !os(tvOS)

import SwiftUI

public enum ThemeEditableListSection {
    public struct RemoveLabel: View {
        let action: () -> Void

        public init(action: @escaping () -> Void) {
            self.action = action
        }
    }

    public struct EditLabel: View {
    }
}

// MARK: - Implementation

public protocol EditableValue: Hashable, CustomStringConvertible, Sendable {
    static var emptyValue: Self { get }

    var isEmptyValue: Bool { get }
}

extension String: EditableValue {
    public static var emptyValue: String {
        ""
    }

    public var isEmptyValue: Bool {
        trimmingCharacters(in: .whitespaces) == ""
    }
}

public struct EditableListSection<ItemView: View, RemoveView: View, EditView: View, T: EditableValue>: View {
    typealias Item = EditableListSectionItem<T>

    private let title: String?

    private let addTitle: String

    @Binding
    private var originalItems: [T]

    private let emptyValue: (() async -> T)?

    private let canRemove: ([Item]) -> Bool

    private let itemLabel: (Bool, Binding<T>) -> ItemView

    private let removeLabel: (@escaping () -> Void) -> RemoveView

    private let editLabel: () -> EditView

    @State
    private var items: [Item] = []

    @State
    private var draggingItem: Item?

    @State
    private var isEditing = false

    public init(
        _ title: String?,
        addTitle: String,
        originalItems: Binding<[T]>,
        emptyValue: (() async -> T)? = nil,
        canRemove: @escaping ([EditableListSectionItem<T>]) -> Bool = { _ in true },
        @ViewBuilder itemLabel: @escaping (Bool, Binding<T>) -> ItemView,
        @ViewBuilder removeLabel: @escaping (@escaping () -> Void) -> RemoveView,
        @ViewBuilder editLabel: @escaping () -> EditView
    ) {
        self.title = title
        self.addTitle = addTitle
        _originalItems = originalItems
        self.emptyValue = emptyValue
        self.canRemove = canRemove
        self.itemLabel = itemLabel
        self.removeLabel = removeLabel
        self.editLabel = editLabel
    }

    public var body: some View {
        Group {
            ForEach(items, id: \.id) { item in
                RemovableItemRow(isEditing: isEditing) {
                    itemView(for: item)
                } removeView: {
                    removeView(for: item)
                        .disabled(!canRemove(items))
                }
                .deleteDisabled(!canRemove(items))
                .onDrag {
                    draggingItem = item
                    return NSItemProvider(object: item.value.description as NSString)
                }
                .onDrop(of: [.text], delegate: ItemDropDelegate(
                    item: item,
                    items: $items,
                    draggingItem: $draggingItem
                ))
            }
            .onMove {
                items.move(fromOffsets: $0, toOffset: $1)
            }
            .onDelete {
                guard canRemove(items) else {
                    assertionFailure("EditableListSection: Remove view should be disabled (!canRemove)")
                    return
                }
                items.remove(atOffsets: $0)
            }
            .onChange(of: items, exportItems)

            ThemeTrailingContent {
#if os(iOS)
                addButton
#elseif os(macOS)
                editButton
                addButton
#endif
            }
        }
        .themeSection(header: title)
        .onLoad(perform: importItems)
    }
}

public struct EditableListSectionItem<T>: Identifiable, Hashable where T: EditableValue {
    public let id = UUID()

    public var value: T

    public var isEmpty: Bool {
        value.isEmptyValue
    }
}

private extension EditableListSection {
    struct ItemDropDelegate: DropDelegate {
        let item: Item

        @Binding
        var items: [Item]

        @Binding
        var draggingItem: Item?

        func performDrop(info: DropInfo) -> Bool {
            draggingItem = nil
            return true
        }

        func dropEntered(info: DropInfo) {
            guard let draggingItem = draggingItem, draggingItem != item else {
                return
            }
            guard let fromIndex = items.firstIndex(of: draggingItem) else {
                return
            }
            guard let toIndex = items.firstIndex(of: item) else {
                return
            }
            guard fromIndex != toIndex else {
                return
            }
            withAnimation {
                items.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
            }
        }
    }
}

private extension EditableListSection {
    var canAdd: Bool {
        if let lastItem = items.last {
            return !lastItem.isEmpty
        }
        return true
    }

    var canEdit: Bool {
        !items.isEmpty
    }

    func itemView(for item: Item) -> some View {
        itemLabel(isEditing, itemValueBinding(for: item))
    }

    func itemValueBinding(for item: Item) -> Binding<T> {
        Binding {
            item.value
        } set: {
            guard let itemIndex = items.firstIndex(where: { $0.id == item.id }) else {
                return
            }
            items[itemIndex].value = $0
        }
    }

    func removeView(for item: Item) -> some View {
        removeLabel {
            guard canRemove(items) else {
                assertionFailure("EditableListSection: Remove view should be disabled (!canRemove)")
                return
            }
            withAnimation {
                items.removeAll {
                    $0.id == item.id
                }
            }
        }
    }

    var addButton: some View {
        Button(addTitle) {
            Task {
                let newValue = await emptyValue?() ?? T.emptyValue
                withAnimation {
                    items.append(Item(value: newValue))
                }
            }
        }
        .disabled(!canAdd)
    }

    var editButton: some View {
        Toggle(isOn: $isEditing, label: editLabel)
            .toggleStyle(.button)
            .disabled(!canEdit)
    }
}

private extension EditableListSection {
    func importItems() {
        items = originalItems.map(Item.init)
    }

    func exportItems() {
        let newOriginalItems = items.map(\.value)
        guard newOriginalItems != originalItems else { return }
        originalItems = newOriginalItems
    }
}

// MARK: - Preview

#Preview {
    struct ContentView: View {
        @State
        private var originalItems = ["One", "Two", "Three"]

        var body: some View {
            Form {
                EditableListSection(
                    "Title",
                    addTitle: "Add item",
                    originalItems: $originalItems
                ) {
                    if $0 {
                        Text($1.wrappedValue)
                    } else {
                        TextField("", text: $1)
                    }
                } removeLabel: { action in
                    Button("Remove", action: action)
                } editLabel: {
                    Image(systemName: "arrow.up.arrow.down")
                }
            }
        }
    }

    return ContentView()
}

#endif
