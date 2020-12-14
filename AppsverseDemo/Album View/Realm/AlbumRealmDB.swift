//
//  AlbumRealmDB.swift
//  AppsverseDemo
//
//  Created by jeet_gandhi on 14/12/20.
//

import Foundation
import RealmSwift

public protocol AlbumRealmDB {
    func fetchAlbums() -> [Album]
    func saveAlbum(albums: [Album])
    func updateAlbum(albums: [Album])
    func removeAlbum(albums: [Album])
}

public class RealmDB: RealmDBType {

    public var fileLocation: String { return "Albums" }
    public var dbName: String { return "Albums.realm" }
    public var realm: Realm?

    public var schemaVersion: UInt64 { return 1 }
    public var migrationBlock: MigrationBlock?

    public var objectTypes: [Object.Type] {
        return [
            AlbumObject.self
        ]
    }

    public static var shared: RealmDB = RealmDB()
    private init() { }
}

extension RealmDB: AlbumRealmDB {

    public func fetchAlbums() -> [Album] {
        guard let albums = RealmDB.shared.realmObjects(type: AlbumObject.self) else {
            return []
        }
        return albums.map { $0.album }
    }

    public func saveAlbum(albums: [Album]) {
        RealmDB.shared.save(objects: albums.map { $0.albumRealmObject })
    }

    public func updateAlbum(albums: [Album]) {
        RealmDB.shared.update(objects: albums.map { $0.albumRealmObject }) { (album) in
            print(album)
        }
    }

    public func removeAlbum(albums: [Album]) {
        let catObjects = albums.map { fetchAlbumsForAdoption(for: $0.name ?? "") }
        RealmDB.shared.delete(objects: catObjects)
    }

    private func fetchAlbumsForAdoption(for name: String) -> AlbumObject {
        guard let dbAlbum = RealmDB.shared.realmObjects(type: AlbumObject.self)?.filter({ $0.name == name }).first else {
            fatalError("RealmDB: (\(dbName)), init: unable to find the object with \(name)")
        }
        return dbAlbum
    }

    public static func setUpRealmDB() {
        RealmDB.shared.initializeDB { (success, _) in
            if !success {
                RealmDB.shared.cleanAndReintializeDB(completion: { _ in })
            }
        }
    }


}
