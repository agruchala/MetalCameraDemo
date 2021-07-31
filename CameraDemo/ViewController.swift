//
//  ViewController.swift
//  CameraDemo
//
//  Created by Artur Gruchała on 31/07/2021.
//

import UIKit

class ViewController: UIViewController {
    
    let cameraController = CameraController()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        cameraController.prepare { _ in
            try? self.cameraController.displayPreview(on: self.view)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
}

