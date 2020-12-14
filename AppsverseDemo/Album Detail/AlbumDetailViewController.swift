//
//  AlbumDetailViewController.swift
//  AppsverseDemo
//
//  Created by jeet_gandhi on 14/12/20.
//

import UIKit
import RxSwift
import RxCocoa
import PhotosUI
import RxDataSources

class AlbumDetailViewController: UIViewController, TaskViewController {
    

    var alertPresenter: AlertPresenterType = AlertPresenter()
    var loadingSpinner: UIActivityIndicatorView = UIActivityIndicatorView(style: .large)
    var viewModel: AlbumDetailViewModel!
    var dataSource: RxCollectionViewSectionedReloadDataSource<ImageSectionModel>?
    
    var disposeBag: DisposeBag = DisposeBag()

    @IBOutlet weak var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLoadingSpinner()
        setupNetworkingEventsUI()
        setupAddButton()
        setupCollectionView()
    }

    private func setupCollectionView() {

        collectionView.register(UINib(nibName: "AlbumCollectionViewCell",
                                      bundle: .main),
                                forCellWithReuseIdentifier: "AlbumCollectionViewCell")

        collectionView.delegate = self

        let dataSource = imageViewDataSource()
        self.dataSource = dataSource

        viewModel.imageSectionModel
            .map { [$0] }
            .bind(to: collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)


        self.collectionView.rx
            .modelSelected(ImageCellModel.self)
            .map { $0.image }
            .asDriver(onErrorJustReturn: Data())
            .drive(onNext: { [unowned self] (data) in
                self.viewModel.displayImage(data: data)
            })
            .disposed(by: disposeBag)
    }

    func setupAddButton() {
        let refresh = UIImage(systemName: "plus.circle.fill")
        let refreshBarButton = UIBarButtonItem(image: refresh, style: .plain, target: self, action: #selector(AlbumDetailViewController.addButtonClicked))
        self.navigationItem.rightBarButtonItem  = refreshBarButton
    }

    @objc func addButtonClicked(sender : AnyObject) {
        let test = self.viewModel.imagerPickerManager.getPHPickerViewController()
        test.delegate = self
        self.navigationController?.present(test, animated: true, completion: nil)
    }

}


extension AlbumDetailViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (collectionView.frame.width/2) - 20,
                      height: 200)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        10
    }
}


extension AlbumDetailViewController {

    private func imageViewDataSource() -> RxCollectionViewSectionedReloadDataSource<ImageSectionModel> {
        return RxCollectionViewSectionedReloadDataSource<ImageSectionModel>(
            configureCell: configureAlbumCollectionViewCell
        )
    }

    private func configureAlbumCollectionViewCell(_: CollectionViewSectionedDataSource<ImageSectionModel>,
                                                  collectionView: UICollectionView,
                                                  indexPath: IndexPath,
                                                  albumCellModel: ImageCellModel) -> UICollectionViewCell {
        guard let cell = collectionView
                .dequeueReusableCell(withReuseIdentifier: "AlbumCollectionViewCell",
                                     for: indexPath) as? AlbumCollectionViewCell else {
            return UICollectionViewCell()
        }
        cell.title.text = "Tap to View the Image \(indexPath.item + 1)"
        return cell
    }


}

extension AlbumDetailViewController: PHPickerViewControllerDelegate {


    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)


        for result in results {
            result.itemProvider.loadObject(ofClass: UIImage.self, completionHandler: { [unowned self] (object, error) in
                DispatchQueue.main.async { [unowned self] in
                    if let image = object as? UIImage, let imageData = image.pngData() ?? image.jpegData(compressionQuality: 1.0) {
                        self.viewModel.saveImage(imageData: imageData)
                    }
                }
            })
        }
    }
}
