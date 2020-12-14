//
//  AlbumSectionModel.swift
//  AppsverseDemo
//
//  Created by jeet_gandhi on 14/12/20.
//

import UIKit
import RxDataSources

public struct AlbumSectionModel {
    var header: String
    public var items: [AlbumCellModel]

    init(header: String? = "", items: [AlbumCellModel]) {
        self.header = header!
        self.items = items
    }
}

extension AlbumSectionModel: SectionModelType {
    public typealias Item = AlbumCellModel

    public init(original: AlbumSectionModel, items: [Item]) {
        self = original
        self.items = items
    }
}

extension AlbumSectionModel: Equatable {
    public static func == (lhs: AlbumSectionModel, rhs: AlbumSectionModel) -> Bool {
        return lhs.header == rhs.header
            && lhs.items == rhs.items

    }
}

public struct AlbumCellModel {
    var album: Album
}

extension AlbumCellModel: Equatable {
    public static func == (lhs: AlbumCellModel, rhs: AlbumCellModel) -> Bool {
        return lhs.album == rhs.album
    }
}
