//
//  MapVCBottomExtension.swift
//  Walkthrough
//
//  Created by Danielle Wang on 2020-08-13.
//  Copyright © 2020 Mappedin. All rights reserved.
//

import UIKit

extension MapViewController {
    func addBottomSheetView(restaurantName: String) {
        let bottomSheetVC = BottomSheetViewController()
        bottomSheetVC.restaurantName = restaurantName
        bottomSheetVC.menuDictionary = menuDictionary
        
        self.addChild(bottomSheetVC)
        self.view.addSubview(bottomSheetVC.view)
        bottomSheetVC.didMove(toParent: self)
        
        let width = view.frame.width
        let height = view.frame.height
        bottomSheetVC.view.frame = CGRect(x: 0, y: view.frame.maxY, width: width, height: height)
    }
}
