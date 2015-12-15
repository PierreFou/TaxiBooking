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
    var mappingAnnotationTaxi = [MKPointAnnotation: Taxi]()
    var mappingViewAnnotation = [MKAnnotationView: MKPointAnnotation]()
    
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
        
        getAllTaxis()
        
    }
    
    func getAllTaxis(){
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
            let taxiJSON = readableJSON["data"][i]
            
            // vehicle
            let car = taxiJSON["vehicle"]
            var seatNumber = car["nb_seats"]
            let carBrand = car["constructor"]
            let carModel = car["model"]
            let carColor = car["color"]
            let licencePlate = car["licence_plate"]
            
            // If we have a nil in the seat number, we put a 0
            if(seatNumber.null != nil){
                seatNumber = 0
            }
            
            // driver
            let department = taxiJSON["driver"]["departement"]
            let professionalLicence = taxiJSON["driver"]["professional_licence"]
            
            //taxi
            var rating = taxiJSON["rating"]
            let id = taxiJSON["id"]
            let lastUpdate = taxiJSON["last_update"]
            let crowflyDistance = taxiJSON["last_update"]
            let status = taxiJSON["status"]
            
            //position
            let lat = taxiJSON["position"]["lat"]
            let long = taxiJSON["position"]["lon"]
            
            let position = Position(latitude: lat.floatValue, longitude: long.floatValue)
            let driver = Driver(departement: department.stringValue, professionalLicence: professionalLicence.stringValue)
            let vehicle = Vehicle(color: carColor.stringValue, licencePlate: licencePlate.stringValue, constructor: carBrand.stringValue, model: carModel.stringValue, nbSeats: seatNumber.stringValue)
            
            let taxi = Taxi(position: position, driver: driver, vehicle: vehicle)
            taxi.id = id.stringValue
            taxi.rating = rating.stringValue
            taxi.lastUpdate = lastUpdate.stringValue
            taxi.crowflyDistance = crowflyDistance.stringValue
            taxi.status = status.stringValue
            
            /* Adding the pin corresponding to the taxi location */
            let taxiLocation = CLLocationCoordinate2DMake(CLLocationDegrees(lat.doubleValue), CLLocationDegrees(long.doubleValue))
            
            let taxiPin = MKPointAnnotation()
            taxiPin.coordinate = taxiLocation
            
            var title = carBrand.stringValue
            
            if(carModel.null == nil){
                title = "\(title) \(carModel)"
            }
            if(carColor.null == nil){
                title = "\(title) \(carColor)"
            }
            
            taxiPin.title = title
            
            // If we have a nil in the seat number, we put a 0
            if(rating.null != nil){
                rating = "NR"
            }
            
            taxiPin.subtitle = "\(seatNumber) place(s) dispo. - Note : \(rating)"
            
            self.mappingAnnotationTaxi[taxiPin] = taxi
            
            //Adding the pin to the view
            mapView.addAnnotation(taxiPin)
        }
    }
    
    /**
     *  Browsing the json corresponding to a taxing booking.
     *  We will parse the response to know if yes or no we can book the taxi
     *  Display an alert to tell the response to the user
     */
    func parseJSONForTaxi(data: NSData){
        let readableJSON = JSON(data: data)
        let successBooking = readableJSON["result"].boolValue   // Response which tell us if we successfully booked the taxi or no
        
        if(successBooking){
            displayAlert("Réservation terminée !", message: "Votre taxi vient d'être notifié de votre réservation, il arrivera d'ici peu.", button: "Merci !")
        } else{
            displayAlert("Désolé...", message: "Ce taxi ne peut vous prendre en charge, vous pouvez essayer d'autres taxis.", button: "Ça marche")
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
    
    /* Events part */
    
    /**
    *   When user press the current location button, we center the map around his location
    */
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
        getAllTaxis()
    }
    
    /**
     *  Occurs when adding an annotation on the map.
     *  We set all the attributes ("Réserver" button)
     */
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if (annotation is MKUserLocation) {
            return nil
        } else{
            
            let taxiPin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "current")
            taxiPin.canShowCallout = true // Usefull to get the event when the button "Réserver" is pressed
            
            let bookButton = UIButton()
            bookButton.frame.size.width = 90
            bookButton.frame.size.height = 44
            bookButton.setTitle("Réserver", forState: .Normal)
            bookButton.backgroundColor = UIColor.blueColor()
            bookButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
            
            taxiPin.rightCalloutAccessoryView = bookButton
            
            self.mappingViewAnnotation[taxiPin] = (annotation as! MKPointAnnotation)
            
            return taxiPin
        }
    }
    
    /**
     *  Occurs when the user pressed the button "Réserver", on the annotation
     */
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        for (_, taxi) in mappingAnnotationTaxi{
            if(taxi.id == self.idSelected!){
                if(taxi.vehicle.nbSeats! == "0"){
                    displayAlert("Attention ! ", message: "Ce taxi n'a pas de place disponible, veuillez en sélectionner un autre.", button: "Ok")
                    return
                }
            }
        }
        
        let url = NSURL(string: "\(urlToGetTaxi)\(self.idSelected!)")
        let request = NSMutableURLRequest(URL: url!)
        
        // UNCOMMENT to use the real web service, it's the necessary headers for the web service
        /*request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("2", forHTTPHeaderField: "X-VERSION")
        request.setValue("46f06ed1-0124-4edc9283-0df69a604ef4", forHTTPHeaderField: "X-API-KEY")*/
        
        // Send the request and parse the response
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {(response, data, error) in
            self.parseJSONForTaxi(data!)
        }
        
    }
    
    /**
     *  Occurs when the location change
     */
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if(!regionRectApplied){
            regionRectApplied = true
            mapView.region = MKCoordinateRegionMakeWithDistance(manager.location!.coordinate, 2000, 2000);
        }
    }
    
    func mapView(mapViw: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        self.idSelected = mappingAnnotationTaxi[mappingViewAnnotation[view]!]!.id
    }
    
    
}