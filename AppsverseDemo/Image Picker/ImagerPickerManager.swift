//
//  ImagerPickerManager.swift
//  AppsverseDemo
//
//  Created by jeet_gandhi on 13/12/20.
//

import UIKit
import PhotosUI

protocol ImagerPickerManagerType {
    func getPHPickerViewController() -> PHPickerViewController
}


class ImagerPickerManager: ImagerPickerManagerType {

    func getPHPickerViewController() -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = PHPickerFilter.images
        let pickerViewController = PHPickerViewController(configuration: config)
        return pickerViewController
    }


}
