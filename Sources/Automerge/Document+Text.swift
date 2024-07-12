#if canImport(Combine)
import Combine
#endif

extension Document {
    
    public struct Text: Equatable {
        public static func == (lhs: Document.Text, rhs: Document.Text) -> Bool {
            lhs.doc === rhs.doc && lhs.id == rhs.id
        }
        public enum Patch {
            case insert(at: UInt64, string: String, marks: [String : Automerge.Value])
            case delete(Range<UInt64>)
            case marks([Mark])
        }
        public let id: ObjId
        public var doc: Document
        #if canImport(Combine)
        public var patchPublisher: AnyPublisher<[Patch], Never> {
            doc.patchPublisher(for: self)
        }
        #endif
    }

}

extension Document.Text {

    public var count: UInt64 {
        doc.length(obj: id)
    }

    public var string: String {
        get {
            try! doc.text(obj: id)
        }
        nonmutating set {
            try! doc.updateText(obj: id, value: newValue)
        }
    }

    public func replaceSubrange(_ range: Range<String.Index>, with text: String) {
        let string = string
        let start = string.unicodeScalars.distance(from: string.startIndex, to: range.lowerBound)
        let length = string.unicodeScalars.distance(from: range.lowerBound, to: range.upperBound)
        replaceSubrange(UInt64(start)..<UInt64(start + length), with: text)
    }
    
    public func replaceSubrange(_ range: Range<UInt64>, with text: String) {
        try! doc.spliceText(
            obj: id,
            start: range.lowerBound,
            delete: Int64(range.upperBound - range.lowerBound),
            value: text
        )
    }
    
}
