//
//  EventListViewController.swift
//  OmetriaSample
//
//  Created by Cata on 9/1/20.
//  Copyright © 2020 Ometria. All rights reserved.
//

import Foundation
import UIKit
import Ometria


enum EventType: String, CaseIterable {
    case basketUpdated
    case basketViewed
    case orderCompleted
    case productCategoryViewed
    case productViewed
    case wishlistAddedTo
    case wishlistRemovedFrom
    case screenViewedExplicit
    case profileIdentified
    case profileDeidentified
    case custom
}

class EventListViewController: UITableViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return EventType.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath)
        cell.textLabel?.text = EventType.allCases[indexPath.row].rawValue
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let eventType = EventType.allCases[indexPath.row]
        triggerEvent(eventType)
    }
    
    func triggerEvent(_ eventType: EventType) {
        switch eventType {
        
        case .basketUpdated:
            Ometria.sharedInstance().trackBasketUpdatedEvent(basket: createSampleBasket())
        case .basketViewed:
            Ometria.sharedInstance().trackBasketViewedEvent()
        case .orderCompleted:
            Ometria.sharedInstance().trackOrderCompletedEvent(orderId: "sample_order_id", basket: createSampleBasket())
        case .productCategoryViewed:
            Ometria.sharedInstance().trackProductCategoryViewedEvent(category: "sample_category")
        case .productViewed:
            Ometria.sharedInstance().trackProductViewedEvent(productId: "sample_product_id")
        case .wishlistAddedTo:
            Ometria.sharedInstance().trackWishlistAddedToEvent(productId: "sample_product_id")
        case .wishlistRemovedFrom:
            Ometria.sharedInstance().trackWishlistRemovedFromEvent(productId: "sample_product_id")
        case .screenViewedExplicit:
            Ometria.sharedInstance().trackScreenViewedEvent(screenName: "sample_screen_name")
        case .profileIdentified:
            Ometria.sharedInstance().trackProfileIdentifiedEvent(email: "sample@profile.com")
        case .profileDeidentified:
            Ometria.sharedInstance().trackProfileDeidentifiedEvent()
        case .custom:
            Ometria.sharedInstance().trackCustomEvent(customEventType: "custom_event", additionalInfo: ["sampleField": "sampleValue"])
        }
    }
    
    func createSampleBasket() -> OmetriaBasket {
        let myItem = OmetriaBasketItem(productId: "product-1",
                                       sku: "sku-product-1",
                                       quantity: 1,
                                       price: 12.0)
        let myItems = [myItem]
        let myBasket = OmetriaBasket(totalPrice: 12.0, currency: "USD", items: myItems)
        
        return myBasket
    }
}