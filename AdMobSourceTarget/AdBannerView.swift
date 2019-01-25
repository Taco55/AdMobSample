//
//  BannerView.swift
//  Meal2day
//
//  Created by Taco Kind on 28-09-18.
//  Copyright © 2018 Taco Kind. All rights reserved.
//
import GoogleMobileAds

@objc public protocol AdBannerViewDelegate{
    @objc optional func adViewDefaultAction(advert: AdBannerView)
    @objc optional func adViewDidLoadAd(advert: AdBannerView)
    @objc optional func adView(advert: AdBannerView, didFailToReceiveAdWithError error: NSError)
    @objc optional func adViewActionShouldBegin(advert: AdBannerView)
    @objc optional func adViewActionDidFinish(advert: AdBannerView)
}

/*
 // Dummy view
 public class AdBannerView: UIView {

 public static let shared = AdBannerView() //Singleton Class
 public var adEnabled: Bool = false
 public var adLoaded: Bool = false
 public var isPresenting = false //Status whether the ad is being viewed
 public weak var delegate: AdBannerViewDelegate?
 public weak var viewController: UIViewController?  //View controller to present ads onto

 public static func configure(withApplicationID id: String ) {
 print("Dummy AdBannerView")
 }

 public var height: CGFloat {
 if UIDevice.current.userInterfaceIdiom == .pad {
 return 90
 } else {
 return UIDevice.current.orientation.isLandscape ? 32 : 50
 }
 }

 public override init(frame: CGRect) {
 super.init(frame: frame)
 }

 required init?(coder aDecoder: NSCoder) {
 super.init(coder: aDecoder)
 }

 deinit {
 }

 ////////////////////////////////////////////////////////////////////////////////////
 // Advert start/stop deamons
 ////////////////////////////////////////////////////////////////////////////////////

 public func requestAd() {
 //  delegate?.adView?(advert: self, didFailToReceiveAdWithError: NSError(domain: "Dummy AdViewBanner", code: 0, userInfo: nil))
 }

 public func stop() {
 }
 }
 */


public class AdBannerView: UIView, GADBannerViewDelegate {
    public static let shared = AdBannerView() //Singleton Class

    public var adEnabled: Bool = false
    public var adLoaded: Bool = false
    public var isPresenting = false //Status whether the ad is being viewed

    public static func configure(withApplicationID id: String ) {
        GADMobileAds.configure(withApplicationID: id)
        shared.adEnabled = true
    }

    //Delegates
    public weak var delegate: AdBannerViewDelegate?
    public weak var viewController: UIViewController? { //View controller to present ads onto
        didSet{
            //View controller changed while admob is presented
            if viewController != nil && oldValue != viewController {
                adMob.rootViewController = viewController
            }
        }
    }

    // Constants (and computed variables)
    fileprivate var adUnitID: String {
        return UIDevice.current.isSimulator ? "ca-app-pub-3940256099942544/2934735716" : "ca-app-pub-7278208006986307/9712866674"
    }

    public var height: CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return 90
        } else {
            return UIDevice.current.orientation.isLandscape ? 32 : 50
        }
    }

    //Advert Views
    public var adMob: GADBannerView!

    lazy fileprivate var request: GADRequest = {
        //Load request for production or testing
        let request = GADRequest()
        if UIDevice.current.isSimulator {
            request.testDevices = [ kGADSimulatorID ]
        }
        return request
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        adMob = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        adMob.rootViewController = viewController
        adMob.adUnitID = adUnitID
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    deinit {
        adMob.delegate = nil
        adMob.removeFromSuperview()
        adMob = nil
    }

    ////////////////////////////////////////////////////////////////////////////////////
    // Advert start/stop deamons
    ////////////////////////////////////////////////////////////////////////////////////

    public func requestAd() {
        guard AdBannerView.shared.adEnabled else {
            print("Ads are not enabled. Please configure GADMobileAds with an ID")
            return
        }

        if adLoaded {
            delegate?.adViewDidLoadAd?(advert: self)
        } else {
            adMob.delegate = self
            adMob.load(request)
        }
    }

    public func stop() {
        adLoaded = false
        adMob.delegate = nil
    }


    //AdMob Delegate
    public func adViewDidReceiveAd(_ bannerView: GADBannerView) {

        print("Did receive new ad")
        adLoaded = true

        //Show ad when loaded
        if adMob.superview == nil {
            addSubview(adMob)
        }

        layoutSubviews()
        delegate?.adViewDidLoadAd?(advert: self)
    }

    public func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        adLoaded = false
        print("didFailToReceiveAdWithError: ", error)
        delegate?.adView?(advert: self, didFailToReceiveAdWithError: error)
    }

    public func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        isPresenting = true

        //Delegate
        delegate?.adViewActionShouldBegin?(advert: self)
    }

    public func adViewDidDismissScreen(_ bannerView: GADBannerView) {

        delegate?.adViewActionDidFinish?(advert: self)
        isPresenting = false
        layoutSubviews()
    }

    //Resize all frames to suite orientation and screen dimentions
    override public func layoutSubviews() {
        super.layoutSubviews()

        //Stop frame from ajusting when presenting an advert which isn't current orientation
        if isPresenting { return }

        //Set orientation
        if UIDevice.current.orientation.isLandscape {
            adMob.adSize = kGADAdSizeSmartBannerLandscape
        } else {
            adMob.adSize = kGADAdSizeSmartBannerPortrait
        }


        //Set constraints
        adMob.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        adMob.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        adMob.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }

    //Run callback for default advert if clicked
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        var visible = true

        //Check AdMob
        if adMob.window != nil {
            visible = false
        }

        if visible{
            delegate?.adViewDefaultAction?(advert: self)
        }
    }
}

public extension UIDevice {

    public var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
}
