//
//  AdBannerView.swift
//
//  Created by Taco Kind on 28-09-18.
//  Copyright © 2018 Taco Kind. All rights reserved.

import GoogleMobileAds

@objc public protocol AdBannerViewDelegate{
    @objc optional func adViewDefaultAction(advert: AdBannerView)
    @objc optional func adViewDidLoadAd(advert: AdBannerView)
    @objc optional func adView(advert: AdBannerView, didFailToReceiveAdWithError error: NSError)
    @objc optional func adViewActionShouldBegin(advert: AdBannerView)
    @objc optional func adViewActionDidFinish(advert: AdBannerView)
}

public class AdBannerView: UIView, GADBannerViewDelegate {
    public static let shared = AdBannerView() //Singleton Class

    public var adEnabled: Bool = false
    public var adLoaded: Bool = false
    public var isPresenting = false

    public static func configure(withApplicationID id: String ) {
        GADMobileAds.configure(withApplicationID: id)
        shared.adEnabled = true
    }

    public weak var delegate: AdBannerViewDelegate?
    public weak var viewController: UIViewController? {
        didSet{
            if viewController != nil && oldValue != viewController {
                adMob.rootViewController = viewController
            }
        }
    }

    fileprivate var adUnitID: String = "ca-app-pub-3940256099942544/2934735716"

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

        delegate?.adViewActionShouldBegin?(advert: self)
    }

    public func adViewDidDismissScreen(_ bannerView: GADBannerView) {

        delegate?.adViewActionDidFinish?(advert: self)
        isPresenting = false
        layoutSubviews()
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        guard !isPresenting else { return }

        //Set orientation
        adMob.adSize = UIDevice.current.orientation.isLandscape ? kGADAdSizeSmartBannerLandscape : kGADAdSizeSmartBannerPortrait

        //Set constraints
        adMob.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        adMob.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        adMob.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }

    //Run callback for default advert if clicked
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        //Check AdMob
        if adMob.window == nil {
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
