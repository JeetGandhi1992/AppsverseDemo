//
//  AlbumCollectionViewCell.swift
//  AppsverseDemo
//
//  Created by jeet_gandhi on 14/12/20.
//

import UIKit
import RxSwift
import RxCocoa

class AlbumCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var deleteButton: UIButton!

    var disposeBag: DisposeBag = DisposeBag()

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func prepareForReuse() {
        self.disposeBag = DisposeBag()
    }

}
