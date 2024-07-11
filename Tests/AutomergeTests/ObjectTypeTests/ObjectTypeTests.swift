@testable import Automerge
import XCTest

class ObjectTypeTests: XCTestCase {

    func testPutIntInMap() throws {
        let store = Document()
        let map = store.root

        XCTAssertEqual(map["key"], nil)
        map.put(.Int(1), key: "key")
        XCTAssertEqual(map["key"], .Scalar(.Int(1)))
        XCTAssertEqual(map.count, 1)
    }
    
    func testEnsureListInMap() throws {
        let store = Document()
        let map = store.root

        XCTAssertEqual(map["key"], nil)
        let l1 = map.ensureList(key: "key")
        let l2 = map.ensureList(key: "key")
        XCTAssertEqual(map.count, 1)
        XCTAssertEqual(l1.id, l2.id)
    }
    
    func testListReplaceRange() throws {
        let store = Document()
        let list = store.root.ensureList(key: "key")
        var receivedPatches: [Document.List.Patch] = []
        let cancellable = list.patchePublisher.sink { patch in
            receivedPatches.append(patch)
        }
        list.replaceSubrange(0..<0, with: [.Int(1), .Int(2), .Int(3)])
        XCTAssertEqual(list.count, 3)
        XCTAssertEqual(list.elements, [.Scalar(.Int(1)), .Scalar(.Int(2)), .Scalar(.Int(3))])
        list.replaceSubrange(0..<2, with: [.Int(4)])
        XCTAssertEqual(list.count, 2)
        XCTAssertEqual(list.elements, [.Scalar(.Int(4)), .Scalar(.Int(3))])
        XCTAssertEqual(receivedPatches.count, 2)
    }
    
    func testTextReplaceRange() throws {
        let store = Document()
        let text = store.root.ensureText(key: "key")
        var receivedPatches: [Document.Text.Patch] = []
        let cancellable = text.patchePublisher.sink { patch in
            receivedPatches.append(patch)
        }
        let string = "😀👮🏿‍♀️"
        let middleIndex = string.index(after: string.startIndex)
        text.string = "😀👮🏿‍♀️"
        XCTAssertEqual(text.string, string)
        XCTAssertEqual(text.count, 6)
        text.replaceSubrange(string.startIndex..<middleIndex, with: "a")
        XCTAssertEqual(text.string, "a👮🏿‍♀️")
        XCTAssertEqual(receivedPatches.count, 2)
    }
    
}
