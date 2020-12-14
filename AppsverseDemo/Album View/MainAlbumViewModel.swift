//
//  MainAlbumViewModel.swift
//  AppsverseDemo
//
//  Created by jeet_gandhi on 13/12/20.
//

import UIKit
import RxSwift
import RxCocoa

public enum MainAlbumViewModelEvents {
    case albumCreated(TaskUIEvent<Data>, name: String)
    case pinVerified(TaskUIEvent<Data>, album: Album, pin: String)
    case ignore
}

extension MainAlbumViewModelEvents: Equatable {
    public static func == (lhs: MainAlbumViewModelEvents, rhs: MainAlbumViewModelEvents) -> Bool {
        switch (lhs, rhs) {
            case (.albumCreated(let albumCreatedL, let nameL), .albumCreated(let albumCreatedR, let nameR)):
                return albumCreatedL == albumCreatedR &&  nameL == nameR
            case (.pinVerified(let pinVerifiedL, _, _), .pinVerified(let pinVerifiedR, _, _)):
                return pinVerifiedL == pinVerifiedR
            case (.ignore, .ignore):
                return true
            default:
                return false
        }
    }
}

extension MainAlbumViewModelEvents: MapsToTaskEvent {
    public func toNetworkEvent() -> TaskUIEvent<()>? {
        switch self {
            case .albumCreated(let event, _):
                return event.ignoreResponse()
            case .pinVerified(let event, _, _):
                return event.ignoreResponse()
            case .ignore:
                return nil
        }
    }
}

protocol MainAlbumViewModelType: TaskViewModel {
    var keyChainHelper: KeyChainHelperType { get  }
    var events: PublishSubject<MainAlbumViewModelEvents> { get }
    var deviceSanctityManager: DeviceSanctityType { get }
    var albumSectionModel: BehaviorRelay<AlbumSectionModel> { get }
    var sharedRealm: AlbumRealmDB { get }
}

class MainAlbumViewModel: MainAlbumViewModelType {

    var deviceSanctityManager: DeviceSanctityType
    var keyChainHelper: KeyChainHelperType
    var events: PublishSubject<MainAlbumViewModelEvents> = PublishSubject<MainAlbumViewModelEvents>()

    var albums: BehaviorRelay<[Album]> = BehaviorRelay<[Album]>(value: [])
    var albumSectionModel = BehaviorRelay(value: AlbumSectionModel(items: []))
    let selectedAlbum = PublishSubject<Album>()
    var sharedRealm: AlbumRealmDB

    var disposeBag = DisposeBag()

    init(deviceSanctityManager: DeviceSanctityType,
         keyChainHelper: KeyChainHelperType,
         sharedRealm: AlbumRealmDB = RealmDB.shared) {
        self.sharedRealm = sharedRealm
        self.deviceSanctityManager = deviceSanctityManager
        self.keyChainHelper = keyChainHelper
        setupEvents()
        setupBindAlbums()
        fetchSavedAlbums()
    }

    private func setupEvents() {
        self.events
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] (event) in
                switch event {
                    case .albumCreated(.succeeded(let encryptedData), let name):
                        let albums = [Album(name: name,
                                           number: (self?.albums.value.count ?? 0) + 1,
                                           pin: encryptedData,
                                           images: nil)]
                        self?.save(albums: albums)
                        var updatedAlbums = (self?.albums.value ?? [])
                        updatedAlbums.append(contentsOf: albums)
                        self?.albums.accept(updatedAlbums)
                    case .pinVerified(.succeeded(let decryptedData), let album, let pin):
                        if let decryptedPin = String(data: decryptedData, encoding: .utf8), decryptedPin == pin {
                            self?.selectedAlbum.onNext(album)
                        }
                    default:
                        break
                }
            })
            .disposed(by: disposeBag)
    }

    private func setupBindAlbums() {

        self.albums.asDriver().drive(onNext: { [weak self] _ in
            guard let self = self else { return }
            let albumCellModels = self.getAlbumCellModels()
            self.albumSectionModel.accept(AlbumSectionModel(header: "",
                                                        items: albumCellModels))
        }).disposed(by: disposeBag)
    }

    func fetchSavedAlbums() {
        self.albums.accept(sharedRealm.fetchAlbums())
    }

    func getAlbumCellModels() -> [AlbumCellModel] {
        var albumCellModels = [AlbumCellModel]()

        for (album) in self.albums.value {
            let albumCellModel = AlbumCellModel(album: album)
            albumCellModels.append(albumCellModel)
        }
        return albumCellModels
    }

    func createAlbumFor(name: String, pin: String) {

        self.keyChainHelper.encrypt(inputData: pin.data(using: .utf8)!)
            .subscribe(onNext: { [weak self] (event) in
                self?.events.onNext(.albumCreated(event, name: name))
        }).disposed(by: disposeBag)
    }

    func save(albums: [Album])  {
        self.sharedRealm.saveAlbum(albums: albums)
    }

    func verifyPin(album: Album) -> UIAlertController {
        let alertController = UIAlertController(title: "Add Correct Pin", message: "Please Enter the  correct pin for the album", preferredStyle: UIAlertController.Style.alert)
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Enter Pin for the Album"
        }
        let saveAction = UIAlertAction(title: "Submit", style: UIAlertAction.Style.default, handler: { [weak self] alert -> Void in
            let firstTextField = alertController.textFields![0] as UITextField
            guard let self = self,
                  let pin = firstTextField.text,
                  !pin.isEmpty else { return }
            self.keyChainHelper.decrypt(encryptedData: album.pin!)
                .subscribe(onNext: { [weak self] (event) in
                    self?.events.onNext(.pinVerified(event, album: album, pin: pin))
                })
                .disposed(by: self.disposeBag)

        })
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: {
                                            (action : UIAlertAction!) -> Void in })

        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)

        return alertController

    }
    
}
