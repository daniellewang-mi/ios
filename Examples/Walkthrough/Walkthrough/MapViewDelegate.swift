//
//  MapViewDelegate.swift
//  Walkthrough
//
//  Created by Danielle Wang on 2020-08-11.
//  Copyright © 2020 Mappedin. All rights reserved.
//

import Mappedin
import CoreLocation

extension MapViewController: MapViewDelegate {
    func tapped(_ mapView: MapView, polygon: Polygon) -> Bool {
        guard !polygon.locations.isEmpty else {
            selectedRestaurant = nil
            return false
        }
        guard restaurants.contains(polygon.locations[0]) else {
            selectedRestaurant = nil
            return false
        }
        
        selectedRestaurant = polygon
        manipulatedCamera()
        
        addBottomSheetView(restaurantName: selectedRestaurant!.locations[0].name)

        return true
    }
    
    func tapped(_ mapView: MapView, clCoordinate: CLLocationCoordinate2D) {
        return
    }
    
    func manipulatedCamera() {
        centeredCamera = false
        recenterButton.backgroundColor = .black
    }
}
