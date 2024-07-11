#if canImport(Combine)
import Combine
#endif

extension Document {
        
    public struct List: Equatable {
        public static func == (lhs: Document.List, rhs: Document.List) -> Bool {
            lhs.doc === rhs.doc && lhs.id == rhs.id
        }
        public enum Patch {
            case insert(index: UInt64, elements: [Automerge.Value])
            case delete(Range<UInt64>)
            case conflict(index: UInt64)
        }
        public let id: ObjId
        public var doc: Document
        #if canImport(Combine)
        public var patchePublisher: AnyPublisher<Patch, Never> {
            doc.patchPublisher(for: self)
        }
        #endif
    }

}

extension Document.List {
    
    public var count: UInt64 {
        doc.length(obj: id)
    }
    
    public var elements: [Value] {
        try! doc.values(obj: id)
    }
    
    public subscript(index: UInt64) -> Value? {
        try! doc.get(obj: id, index: index)
    }
    
    public func insert(_ value: ScalarValue, at index: UInt64) {
        try! doc.insert(obj: id, index: index, value: value)
    }

    public func insertList(at index: UInt64) -> Document.List {
        .init(id: try! doc.insertObject(obj: id, index: index, ty: .List), doc: doc)
    }
    
    public func insertMap(at index: UInt64) -> Document.Map {
        .init(id: try! doc.insertObject(obj: id, index: index, ty: .Map), doc: doc)
    }

    public func insertText(at index: UInt64) -> Document.Text {
        .init(id: try! doc.insertObject(obj: id, index: index, ty: .Text), doc: doc)
    }

    public func put(_ value: ScalarValue, at index: UInt64) {
        try! doc.put(obj: id, index: index, value: value)
    }

    public func ensureList(at index: UInt64, forceReplace: Bool = false) -> Document.List {
        if !forceReplace, case .some(.Object(let objId, let objType)) = try! doc.get(obj: id, index: index) {
            if objType == .List {
                return .init(id: objId, doc: doc)
            }
        }
        return .init(id: try! doc.putObject(obj: id, index: index, ty: .List), doc: doc)
    }
    
    public func ensureMap(at index: UInt64, forceReplace: Bool = false) -> Document.Map {
        if !forceReplace, case .some(.Object(let objId, let objType)) = try! doc.get(obj: id, index: index) {
            if objType == .Map {
                return .init(id: objId, doc: doc)
            }
        }
        return .init(id: try! doc.putObject(obj: id, index: index, ty: .Map), doc: doc)
    }
    
    public func ensureText(at index: UInt64, forceReplace: Bool = false) -> Document.Text {
        if !forceReplace, case .some(.Object(let objId, let objType)) = try! doc.get(obj: id, index: index) {
            if objType == .Text {
                return .init(id: objId, doc: doc)
            }
        }
        return .init(id: try! doc.putObject(obj: id, index: index, ty: .Text), doc: doc)
    }
    
    public func replaceSubrange(_ range: Range<UInt64>, with values: [ScalarValue]) {
        try! doc.splice(
            obj: id,
            start: range.lowerBound,
            delete: Int64(range.upperBound - range.lowerBound),
            values: values
        )
    }

    public func remove(at index: UInt64) -> Value? {
        let v = self[index]
        try! doc.delete(obj: id, index: index)
        return v
    }
    
}
