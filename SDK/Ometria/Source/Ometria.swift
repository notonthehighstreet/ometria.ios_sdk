//
//  Ometria.swift
//  Ometria
//
//  Created by Cata on 7/10/20.
//  Copyright © 2020 Cata. All rights reserved.
//

import Foundation
import UIKit

open class Ometria: NSObject, UNUserNotificationCenterDelegate {
    
    open var apiToken: String
    private var config: OmetriaConfig
    static var instance: Ometria?
    private let automaticPushTracker = AutomaticPushTracker()
    private let automaticLifecycleTracker = AutomaticLifecycleTracker()
    private let automaticScreenViewsTracker = AutomaticScreenViewsTracker()
    private let notificationHandler = NotificationHandler()
    private let eventHandler: EventHandler
    
    @discardableResult
    open class func initialize(apiToken: String, config: OmetriaConfig = OmetriaConfig()) -> Ometria {
        let ometria = Ometria(apiToken: apiToken, config: config)
        instance = ometria
        ometria.handleApplicationLaunch()
        return ometria
    }
    
    open class func sharedInstance() -> Ometria {
        guard instance != nil else {
            assert(false, "You are not allowed to call the sharedInstance() method before calling initialize(apiToken:preferences:).")
        }
        return instance!
    }
    
    init(apiToken: String, config: OmetriaConfig) {
        self.config = config
        self.apiToken = apiToken
        self.eventHandler = EventHandler(flushLimit: config.flushLimit)
        super.init()
        
        isLoggingEnabled = config.isLoggingEnabled
        // didSet not called from initializer. setLoggingEnabled is force called to remedy that.
        setLoggerEnabled(isLoggingEnabled)
        
      
        if config.automaticallyTrackNotifications {
            automaticPushTracker.startTracking()
        }
        if config.automaticallyTrackAppLifecycle {
            automaticLifecycleTracker.startTracking()
        }
        if config.automaticallyTrackScreenListing {
            automaticScreenViewsTracker.startTracking()
        }
    }
    
    open var isLoggingEnabled: Bool = false {
        didSet {
            setLoggerEnabled(isLoggingEnabled)
        }
    }
    
    func setLoggerEnabled(_ enabled: Bool) {
        if enabled {
            Logger.enableLevel(.debug)
            Logger.enableLevel(.info)
            Logger.enableLevel(.warning)
            Logger.enableLevel(.error)

            Logger.debug(message: "Logger Enabled")
        } else {
            Logger.debug(message: "Logger Disabled")

            Logger.disableLevel(.debug)
            Logger.disableLevel(.info)
            Logger.disableLevel(.warning)
            Logger.disableLevel(.error)
        }
    }
    
    // MARK: - Application launch
    
    private func handleApplicationLaunch() {
        OmetriaDefaults.lastLaunchDate = Date()
        if OmetriaDefaults.isFirstLaunch {
            handleAppInstall()
        }
        
        trackAppLaunchedEvent()
    }
    
    private func handleAppInstall() {
        OmetriaDefaults.isFirstLaunch = false
        var installationID = OmetriaDefaults.installationID
        if installationID == nil {
            installationID = generateInstallationID()
            OmetriaDefaults.installationID = installationID
        }
        trackAppInstalledEvent()
    }
    
  
    private func generateInstallationID() -> String {
        let installationID = UUID().uuidString
        return installationID
    }
    
    // MARK: - Event Tracking
    
    
    
    private func trackEvent(type: OmetriaEventType, data: [String: Codable] = [:]) {
        eventHandler.processEvent(type: type, data: data)
    }
    
    // MARK: Application Related Events
    
    func trackAppInstalledEvent() {
        trackEvent(type: .appInstalled)
    }
    
    func trackAppLaunchedEvent() {
        trackEvent(type: .appLaunched)
    }
    
    func trackAppBackgroundedEvent() {
        trackEvent(type: .appBackgrounded)
        eventHandler.flushEvents()
    }
    
    func trackAppForegroundedEvent() {
        trackEvent(type: .appForegrounded)
        eventHandler.flushEvents()
        notificationHandler.processDeliveredNotifications()
    }
    
    open func trackScreenViewedEvent(screenName: String, additionalInfo:[String: Codable] = [:]) {
        var data = additionalInfo
        data["page"] = screenName
        trackEvent(type: .screenViewed, data: data)
    }
    
    open func trackProfileIdentifiedEvent(email: String) {
        trackEvent(type: .profileIdentified, data: ["email": email])
    }
    
    open func trackProfileIdentifiedEvent(customerId: String) {
        trackEvent(type: .profileIdentified, data: ["customerId": customerId])
    }
    
    open func trackProfileDeidentifiedEvent() {
        trackEvent(type: .profileDeidentified)
    }
    
    // MARK: Product Related Events
    
    open func trackProductViewedEvent(productId: String) {
        trackEvent(type: .productViewed, data: ["productId": productId])
    }
    
    open func trackProductCategoryViewedEvent(category: String) {
        trackEvent(type: .productCategoryViewed, data: ["category": category])
    }
    
    open func trackWishlistAddedToEvent(productId: String) {
        trackEvent(type: .wishlistAddedTo, data: ["productId": productId])
    }
    
    open func trackWishlistRemovedFromEvent(productId: String) {
        trackEvent(type: .wishlistRemovedFrom, data: ["productId": productId])
    }
    
    open func trackBasketViewedEvent() {
        trackEvent(type: .basketViewed)
    }
    
    open func trackBasketUpdatedEvent(basket: OmetriaBasket) {
        trackEvent(type: .basketUpdated, data: ["basket": basket])
    }
    
    open func trackOrderCompletedEvent(orderId: String, basket: OmetriaBasket) {
        trackEvent(type: .orderCompleted, data: ["orderId": orderId,
                                                 "basket": basket])
    }
    
    // MARK: Notification Related Events
    
    open func trackPushTokenRefreshedEvent(pushToken: String) {
        trackEvent(type: .pushTokenRefreshed, data: ["pushToken": pushToken])
        eventHandler.flushEvents()
    }
    
    open func trackNotificationReceivedEvent(notificationId: String) {
        trackEvent(type: .notificationReceived, data: ["notificationId": notificationId])
    }
    
    open func trackNotificationInteractedEvent(notificationId: String) {
        trackEvent(type: .notificationInteracted, data: ["notificationId": notificationId])
    }
    
    // MARK: Other Events
    
    open func trackDeepLinkOpenedEvent(link: String, screenName: String) {
        trackEvent(type: .deepLinkOpened, data: ["link": link,
                                                 "page": screenName])
    }
    
    open func trackCustomEvent(customEventType: String, additionalInfo: [String: Codable]) {
        var data = additionalInfo
        data["customEventType"] = customEventType
        trackEvent(type: .custom, data: data)
    }
    
    // MARK: - Flush/Clear
    
    open func flush() {
        eventHandler.flushEvents()
    }
    
    open func clear() {
        eventHandler.clearEvents()
    }
    
    // MARK: - Push notifications
    
    open func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        notificationHandler.handleNotificationResponse(response, withCompletionHandler: completionHandler)
    }
    
    open func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        notificationHandler.handleReceivedNotification(notification, withCompletionHandler: completionHandler)
    }
    
    open func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    }
    
    open func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        
    }
    
    open func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    }
    
}
