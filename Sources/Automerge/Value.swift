import Foundation

import enum AutomergeUniffi.Value

typealias FfiValue = AutomergeUniffi.Value

/// A type that represents a value or object managed by Automerge.
public enum Value: Equatable, Hashable, Sendable {
    /// An object type
    case Object(ObjId, ObjType)
    /// A scalar value
    case Scalar(ScalarValue)

    static func fromFfi(value: FfiValue) -> Self {
        switch value {
        case let .object(typ, id):
            return .Object(ObjId(bytes: id), ObjType.fromFfi(ty: typ))
        case let .scalar(v):
            return .Scalar(ScalarValue.fromFfi(value: v))
        }
    }
}

extension Value: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case let .Object(objId, objType):
            return "Object<\(objId), \(objType)>"
        case let .Scalar(scalarValue):
            return "ScalarValue<\(scalarValue)>"
        }
    }
}

extension Value {

    public var scalarValue: ScalarValue? {
        if case .Scalar(let scalar) = self {
            return scalar
        }
        return nil
    }
    
    public func listValue(in document: Document) -> Document.List? {
        if case .Object(let id, .List) = self {
            return .init(id: id, doc: document)
        }
        return nil
    }

    public func mapValue(in document: Document) -> Document.Map? {
        if case .Object(let id, .Map) = self {
            return .init(id: id, doc: document)
        }
        return nil
    }

    public func textValue(in document: Document) -> Document.Text? {
        if case .Object(let id, .Text) = self {
            return .init(id: id, doc: document)
        }
        return nil
    }

}
