//
//  ViewController.swift
//  AdMobSample
//
//  Created by Taco Kind on 25/01/2019.
//  Copyright © 2019 Taco Kind. All rights reserved.
//

import UIKit
import AdMobSourceTarget

public class TestTargetViewController: UIViewController, AdBannerViewDelegate {

    public var adBannerView: AdBannerView!

    override public func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .green

        adBannerView = AdBannerView.shared
        adBannerView.viewController = self
        adBannerView.delegate = self
        adBannerView.translatesAutoresizingMaskIntoConstraints = false
        adBannerView.requestAd()
        view.addSubview(adBannerView)

        adBannerView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        adBannerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }

    

    public func adViewDidLoadAd(advert: AdBannerView) {
        print("Ad loaded")
     //   showAd(true)
    }

    public func adView(advert: AdBannerView, didFailToReceiveAdWithError error: NSError) {
        print("Ad not loaded")
     //   showAd(false)
    }

}




