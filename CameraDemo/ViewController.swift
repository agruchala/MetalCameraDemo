//
//  ViewController.swift
//  CameraDemo
//
//  Created by Artur Gruchała on 31/07/2021.
//

import UIKit

class ViewController: UIViewController {
    
    let cameraController = FilteringCameraController()

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraController.prepareCamera(with: self.view)
        cameraController.startCamera()
    }
}

