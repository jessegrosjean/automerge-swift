import Foundation

#if canImport(Combine)
import Combine
#endif

extension Document {

    public struct Map: Equatable {
        public static func == (lhs: Document.Map, rhs: Document.Map) -> Bool {
            lhs.doc === rhs.doc && lhs.id == rhs.id
        }
        public enum Patch {
            case put(key: String, value: Automerge.Value)
            case delete(key: String)
            case conflict(key: String)
        }
        public let id: ObjId
        public var doc: Document
        #if canImport(Combine)
        public var patchPublisher: AnyPublisher<Patch, Never> {
            doc.patchPublisher(for: self)
        }
        #endif
    }

}

extension Document.Map {

    public var count: UInt64 {
        doc.length(obj: id)
    }

    public var keys: [String] {
        doc.keys(obj: id)
    }

    public var entries: [(String, Value)] {
        try! doc.mapEntries(obj: id)
    }

    public subscript(key: String) -> Value? {
        try! doc.get(obj: id, key: key)
    }
    
    public func put(_ value: ScalarValue, key: String) {
        try! doc.put(obj: id, key: key, value: value)
    }
    
    public func ensureList(key: String, forceReplace: Bool = false) -> Document.List {
        if !forceReplace, case .some(.Object(let objId, let objType)) = try! doc.get(obj: id, key: key) {
            if objType == .List {
                return .init(id: objId, doc: doc)
            }
        }
        return .init(id: try! doc.putObject(obj: id, key: key, ty: .List), doc: doc)
    }
    
    public func ensureMap(key: String, forceReplace: Bool = false) -> Document.Map {
        if !forceReplace, case .some(.Object(let objId, let objType)) = try! doc.get(obj: id, key: key) {
            if objType == .Map {
                return .init(id: objId, doc: doc)
            }
        }
        return .init(id: try! doc.putObject(obj: id, key: key, ty: .Map), doc: doc)
    }
    
    public func ensureText(key: String, forceReplace: Bool = false) -> Document.Text {
        if !forceReplace, case .some(.Object(let objId, let objType)) = try! doc.get(obj: id, key: key) {
            if objType == .Text {
                return .init(id: objId, doc: doc)
            }
        }
        return .init(id: try! doc.putObject(obj: id, key: key, ty: .Text), doc: doc)
    }
    
    @discardableResult
    public func removeValue(forKey key: String) -> Value? {
        let v = self[key]
        try! doc.delete(obj: id, key: key)
        return v
    }

}
