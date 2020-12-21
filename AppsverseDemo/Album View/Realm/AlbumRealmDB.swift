//
//  AlbumRealmDB.swift
//  AppsverseDemo
//
//  Created by jeet_gandhi on 14/12/20.
//

import Foundation
import RealmSwift
import RxSwift
import RxCocoa

public protocol AlbumRealmDB {
    func fetchUpdateAlbums() -> Observable<TaskUIEvent<[Album]>>
    func saveAlbum(albums: [Album])
    func updateAlbum(album: Album)
    func removeAlbum(albumName: String) -> Observable<TaskUIEvent<Album>>
}

public class RealmDB: RealmDBType {

    public var fileLocation: String { return "Albums" }
    public var dbName: String { return "Albums.realm" }
    public var realm: Realm?

    public var schemaVersion: UInt64 { return 1 }
    public var migrationBlock: MigrationBlock?

    public var objectTypes: [Object.Type] {
        return [
            AlbumObject.self,
            AlbumImageObject.self
        ]
    }

    public static var shared: RealmDB = RealmDB()
    private init() { }
}

extension RealmDB: AlbumRealmDB {

    public func fetchUpdateAlbums() -> Observable<TaskUIEvent<[Album]>> {
        return Observable<TaskUIEvent<[Album]>>.create { observer in
            guard let albums = RealmDB.shared.realmObjects(type: AlbumObject.self) else {
                observer.on(.next(TaskUIEvent.succeeded([])))
                observer.on(.completed)
                return Disposables.create()
            }
            observer.on(.next(TaskUIEvent.succeeded(albums.map { $0.album })))
            observer.on(.completed)
            return Disposables.create()
        }.startWith(.waiting)
    }

    public func saveAlbum(albums: [Album]) {
        RealmDB.shared.save(objects: albums.map { $0.albumRealmObject })
    }

    public func updateAlbum(album: Album) {
        RealmDB.shared.save(object: album.albumRealmObject, deleteBeforeSave: true)
    }

    public func removeAlbum(albumName: String) -> Observable<TaskUIEvent<Album>> {
        return Observable<TaskUIEvent<Album>>.create { [weak self] observer in
            guard let albumObject = self?.fetchAlbum(for: albumName) else {
                observer.on(.error(AlbumDBError.fetchError))
                observer.on(.completed)
                return Disposables.create()
            }
            let album = albumObject.album
            RealmDB.shared.delete(objects: [albumObject])
            observer.on(.next(TaskUIEvent.succeeded(album)))
            observer.on(.completed)
            return Disposables.create()
        }.startWith(.waiting)
    }

    private func fetchAlbum(for name: String) -> AlbumObject {
        guard let albums = RealmDB.shared.realmObjects(type: AlbumObject.self),
              let fetchedAlbum = albums.filter({ $0.name == name }).first else {
            fatalError("RealmDB: (\(dbName)), init: unable to find the object with \(name)")
        }
        return fetchedAlbum
    }

    public static func setUpRealmDB() {
        RealmDB.shared.initializeDB { (success, _) in
            if !success {
                RealmDB.shared.cleanAndReintializeDB(completion: { _ in })
            }
        }
    }


}


enum AlbumDBError: Error {
    case fetchError
    case unknown
}

extension AlbumDBError: LocalizedError {

    var errorDescription: String? {
        switch self {
            case .unknown:
                return "Unknown Error occured"
            case .fetchError:
                return "Cannot fetch the Album"
        }
    }
}
