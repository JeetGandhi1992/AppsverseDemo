//
//  MainAlbumViewController.swift
//  AppsverseDemo
//
//  Created by jeet_gandhi on 13/12/20.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class MainAlbumViewController: UIViewController, TaskViewController {

    var alertPresenter: AlertPresenterType = AlertPresenter()
    var loadingSpinner: UIActivityIndicatorView = UIActivityIndicatorView(style: .large)
    var viewModel: MainAlbumViewModel!
    var dataSource: RxCollectionViewSectionedReloadDataSource<AlbumSectionModel>?

    var disposeBag: DisposeBag = DisposeBag()

    @IBOutlet weak var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLoadingSpinner()
        setupNetworkingEventsUI()
        setupAddButton()
        setupCollectionView()
        setupAlbums()
    }

    private func setupAlbums() {
        self.rx.viewWillAppear
            .subscribe(onNext: { [weak self] _ in
                self?.viewModel.fetchSavedAlbums()
            })
            .disposed(by: disposeBag)
    }

    private func setupCollectionView() {

        collectionView.register(UINib(nibName: "AlbumCollectionViewCell",
                                      bundle: .main),
                                forCellWithReuseIdentifier: "AlbumCollectionViewCell")

        collectionView.delegate = self

        let dataSource = albumViewDataSource()
        self.dataSource = dataSource

        viewModel.albumSectionModel
            .map { [$0] }
            .bind(to: collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)


        self.collectionView.rx
            .modelSelected(AlbumCellModel.self)
            .map { $0.album }
            .subscribe(onNext: { [unowned self] (album) in
                let alertController = self.viewModel.verifyPin(album: album)
                self.present(alertController, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }

    func setupAddButton() {
        let refresh = UIImage(systemName: "plus.circle.fill")
        let refreshBarButton = UIBarButtonItem(image: refresh, style: .plain, target: self, action: #selector(MainAlbumViewController.addButtonClicked))
        self.navigationItem.rightBarButtonItem  = refreshBarButton
    }

    @objc func addButtonClicked(sender : AnyObject) {
        let alertController = UIAlertController(title: "Add New Album", message: "Please Enter the album name and pin", preferredStyle: UIAlertController.Style.alert)
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Enter Album Name"
        }
        let saveAction = UIAlertAction(title: "Save", style: UIAlertAction.Style.default, handler: { [unowned self] alert -> Void in
            let firstTextField = alertController.textFields![0] as UITextField
            let secondTextField = alertController.textFields![1] as UITextField
            guard let name = firstTextField.text,
                  !name.isEmpty,
                  let pin = secondTextField.text,
                  !pin.isEmpty else { return }
            var albums = self.viewModel.albums.value
            albums = albums.filter { (album: Album) -> Bool in
                album.name == name
            }
            if albums.isEmpty {
                self.viewModel.createAlbumFor(name: name, pin: pin)
            } 


        })
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: {
                                            (action : UIAlertAction!) -> Void in })
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Enter Pin"
        }

        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true, completion: nil)
    }

}

extension MainAlbumViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (collectionView.frame.width/2) - 20,
                      height: 200)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        10
    }
}


extension MainAlbumViewController {

    private func albumViewDataSource() -> RxCollectionViewSectionedReloadDataSource<AlbumSectionModel> {
        return RxCollectionViewSectionedReloadDataSource<AlbumSectionModel>(
            configureCell: configureAlbumCollectionViewCell
        )
    }

    private func configureAlbumCollectionViewCell(_: CollectionViewSectionedDataSource<AlbumSectionModel>,
                                                     collectionView: UICollectionView,
                                                     indexPath: IndexPath,
                                                     albumCellModel: AlbumCellModel) -> UICollectionViewCell {
        guard let cell = collectionView
                .dequeueReusableCell(withReuseIdentifier: "AlbumCollectionViewCell",
                                     for: indexPath) as? AlbumCollectionViewCell else {
            return UICollectionViewCell()
        }
        cell.title.text =  " Tap on \(albumCellModel.album.name ?? "") to view the images"
        cell.deleteButton
            .rx.tap
            .throttle(RxTimeInterval.seconds(1), scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [unowned self] in
                let alertController = self.viewModel.verifyPin(album: albumCellModel.album,to: true)
                self.present(alertController, animated: true, completion: nil)
            })
            .disposed(by: cell.disposeBag)
        return cell
    }


}
