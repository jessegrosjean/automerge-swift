import Combine
@testable import Automerge
import XCTest

class ObjectTypeTests: XCTestCase {

    func testPutIntInMap() throws {
        let store = Document()
        let map = store.root
        var receivedPatches: [Document.Map.Patch] = []
        var cancellables: Set<AnyCancellable> = []
        map.patchPublisher.sink { patches in
            receivedPatches += patches
        }.store(in: &cancellables)

        XCTAssertEqual(map["key"], nil)
        map.put(.Int(1), key: "key")
        XCTAssertEqual(map["key"], .Scalar(.Int(1)))
        XCTAssertEqual(map.count, 1)
        XCTAssertEqual(receivedPatches.count, 1)
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
        var cancellables: Set<AnyCancellable> = []
        list.patchPublisher.sink { patches in
            receivedPatches += patches
        }.store(in: &cancellables)
        list.replaceSubrange(0..<0, with: [.Int(1), .Int(2), .Int(3)])
        XCTAssertEqual(list.count, 3)
        XCTAssertEqual(list.elements, [.Scalar(.Int(1)), .Scalar(.Int(2)), .Scalar(.Int(3))])
        list.replaceSubrange(0..<2, with: [.Int(4)])
        XCTAssertEqual(list.count, 2)
        XCTAssertEqual(list.elements, [.Scalar(.Int(4)), .Scalar(.Int(3))])
        XCTAssertEqual(receivedPatches.count, 3)
    }
    
    func testTextReplaceRange() throws {
        let store = Document()
        let text = store.root.ensureText(key: "key")
        var receivedPatches: [Document.Text.Patch] = []
        var cancellables: Set<AnyCancellable> = []
        text.patchPublisher.sink { patches in
            receivedPatches += patches
        }.store(in: &cancellables)
        let string = "😀👮🏿‍♀️"
        let middleIndex = string.index(after: string.startIndex)
        text.string = "😀👮🏿‍♀️"
        XCTAssertEqual(text.string, string)
        XCTAssertEqual(text.count, 6)
        text.replaceSubrange(string.startIndex..<middleIndex, with: "a")
        XCTAssertEqual(text.string, "a👮🏿‍♀️")
        XCTAssertEqual(receivedPatches.count, 3)
    }
    
    func testGroupPatches() throws {
        let doc = Document()
        let map = doc.root

        var cancellables: Set<AnyCancellable> = []
        var receivedPatchGroups: [[Document.Map.Patch]] = []
        map.patchPublisher.sink { patches in
            receivedPatchGroups.append(patches)
        }.store(in: &cancellables)

        map.put(.Int(1), key: "key1")
        XCTAssertEqual(receivedPatchGroups.count, 1)

        map.put(.Int(2), key: "key2")
        XCTAssertEqual(receivedPatchGroups.count, 2)
        
        map.put(.Int(3), key: "key3")
        XCTAssertEqual(receivedPatchGroups.count, 3)

        doc.groupChanges {
            map.put(.Int(4), key: "key4")
            map.put(.Int(5), key: "key5")
            map.put(.Int(6), key: "key6")
        }
        XCTAssertEqual(receivedPatchGroups.count, 4)
    }
    
    func testGroupPatchesWithMultipleObjects() throws {
        let doc = Document()
        let map1 = doc.root.ensureMap(key: "m1")
        let map2 = doc.root.ensureMap(key: "m2")
        var cancellables: Set<AnyCancellable> = []
        
        var m1PatchGroups: [[Document.Map.Patch]] = []
        map1.patchPublisher.sink { patches in
            m1PatchGroups.append(patches)
        }.store(in: &cancellables)

        var m2PatchGroups: [[Document.Map.Patch]] = []
        map2.patchPublisher.sink { patches in
            m2PatchGroups.append(patches)
        }.store(in: &cancellables)

        doc.groupChanges {
            map2.put(.Int(0), key: "key0")
            map1.put(.Int(1), key: "key1")
            map1.put(.Int(2), key: "key2")
            map2.put(.Int(3), key: "key3")
            map1.put(.Int(4), key: "key4")
            map1.put(.Int(5), key: "key5")
            map2.put(.Int(6), key: "key6")
        }
        
        XCTAssertEqual(m1PatchGroups.count, 2)
        XCTAssertEqual(m1PatchGroups[0].count, 2)
        XCTAssertEqual(m1PatchGroups[1].count, 2)
        XCTAssertEqual(m2PatchGroups.count, 3)
        XCTAssertEqual(m2PatchGroups[0].count, 1)
        XCTAssertEqual(m2PatchGroups[1].count, 1)
        XCTAssertEqual(m2PatchGroups[2].count, 1)
    }
    
}
