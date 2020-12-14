//
//  ImageSectionModel.swift
//  AppsverseDemo
//
//  Created by jeet_gandhi on 14/12/20.
//

import UIKit
import RxDataSources

public struct ImageSectionModel {
    var header: String
    public var items: [ImageCellModel]

    init(header: String? = "", items: [ImageCellModel]) {
        self.header = header!
        self.items = items
    }
}

extension ImageSectionModel: SectionModelType {
    public typealias Item = ImageCellModel

    public init(original: ImageSectionModel, items: [Item]) {
        self = original
        self.items = items
    }
}

extension ImageSectionModel: Equatable {
    public static func == (lhs: ImageSectionModel, rhs: ImageSectionModel) -> Bool {
        return lhs.header == rhs.header
            && lhs.items == rhs.items

    }
}

public struct ImageCellModel {
    var image: Data
}

extension ImageCellModel: Equatable {
    public static func == (lhs: ImageCellModel, rhs: ImageCellModel) -> Bool {
        return lhs.image == rhs.image
    }
}

