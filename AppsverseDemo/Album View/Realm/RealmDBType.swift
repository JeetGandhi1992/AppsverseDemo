//
//  RealmDBType.swift
//  Meow
//
//  Created by jeet_gandhi on 29/11/20.
//

import Foundation
import RealmSwift
import RxSwift
import RxRealm
import Realm

public protocol RealmDBType: AnyObject {
    /// Use to generate key and realm database
    var dbName: String { get }
    var realm: Realm? { get set }
    var schemaVersion: UInt64 { get }
    var migrationBlock: MigrationBlock? { get }
    var objectTypes: [Object.Type] { get }
    /// Use to create db folder
    var fileLocation: String { get }

    func initializeDB(completion: (_ success: Bool, _ error: Error?) -> Void)
    func cleanAndReintializeDB(completion: (_ success: Bool) -> Void)
    func resetDB()
    func save<T: Object>(object: T, deleteBeforeSave: Bool)
    func save<T: Object>(objects: [T])
    func update(objects: [Object])
    func realmObjects<T: Object>(type: T.Type, predicate: NSPredicate?) -> [T]?
    func realmObject<T: Object, K: Any>(type: T.Type, primaryKey: K) -> T?
    func delete(objects: [Object])
    func collectionChanged<T: Object>() -> Observable<[T]>
    func removeDatabaseFile()
}

extension RealmDBType {

    public func initializeDB(completion: (_ success: Bool, _ error: Error?) -> Void) {
        do {
            let dbURL = getDBURL()
            guard let key = RealmKey.getKey(dbName: dbName) as Data? else {
                fatalError("RealmDB: (\(dbName), init: key not found")
            }
            let config = Realm.Configuration(fileURL: dbURL,
                                             encryptionKey: nil,
                                             objectTypes: objectTypes)
            self.realm = try Realm(configuration: config)
            completion(true, nil)
        } catch let error {
            completion(false, error)
        }
    }

    public func cleanAndReintializeDB(completion: (_ success: Bool) -> Void) {
        self.removeDatabaseFile()
        self.initializeDB { (success, error) in
            if !success {
                fatalError("RealmDB: (\(dbName)), init: \(String(describing: error?.localizedDescription))")
            } else {
                completion(success)
            }
        }
    }

    public func resetDB() {
        do {
            try self.realm?.write {
                self.realm?.deleteAll()
            }
        } catch {
            fatalError("RealmDB: (\(dbName)), init: unable to resetDB \(error.localizedDescription)")
        }
    }

    /// Convenience method to save with update
    public func save<T: Object>(object: T, deleteBeforeSave: Bool = false) {
        do {
            try self.realm?.write {

                if deleteBeforeSave {
                    self.realm?.deleteAll()
                }

                self.realm?.add(object, update: .all)
            }
        } catch (let error) {
            fatalError("RealmDB: (\(dbName)), save T: \(error.localizedDescription)")
        }
    }

    public func save<T: Object>(objects: [T]) {
        do {
            try self.realm?.write {
                self.realm?.add(objects, update: .all)
            }
        } catch (let error) {
            fatalError("RealmDB: (\(dbName)), save[T]: \(error.localizedDescription)")
        }
    }

    public func update(objects: [Object]) {
        do {
            try self.realm?.write {
                for obj in objects {
                    self.realm?.add(obj, update: .all)
                }
            }
        } catch {
            fatalError("RealmDB: (\(dbName)), update: \(objects) error: \(error.localizedDescription)")
        }
    }

    //Retrieve
    public func realmObjects<T: Object>(type: T.Type, predicate: NSPredicate? = nil) -> [T]? {
        var realmObjects: [T]?
        do {
            try self.realm?.write {
                if let pred = predicate {
                    realmObjects = self.realm?.objects(T.self).filter(pred).toArray()
                } else {
                    realmObjects = self.realm?.objects(T.self).toArray()
                }
            }
        } catch let error {
            fatalError("RealmDB: (\(dbName)), delete: \(error.localizedDescription)")
        }
        return realmObjects
    }

    public func realmObject<T: Object, K: Any>(type: T.Type, primaryKey: K) -> T? {
        return self.realm?.object(ofType: type, forPrimaryKey: primaryKey)
    }

    public func delete(objects: [Object]) {
        do {
            try self.realm?.write {
                self.realm?.delete(objects)
            }
        } catch let error {
            fatalError("RealmDB: (\(dbName)), setRealmObject: \(error.localizedDescription)")
        }
    }

    public func removeDatabaseFile() {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let url: URL =  URL(fileURLWithPath: documentsPath).appendingPathComponent(fileLocation)

        guard FileManager.default.fileExists(atPath: url.path) else {
            return
        }

        do {
            try FileManager.default.removeItem(at: url)
        } catch let error {
            fatalError("RealmDB: (\(dbName)), removeDatabaseFile: \(error.localizedDescription)")
        }
    }

    private func getDBURL() -> URL {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let url: URL =  URL(fileURLWithPath: documentsPath).appendingPathComponent(fileLocation)

        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) {
            if !isDir.boolValue {
                createDirectory(url)
            }
        } else {
            createDirectory(url)
        }

        let dbURL = url.appendingPathComponent(dbName)
        return dbURL
    }

    private func createDirectory(_ path: URL) {
        do {
            try FileManager.default.createDirectory(at: path,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
        } catch {
            fatalError("RealmDB: (\(dbName)), init: unable to create a directory at path \(path)")
        }
    }

    public func collectionChanged<T: Object>() -> Observable<[T]> {
        guard let realm = realm else { return Observable.just([]) }
        let result = realm.objects(T.self)
        return Observable.collection(from: result).map { $0.toArray() }
    }
}

protocol CascadeDeleting {
    func delete<S: Sequence>(_ objects: S, cascading: Bool) where S.Iterator.Element: Object
    func delete<Entity: Object>(_ entity: Entity, cascading: Bool)
}

extension Realm: CascadeDeleting {
    func delete<S: Sequence>(_ objects: S, cascading: Bool) where S.Iterator.Element: Object {
        for obj in objects {
            delete(obj, cascading: cascading)
        }
    }

    func delete<Entity: Object>(_ entity: Entity, cascading: Bool) {
        if cascading {
            cascadeDelete(entity)
        } else {
            delete(entity)
        }
    }
}

private extension Realm {
    private func cascadeDelete(_ entity: RLMObjectBase) {
        guard let entity = entity as? Object else { return }
        var toBeDeleted = Set<RLMObjectBase>()
        toBeDeleted.insert(entity)
        while !toBeDeleted.isEmpty {
            guard let element = toBeDeleted.removeFirst() as? Object,
                  !element.isInvalidated else { continue }
            resolve(element: element, toBeDeleted: &toBeDeleted)
        }
    }

    private func resolve(element: Object, toBeDeleted: inout Set<RLMObjectBase>) {
        element.objectSchema.properties.forEach {
            guard let value = element.value(forKey: $0.name) else { return }
            if let entity = value as? RLMObjectBase {
                toBeDeleted.insert(entity)
            } else if let list = value as? RealmSwift.ListBase {
                for index in 0 ..< list._rlmArray.count {
                    if let realmObject = list._rlmArray.object(at: index) as? RLMObjectBase {
                        toBeDeleted.insert(realmObject)
                    }
                }
            }
        }
        delete(element)
    }
}

