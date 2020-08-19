//
//  BottomSheetViewController.swift
//  Walkthrough
//
//  Created by Danielle Wang on 2020-08-13.
//  Copyright © 2020 Mappedin. All rights reserved.
//

import UIKit
import VenueNextCore
import VenueNextCoreUI
import VenueNextOrderUI
import VenueNextLegacy
import VenueNextPayment
import VenueNextWalletUI
import VenueNextAnalytics
import VenueNextOrderData
import VenueNextWalletData
import VenueNextOrderService
import VenueNextWalletService
import VenueNextNetworkService

enum BottomSheetState {
    case expanded
    case normal
}

class BottomSheetViewController: UIViewController {
    
    var state: BottomSheetState = .normal
    var prepared = false
    
    var restaurantName: String = "Restaurant"
    var descriptionText: String = "Description"
    
    var menuDictionary: NSDictionary? = nil
    
    @IBOutlet weak var restaurantLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let gesture = UIPanGestureRecognizer.init(target: self, action: #selector(BottomSheetViewController.panGesture))
        view.addGestureRecognizer(gesture)
        
        let tap = UITapGestureRecognizer(target: self, action: nil)
        view.addGestureRecognizer(tap)
        
        restaurantLabel.text = restaurantName
        descriptionLabel.text = descriptionText
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prepareBackgroundView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        UIView.animate(withDuration: 0.3) { [weak self] in
            let frame = self?.view.frame
            let yComponent = UIScreen.main.bounds.height - 150
            self?.view.frame = CGRect(x: 0, y: yComponent, width: frame!.width, height:
                frame!.height)
        }
    }
    
    func prepareBackgroundView() {
        if !prepared {
            let blurEffect: UIBlurEffect
            if #available(iOS 13.0, *) {
                blurEffect = UIBlurEffect(style: .systemThinMaterialLight)
            } else {
                blurEffect = UIBlurEffect(style: .extraLight)
            }
            let visualEffect = UIVisualEffectView(effect: blurEffect)
            let bluredView = UIVisualEffectView(effect: blurEffect)
            bluredView.contentView.addSubview(visualEffect)
            
            visualEffect.frame = UIScreen.main.bounds
            bluredView.frame = UIScreen.main.bounds
            
            view.insertSubview(bluredView, at: 0)
            prepared = true
        }
    }
    
    @objc func panGesture(recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self.view)
        let y = self.view.frame.minY + translation.y
        self.view.frame = CGRect(x: 0, y: y, width: view.frame.width, height: view.frame.height)
        recognizer.setTranslation(CGPoint.zero, in: self.view)
        if recognizer.state == .ended {
            if recognizer.velocity(in: self.view).y < 0 {
                swipeUp()
            } else {
                swipeDown()
            }
        }
    }
    
    func swipeUp() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            let frame = self?.view.frame
            let navigationBarHeight = 180 + (self?.navigationController?.navigationBar.frame.height ?? 0)
            self?.view.frame = CGRect(x: 0, y: UIScreen.main.bounds.minY + navigationBarHeight, width: frame!.width, height:
                frame!.height)
        }
        state = .expanded
    }
    
    func swipeDown() {
        switch state {
        case .normal:
            if let parent = parent as? MapViewController {
                parent.selectedRestaurant = nil
            }
            dismissVC()
        case .expanded:
            UIView.animate(withDuration: 0.3) { [weak self] in
                let frame = self?.view.frame
                let yComponent = UIScreen.main.bounds.height - 150
                self?.view.frame = CGRect(x: 0, y: yComponent, width: frame!.width, height:
                    frame!.height)
            }
            state = .normal
        }
    }
    
    func dismissVC() {
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
    
    
    @IBAction func didTapSeeMenu(_ sender: Any) {
//        navigationController?.pushVNRvCList(for: [.food, .merchandise, .experience], animated: true)
        if let menuDictionary = menuDictionary, let menuUUID = menuDictionary[restaurantName] as? String {
            navigationController?.pushVNMenu(for: menuUUID, productType: .food, animated: true)
        } else {
            navigationController?.pushVNRvCList(for: [.food], animated: true)
        }
       
    }
}
