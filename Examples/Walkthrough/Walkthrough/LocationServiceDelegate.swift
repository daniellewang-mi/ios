//
//  LocationServiceDelegate.swift
//  Walkthrough
//
//  Created by Danielle Wang on 2020-08-12.
//  Copyright © 2020 Mappedin. All rights reserved.
//

import CoreLocation
import Mappedin

extension MapViewController: LocationServiceDelegate {    

    func addIAmHereOnMap(){
        if (cylinder == nil || self.arrow == nil) && iAmHereCoordinate != nil {
            self.cylinder = Cylinder(position: iAmHereCoordinate!, diameter: I_AM_HERE_DIAMETER, height: I_AM_HERE_HEIGHT, color: I_AM_HERE_CYLINDER_COLOR)
            self.arrow = Prism(position: iAmHereCoordinate!, heading: self.iAmHereHeading, points: self.I_AM_HERE_ARROW_POINTS, height: I_AM_HERE_ARROW_HEIGHT, color: I_AM_HERE_ARROW_COLOR)
        }
        if self.cylinder != nil && self.arrow != nil && iAmHereCoordinate != nil {
            self.mapView.add(self.cylinder!)
            self.mapView.add(self.arrow!)
        }
    }

    func removeIAmHereFromMap(){
        if self.cylinder != nil, self.arrow != nil {
            self.mapView.remove(self.cylinder!)
            self.mapView.remove(self.arrow!)
        }
    }
    
    func moveIAmHere(position:Coordinate, heading:Radians, over:TimeInterval){
        if self.cylinder != nil, self.arrow != nil {
            self.cylinder?.set(position: position, over: over)
            self.arrow?.set(position: position, over: over)
            self.arrow?.set(heading: heading, over: over)
        }
    }

    func updatePath(newDirections: Directions?) {
        guard let directions = newDirections else {
            return
        }
        let newPathPoints = directions.path
        let newPath = Path(points: newPathPoints, width: PATH_WIDTH, height: PATH_HEIGHT, color: .systemGreen)
        mapView.add(newPath)

        if self.path != nil {
            mapView.remove(self.path!)
        }
        self.path = newPath

        var newDirectionPoints = [Cylinder]()
        for dir in directions.instructions {
            newDirectionPoints.append(Cylinder(position: dir.coordinate, diameter: TURN_POINT_DIAMETER, height: TURN_POINT_HEIGHT, color: .white))
        }

        for point in newDirectionPoints {
            mapView.add(point)
        }
        for point in self.directionPoints {
            mapView.remove(point)
        }
        self.directionPoints = newDirectionPoints
    }

    
    // updates the users location on the map
    func updateLocation(currentLocation: CLLocation, locationManager: CLLocationManager) {
        guard let venue = venue else {
            return
        }
        
        if let heading = locationManager.heading?.trueHeading {
            self.iAmHereHeading = Float(-1 * heading * .pi / 180)
        } else {
            self.iAmHereHeading = 0
        }
        
        self.iAmHereCoordinate = Coordinate(location: currentLocation.coordinate, map: venue.maps.first!)
        
        addIAmHereOnMap()
        
        if !isUsingUserLocation {
            isUsingUserLocation = true
        }

        if isUsingUserLocation {
            guard let currentPosition = self.iAmHereCoordinate else {
                    return
            }
            moveIAmHere(position: currentPosition, heading: iAmHereHeading, over: 1)
            
            if centeredCamera {
                mapView.frame(currentPosition, padding: 50, heading: mapView.cameraHeading, tilt: Float.pi/4, over: 0.6)
            }
            
//            if let selectedRestaurant = selectedRestaurant {
//                let directions = currentPosition.directions(to: selectedRestaurant)
//                updatePath(newDirections: directions)
//            }
            
//            if camera == .follow {
//                let angleRads = currentPosition.vector2.angle(to: (path.to.navigatableCoordinates.first?.vector2)!)
//                mapView.frame(
//                    currentPosition,
//                    padding: CAMERA_PADDING,
//                    heading: angleRads,
//                    tilt: PERSPECTIVE_TILT,
//                    over: 1.0)
//            }
        }
    }

    func updateLocationDidFailWithError(error: Error) {
        // Handle errors here
        if CLLocationManager.authorizationStatus() == .denied {
            if self.cylinder != nil,
                self.arrow != nil {
                mapView.remove(cylinder!)
                mapView.remove(arrow!)
                self.cylinder = nil
                self.arrow = nil
            }
            isUsingUserLocation = false
            iAmHereCoordinate = nil
        }
    }
}
