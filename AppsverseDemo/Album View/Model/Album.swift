//
//  Album.swift
//  AppsverseDemo
//
//  Created by jeet_gandhi on 14/12/20.
//

import UIKit
import RealmSwift

public struct Album: Codable, Equatable {

    var name: String?
    var number: Int?
    var pin: Data?
    var images: [Data]?

    public var albumRealmObject: AlbumObject {
        AlbumObject(album: self)
    }

    init() {

    }

    public init(name: String?,
                number: Int?,
                pin: Data?,
                images: [Data]?) {
        self.name = name
        self.number = number
        self.pin = pin
        self.images = images
    }

    public init(albumRealmObject: AlbumObject) {
        self.init(name: albumRealmObject.name,
                  number: albumRealmObject.number,
                  pin: albumRealmObject.pin,
                  images: albumRealmObject.images.toArray().compactMap { $0.image })
    }
}

public class AlbumObject: Object {

    @objc dynamic var name: String?
    @objc dynamic var number: Int = 0
    @objc dynamic var pin: Data?
    let images: List<AlbumImageObject> = List<AlbumImageObject>()

    var album: Album {
        return Album(albumRealmObject: self)
    }
    

    convenience init(album: Album) {
        self.init()
        self.name = album.name
        self.number = album.number ?? 0
        self.pin = album.pin
        self.images.append(objectsIn: album.images?.map { AlbumImageObject(image: $0) } ?? [])
    }

    public override static func primaryKey() -> String {
        return "name"
    }
}

public class AlbumImageObject: Object {

    @objc dynamic var image: Data?

    convenience init(image: Data?) {
        self.init()
        self.image = image
    }
}
