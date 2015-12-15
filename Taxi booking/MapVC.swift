//
//  MapVC.swift
//  Taxi booking
//
//  Created by Pierre on 15/12/15.
//  Copyright © 2015 Pierre. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import SwiftyJSON

class MapVC: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    let locationManager = CLLocationManager()
    var regionRectApplied = false
    let urlAllTaxis = "https://guarded-ocean-4869.herokuapp.com/api/taxis/"
    let urlToGetTaxi = "https://guarded-ocean-4869.herokuapp.com/api/reservation/taxi="
    var idSelected: String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Location settings */
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
        /* End of location settings */
        
        //refreshData()
        
        let url = NSURL(string: "\(urlAllTaxis)lat=1&lon=2")
        let request = NSMutableURLRequest(URL: url!)
        
        // UNCOMMENT to use the real web service, it's the necessary headers for
        /*request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("2", forHTTPHeaderField: "X-VERSION")
        request.setValue("46f06ed1-0124-4edc9283-0df69a604ef4", forHTTPHeaderField: "X-API-KEY")*/
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {(response, data, error) in
            self.parseJSONForTaxis(data!)
        }
        
        
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if (annotation is MKUserLocation) {
            return nil
        } else{
            let taxiPin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "current")
            taxiPin.canShowCallout = true
            
            let bookButton = UIButton()
            bookButton.frame.size.width = 90
            bookButton.frame.size.height = 44
            bookButton.setTitle("Réserver", forState: .Normal)
            bookButton.backgroundColor = UIColor.blueColor()
            bookButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
            
            taxiPin.rightCalloutAccessoryView = bookButton
            
            return taxiPin
        }
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let url = NSURL(string: "\(urlToGetTaxi)\(self.idSelected!)")
        let request = NSMutableURLRequest(URL: url!)
        
        // UNCOMMENT to use the real web service, it's the necessary headers for
        /*request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("2", forHTTPHeaderField: "X-VERSION")
        request.setValue("46f06ed1-0124-4edc9283-0df69a604ef4", forHTTPHeaderField: "X-API-KEY")*/
        
        print(url!.absoluteString)
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {(response, data, error) in
            self.parseJSONForTaxi(data!)
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if(!regionRectApplied){
            regionRectApplied = true
            //mapView.region = MKCoordinateRegionMakeWithDistance(manager.location!.coordinate, 2000, 2000);
        }
    }
    
    @IBAction func showUserLocation() {
        
        var region = MKCoordinateRegion()
        region.center = mapView.userLocation.location!.coordinate
        region = MKCoordinateRegionMakeWithDistance(region.center, 2000,2000);
        mapView.setRegion(region, animated: true)
    }
    
    /**
    *   When refresh button is pressed, we send the request to get all taxis
    */
    @IBAction func refreshClicked(sender: UIBarButtonItem) {
        let url = NSURL(string: "\(urlAllTaxis)lat=1&lon=2")
        let request = NSMutableURLRequest(URL: url!)
        
        // UNCOMMENT to use the real web service, it's the necessary headers for
        /*request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("2", forHTTPHeaderField: "X-VERSION")
        request.setValue("46f06ed1-0124-4edc9283-0df69a604ef4", forHTTPHeaderField: "X-API-KEY")*/
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {(response, data, error) in
            self.parseJSONForTaxis(data!)
        }
    }
    
    /**
    *   Browsing the json, and add the annotation on the map
    */
    func parseJSONForTaxis(data: NSData){
        
        let readableJSON = JSON(data: data)
        
        for i in 0...readableJSON["data"].count{
            let taxi = readableJSON["data"][i]
            //print(taxi)
            let car = taxi["vehicle"]
            let seatNumber = car["nb_seats"]
            let carBrand = car["constructor"]
            let carModel = car["model"]
            let carColor = car["color"]
            let rating = taxi["rating"]
            let free = taxi["free"]
            let lat = taxi["position"]["lat"]
            let long = taxi["position"]["lon"]
            print(taxi["id"].stringValue)
            //self.idSelected = taxi["id"].stringValue
            self.idSelected = "MJbqzdh"
            
            let taxiLocation = CLLocationCoordinate2DMake(CLLocationDegrees(lat.doubleValue), CLLocationDegrees(long.doubleValue))
            
            let taxiPin = MKPointAnnotation()
            taxiPin.coordinate = taxiLocation
            taxiPin.title = "\(carBrand) \(carModel) \(carColor)"
            taxiPin.subtitle = "\(seatNumber) place(s) dispo. - Note : \(rating)"
            
            
            mapView.addAnnotation(taxiPin)
        }
    }
    
    func parseJSONForTaxi(data: NSData){
        let readableJSON = JSON(data: data)
        let successBooking = readableJSON["result"].boolValue
        
        if(successBooking){
            displayAlert("Réservation terminée !", message: "Votre taxi vient d'être notifié de votre réservation, il arrivera d'ici peu", button: "Merci !")
        } else{
            displayAlert("Désolé...", message: "Ce taxi ne peut vous prendre en charge, vous pouvez essayer d'autres taxis", button: "Ça marche")
        }
    }
    
    /**
     * Display a pop-up with different parameters.
     * Need a title, a message, and a label for the dismiss button
     */
    func displayAlert(title: String, message: String, button: String){
        let alert = UIAlertView()
        alert.title = title
        alert.message = message
        alert.addButtonWithTitle(button)
        alert.show()
    }
}