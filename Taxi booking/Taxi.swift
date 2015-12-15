//
//  Taxi.swift
//  Taxi booking
//
//  Created by Pierre on 15/12/15.
//  Copyright © 2015 Pierre. All rights reserved.
//

import Foundation

struct Position {
    var latitude: Float
    var longitude: Float
}

struct Driver {
    var departement: String
    var professionalLicence: String
}

struct Vehicle {
    //var characteristics: NSSet
    var color: String?
    var licencePlate: String?
    var constructor: String
    var model: String?
    var nbSeats: String?
}

class Taxi: NSObject {
    
    var id: String = ""
    var lastUpdate: String = "NR"
    var crowflyDistance: String?
    var rating: String = "NR"
    var status: String = "NR"
    var position: Position
    var driver: Driver
    var vehicle: Vehicle
    
    init(position: Position, driver: Driver, vehicle: Vehicle){
        self.position = position
        self.driver = driver
        self.vehicle = vehicle
    }
}
