#if canImport(Combine)
import Combine

extension Document {
    
    func sendPatches() {
        guard patchesSubject != nil || objectPatchSubjects != nil else {
            return
        }

        let newHeads = Set(self.doc.wrapErrors { $0.heads().map { ChangeHash(bytes: $0) } })
        
        let patches = self.doc.wrapErrors { doc in
            doc.difference(before: newHeads.map(\.bytes), after: publishedHeads.map(\.bytes))
        }.map { Patch($0) }

        publishedHeads = newHeads

        guard !patches.isEmpty else {
            return
        }
        
        if let objectPatchSubjects {
            for p in patches {
                let pId = p.action.objId
                if let objectPublisher = objectPatchSubjects[pId] {
                    objectPublisher.send(p)
                }
            }
        }
        
        patchesSubject?.send(patches)
    }

    fileprivate func patchPublisher(for id: ObjId) -> AnyPublisher<Patch, Never> {
        if let publisher = objectPatchSubjects?[id] {
            return publisher.eraseToAnyPublisher()
        }
        if objectPatchSubjects == nil { objectPatchSubjects = .init() }
        objectPatchSubjects![id] = .init()
        return objectPatchSubjects![id]!.eraseToAnyPublisher()
    }
    
    func patchPublisher(for list: List) -> AnyPublisher<List.Patch, Never> {
        sync {
            if let publisher = listPatchPublishers?[list.id] {
                return publisher
            }
            
            if listPatchPublishers == nil { listPatchPublishers = .init() }
            
            let id = list.id
            let objectPublisher = patchPublisher(for: id)
            let listPublisher = objectPublisher.map { patch -> List.Patch in
                switch patch.action {
                case .Insert(let objId, let index, let elements):
                    assert(id == objId)
                    return .insert(index: index, elements: elements)
                case .DeleteSeq(let delSeq):
                    assert(id == delSeq.obj)
                    return .delete(delSeq.index..<delSeq.index + delSeq.length)
                case .Conflict(let objId, let prop):
                    assert(objId == id)
                    switch prop {
                    case .Key:
                        fatalError("Unexpected prop \(prop)")
                    case .Index(let index):
                        return .conflict(index: index)
                    }
                default:
                    fatalError("Unexpected patch \(patch)")
                }
                fatalError()
            }
                .share()
                .eraseToAnyPublisher()
            
            listPatchPublishers![id] = listPublisher
            
            return listPublisher
        }
    }
    
    func patchPublisher(for map: Map) -> AnyPublisher<Map.Patch, Never> {
        sync {
            if let publisher = mapPatchPublishers?[map.id] {
                return publisher
            }
            
            if mapPatchPublishers == nil { mapPatchPublishers = .init() }
            
            let id = map.id
            let mapPublisher = patchPublisher(for: map.id).map { patch -> Map.Patch in
                switch patch.action {
                case .Put(let objId, let prop, let value):
                    assert(objId == id)
                    switch prop {
                    case .Key(let key):
                        return .put(key: key, value: value)
                    case .Index:
                        fatalError("Unexpected prop \(prop)")
                    }
                case .DeleteMap(let objId, let key):
                    assert(objId == id)
                    return .delete(key: key)
                case .Conflict(let objId, let prop):
                    assert(objId == id)
                    switch prop {
                    case .Key(let key):
                        return .conflict(key: key)
                    case .Index:
                        fatalError("Unexpected prop \(prop)")
                    }
                default:
                    fatalError("Unexpected patch \(patch)")
                }
                fatalError()
                
            }
                .share()
                .eraseToAnyPublisher()
            
            mapPatchPublishers![id] = mapPublisher
            
            return mapPublisher
        }
    }
    
    func patchPublisher(for text: Text) -> AnyPublisher<Text.Patch, Never> {
        sync {
            if let publisher = textPatchPublishers?[text.id] {
                return publisher
            }
            
            if textPatchPublishers == nil { textPatchPublishers = .init() }
            
            let id = text.id
            let textPublisher = patchPublisher(for: text.id).map { patch -> Text.Patch in
                switch patch.action {
                case .SpliceText(let objId, let index, let string, let marks):
                    assert(id == objId)
                    return .insert(at: index, string: string, marks: marks)
                case .DeleteSeq(let delSeq):
                    assert(id == delSeq.obj)
                    return .delete(delSeq.index..<delSeq.index + delSeq.length)
                case .Marks(let objId, let marks):
                    assert(id == objId)
                    return .marks(marks)
                default:
                    fatalError()
                }
                fatalError()
            }
                .share()
                .eraseToAnyPublisher()
            
            textPatchPublishers![id] = textPublisher
            
            return textPublisher
        }
    }
    
}
#else
extension Document {
    func sendPatches() {}
}
#endif

extension PatchAction {
    var objId: ObjId {
        switch self {
        case .Put(let objId, _, _):
            return objId
        case .Insert(let objId, _, _):
            return objId
        case .SpliceText(let objId, _, _, _):
            return objId
        case .Increment(let objId, _, _):
            return objId
        case .DeleteMap(let objId, _):
            return objId
        case .DeleteSeq(let delSeq):
            return delSeq.obj
        case .Marks(let objId, _):
            return objId
        case .Conflict(let objId, _):
            return objId
        }
    }
}
