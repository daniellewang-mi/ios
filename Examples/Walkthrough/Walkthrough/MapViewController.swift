//
//  MapViewController.swift
//  Walkthrough
//
//  Created by Danielle Wang on 2020-08-11.
//  Copyright © 2020 Mappedin. All rights reserved.
//

import UIKit
import Mappedin
import CoreLocation

// A class is needed to control the behavior of the MapView
class MapViewController: UIViewController {
    @IBOutlet var mapView: MapView! {
        didSet {
            mapView.delegate = self
            mapView.storeLablesDefaultColor = .black
            mapView.storeLabelsEnable = true
        }
    }
    // This is important, The Venue's will return children from many calls, all
    // of these children contain a link back to the parent, this is maintained
    // as a weak link and dropping the parent will cause the entire
    // data structure to drop
    var venue: Venue?
    var centeredCamera = false
    
    var restaurants = [Location]()
    var menuDictionary: NSDictionary? = nil
    var selectedRestaurant: Polygon? = nil {
        willSet(nextRestaurant) {
            for child in children {
                if let child = child as? BottomSheetViewController {
                    child.dismissVC()
                }
            }
            if let selectedRestaurant = selectedRestaurant {
                mapView.setColor(of: selectedRestaurant, to: selectedRestaurant.defaultColor, over: 0.6)
            }
            if let nextRestaurant = nextRestaurant {
                mapView.setColor(of: nextRestaurant, to: .systemGreen, over: 0.6)
                mapView.frame(nextRestaurant, padding: 20, heading: mapView.cameraHeading, tilt: Float.pi/4, over: 0.6)
            }
        }
    }
    
    override func viewDidLoad() {
        service!.getVenues()
        .onComplete { venues in
            let venue = venues.filter { $0.slug == "miami-dolphins-stadium" }.first
            if let venue = venue {
                self.loadVenue(venue: venue)
            }
            self.initLocation()
        }
        if let path = Bundle.main.path(forResource: "Menus", ofType: "plist") {
           menuDictionary = NSDictionary(contentsOfFile: path)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.topItem?.title = "RESTAURANT MAP"
    }
    
    // load a venue from the Mappedin server into this view
    func loadVenue(venue: VenueListing) {
        // This will fetch the venue from our API servers, it completes in an
        // asynchronous way. So might need some form of synchronization if
        // your logic is fancier then what is shown.
        //
        // Note: The callback `onComplete` or `OnError` will only execute on
        // the UI thread. this is done as a convince to the API users.
        service!.getVenue(venue).onComplete { venue in
            // pin the venue
            self.venue = venue

            // The venue can hold 1 to any number of maps, but to keep this simple
            // we are only going to use the first map.
            let map = self.venue!.maps.first!

            // this will choose which map you would like to show in the viewport
            self.mapView.setMap(map)

            // this will project the screen in such a way that the entire map
            // is clearly in frame.
            self.mapView.frame(Coordinate(location: CLLocationCoordinate2D(latitude: 25.957966, longitude: -80.238865), map: map), padding: 100, heading: map.heading + Float.pi/2, tilt: Float.pi/4, over: 1)
            
            self.filterRestaurants()
            
            self.labelRestaurants()
            
            self.animateRestaurants()
            
            self.maps = venue.maps.sorted(by: { (map1, map2) -> Bool in
                map1.floor < map2.floor
            })
        }
    }
    
    // MARK: - Restaurants
    var timer: Timer?
    var restaurantsColored = false
    
    func filterRestaurants() {
        guard let venue = venue else { return }
        restaurants.append(contentsOf: venue.locations.filter({ (location) -> Bool in
            location.type == "food"
        }))
        print(restaurants.map { $0.name })
    }
    
    func labelRestaurants() {
        for restaurant in self.restaurants {
            for polygon in restaurant.polygons {
                let label = UILabel()
                label.sizeToFit()

                label.layer.shadowColor = UIColor.white.cgColor
                label.layer.shadowRadius = 1.0
                label.layer.shadowOpacity = 1.0
                label.layer.shadowOffset = CGSize.zero
                label.layer.masksToBounds = false
                
                let strokeTextAttributes: [NSAttributedString.Key : Any] = [
//                    .strokeColor : UIColor.white,
                    .foregroundColor : UIColor.black,
                    .strokeWidth : -2.0,
                    .font : UIFont.boldSystemFont(ofSize: 10)
                    ]

                label.attributedText = NSAttributedString(string: restaurant.name, attributes: strokeTextAttributes)
                self.mapView.add(TextOverlay(position: polygon.entrances.first!, label: label))
            }
        }
    }
    
    func animateRestaurants() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            var color = UIColor(hexString: "#dcedd5")
            if self.restaurantsColored {
                color = .white
                self.restaurantsColored = false
            } else {
                self.restaurantsColored = true
            }
            for restaurant in self.restaurants {
                for polygon in restaurant.polygons {
                    guard polygon != self.selectedRestaurant else {
                        continue
                    }
                    self.mapView.setColor(of: polygon, to: color, over: 1.0)
                }
            }
        }
    }
    
    // MARK: - Location Display
    
    // Map elements necessary for displaying user location, paths, and direction nodes
    var cylinder: Cylinder?
    var arrow: Prism?
    var path: Path?
    var directionPoints = [Cylinder]()
    
    // Keeps track of the users current position on the map
    var isUsingUserLocation = false
    var startingLocation: Navigatable?
    var destinationLocation: Navigatable?
    var iAmHereCoordinate: Coordinate?
    var iAmHereHeading: Radians = 0
    var distanceTestCoordinate: Coordinate?
    
    // SCALE is used to scale elements added to the map such as paths.
    // Depending on the size of your venue you may wish to increase or decrease this scale
    let SCALE: Float = 0.5;
    // These values will be scaled by the scale set above on viewDidLoad()
    // These values are in meters
    var TURN_POINT_HEIGHT:Float = 3.6
    var TURN_POINT_DIAMETER:Float = 1.5
    var PATH_WIDTH:Float = 0.8
    var PATH_HEIGHT:Float = 3.5
    var I_AM_HERE_DIAMETER:Float = 5
    var I_AM_HERE_HEIGHT:Float = 5
    var I_AM_HERE_ARROW_HEIGHT: Float = 5.1
    var I_AM_HERE_ARROW_COLOR = UIColor.white
    var I_AM_HERE_CYLINDER_COLOR = UIColor.systemGreen
    // Defines points to draw the user arrow
    var I_AM_HERE_ARROW_POINTS = [
        Vector2(0,1.2),
        Vector2(1.0,-1.2),
        Vector2(0,-0.8),
        Vector2(-1.0,-1.2)
    ]
    
    func initLocation() {
        LocationService.shared.delegate = self
        LocationService.shared.startUpdatingLocation()
        LocationService.shared.startUpdatingHeading()
    }
    
    // MARK: - UI
    
    var maps: [Map] = []
    @IBOutlet weak var levelUpButton: UIButton!
    @IBOutlet weak var levelDownButton: UIButton!
    @IBOutlet weak var recenterButton: UIButton!
    
    @IBAction func didTapLevelUp(_ sender: Any) {
        guard let activeMap = mapView.activeMap else {
            return
        }
        let index: Int? = maps.firstIndex(of: activeMap)
        if index != nil && index! + 1 < maps.count {
            let newMap = maps[index! + 1]
            mapView.setMap(newMap)
            levelDownButton.backgroundColor = .black
        }
        if index! + 2 >= maps.count {
            levelUpButton.backgroundColor = UIColor(hexString: "#000000", alpha: 0.5)
        }
        selectedRestaurant = nil
        manipulatedCamera()
    }
    
    @IBAction func didTapLevelDown(_ sender: Any) {
        guard let activeMap = mapView.activeMap else {
            return
        }
        let index: Int? = maps.firstIndex(of: activeMap)
        if index != nil && index! - 1 >= 0 {
            let newMap = maps[index! - 1]
            mapView.setMap(newMap)
            levelUpButton.backgroundColor = .black
        }
        if index! - 2 < 0 {
            levelDownButton.backgroundColor = UIColor(hexString: "#000000", alpha: 0.5)
        }
        selectedRestaurant = nil
        manipulatedCamera()
    }
    
    @IBAction func didTapRecenter(_ sender: Any) {
//        guard let currentPosition = self.iAmHereCoordinate else {
//                return
//        }
//        mapView.frame(currentPosition, padding: 50, heading: mapView.cameraHeading, tilt: Float.pi/4, over: 0.6)
        centeredCamera = true
        recenterButton.backgroundColor = UIColor(hexString: "#000000", alpha: 0.5)
        selectedRestaurant = nil
    }
}
