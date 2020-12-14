//
//  AlbumDetailViewModel.swift
//  AppsverseDemo
//
//  Created by jeet_gandhi on 14/12/20.
//

import UIKit
import RxSwift
import RxCocoa

public enum AlbumDetailViewModelEvents {
    case imageAdded(TaskUIEvent<Data>)
    case imageTapped(TaskUIEvent<Data>)
    case ignore
}

extension AlbumDetailViewModelEvents: Equatable {
    public static func == (lhs: AlbumDetailViewModelEvents, rhs: AlbumDetailViewModelEvents) -> Bool {
        switch (lhs, rhs) {
            case (.imageTapped(let albumCreatedL), .imageTapped(let albumCreatedR)):
                return albumCreatedL == albumCreatedR
            case (.ignore, .ignore):
                return true
            default:
                return false
        }
    }
}

extension AlbumDetailViewModelEvents: MapsToTaskEvent {
    public func toNetworkEvent() -> TaskUIEvent<()>? {
        switch self {
            case .imageAdded(let event):
                return event.ignoreResponse()
            case .imageTapped(let event):
                return event.ignoreResponse()
            case .ignore:
                return nil
        }
    }
}


protocol AlbumDetailViewModelType: TaskViewModel {
    var keyChainHelper: KeyChainHelperType { get }
    var events: PublishSubject<AlbumDetailViewModelEvents> { get }
    var imagerPickerManager: ImagerPickerManager { get }
    var album: Album { get }
}

class AlbumDetailViewModel: AlbumDetailViewModelType {

    var album: Album
    var keyChainHelper: KeyChainHelperType
    var imagerPickerManager: ImagerPickerManager

    var images: BehaviorRelay<[Data]> = BehaviorRelay<[Data]>(value: [])
    var imageSectionModel = BehaviorRelay(value: ImageSectionModel(items: []))
    let selectedImage = PublishSubject<UIImage>()
    var sharedRealm: AlbumRealmDB

    var events = PublishSubject<AlbumDetailViewModelEvents>()
    var disposeBag = DisposeBag()

    init(keyChainHelper: KeyChainHelperType,
         imagerPickerManager: ImagerPickerManager,
         album: Album,
         sharedRealm: AlbumRealmDB = RealmDB.shared) {
        self.keyChainHelper = keyChainHelper
        self.imagerPickerManager = imagerPickerManager
        self.album = album
        self.sharedRealm = sharedRealm
        setupEvents()
        setupBindAlbums()
        self.images.accept(self.album.images ?? [])
    }

    private func setupBindAlbums() {

        self.images.asDriver().drive(onNext: { [weak self] _ in
            guard let self = self else { return }
            let imageCellModels = self.getImageCellModels()
            self.imageSectionModel.accept(ImageSectionModel(header: "",
                                                            items: imageCellModels))
        }).disposed(by: disposeBag)
    }

    private func setupEvents() {
        self.events
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] (event) in
                guard let self = self else { return }
                switch event {
                    case .imageAdded(.succeeded(let data)):
                        let updatedImages = self.images.value + [data]
                        self.album.images = updatedImages
                        self.save(albums: [self.album])
                        self.images.accept(updatedImages)
                    case .imageTapped(.succeeded(let imageData)):
                        if let image = UIImage(data: imageData) {
                            self.selectedImage.onNext(image)
                        }
                    default:
                        break
                }
            })
            .disposed(by: disposeBag)
    }

    func getImageCellModels() -> [ImageCellModel] {
        var imageCellModels = [ImageCellModel]()

        for (image) in self.images.value {
            let imageCellModel = ImageCellModel(image: image)
            imageCellModels.append(imageCellModel)
        }
        return imageCellModels
    }

    func save(albums: [Album])  {
        self.sharedRealm.updateAlbum(albums: albums)
    }

    func saveImage(imageData: Data) {
        self.keyChainHelper
            .encrypt(inputData: imageData)
            .observeOn(MainScheduler.asyncInstance)
            .asDriver(onErrorJustReturn: TaskUIEvent.failed(DeviceError.deviceIsMalicious))
            .drive(onNext: { (event) in
                self.events.onNext(.imageAdded(event))
            })
            .disposed(by: disposeBag)
        
    }

    func displayImage(data: Data) {
        self.keyChainHelper.decrypt(encryptedData: data)
            .subscribeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { (event) in
                self.events.onNext(.imageTapped(event))
            })
            .disposed(by: disposeBag)
    }

}
