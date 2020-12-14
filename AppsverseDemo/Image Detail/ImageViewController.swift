//
//  ImageViewController.swift
//  AppsverseDemo
//
//  Created by jeet_gandhi on 14/12/20.
//

import UIKit

class ImageViewController: UIViewController {

    var image: UIImage = UIImage()
    @IBOutlet weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = image
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
