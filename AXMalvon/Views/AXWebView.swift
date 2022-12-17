//
//  AXWebView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-06.
//  Copyright © 2022 Aayam(X). All rights reserved.
//

import AppKit
import WebKit

class AXWebView: WKWebView {
    func addConfigurations() {
        self.configuration.preferences.setValue(true, forKey: "offlineApplicationCacheIsEnabled")
        self.configuration.preferences.setValue(true, forKey: "fullScreenEnabled")
        self.configuration.preferences.setValue(true, forKey: "allowsPictureInPictureMediaPlayback")
        self.configuration.preferences.setValue(true, forKey: "acceleratedDrawingEnabled")
        self.configuration.preferences.setValue(true, forKey: "largeImageAsyncDecodingEnabled")
        self.configuration.preferences.setValue(true, forKey: "animatedImageAsyncDecodingEnabled")
        self.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        self.configuration.preferences.setValue(true, forKey: "loadsImagesAutomatically")
        self.configuration.preferences.setValue(true, forKey: "acceleratedCompositingEnabled")
        self.configuration.preferences.setValue(true, forKey: "canvasUsesAcceleratedDrawing")
        self.configuration.preferences.setValue(true, forKey: "localFileContentSniffingEnabled")
        self.configuration.preferences.setValue(true, forKey: "usesPageCache")
        self.configuration.preferences.setValue(true, forKey: "aggressiveTileRetentionEnabled")
        self.configuration.preferences.setValue(true, forKey: "appNapEnabled")
        self.configuration.preferences.setValue(true, forKey: "aggressiveTileRetentionEnabled")
        self.configuration.preferences.setValue(false, forKey: "backspaceKeyNavigationEnabled")
        
        self.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15"
        
        self.allowsMagnification = true
    }
    
    // Code Borrowed From: https://github.com/sstahurski/SearchWKWebView
    func highlightAllOccurencesOfString(string:String)  {
        if let path = Bundle.main.url(forResource: "WKWebViewSearch", withExtension: "js") {
            do{
                let data:Data = try Data(contentsOf: path)
                let jsCode:String = String(decoding: data, as: UTF8.self)
                
                //print( jsCode)
                
                //inject the search code
                self.evaluateJavaScript(jsCode, completionHandler: nil)
                //search function
                let searchString = "WKWebView_HighlightAllOccurencesOfString('\(string)')"
                //perform search
                self.evaluateJavaScript(searchString, completionHandler: nil)
                
                
            } catch {
                print("could not load javascript:\(error)")
                
            }
            
            
        }
    }
    
    func handleSearchResultCount( completionHandler: @escaping (_ count:Int) -> Void ) {
        //count function
        let countString  = "WKWebView_SearchResultCount"
        
        //get count
        self.evaluateJavaScript(countString) { (result, error) in
            if error == nil {
                if result != nil {
                    let count = result as! Int
                    completionHandler(count)
                }
            }
        }
    }
    
    
    func removeAllHighlights(){
        self.evaluateJavaScript("WKWebView_RemoveAllHighlights()", completionHandler: nil)
    }
    
    func searchNext(){
        self.evaluateJavaScript("WKWebView_SearchNext()", completionHandler: nil)
    }
    
    func searchPrevious(){
        self.evaluateJavaScript("WKWebView_SearchPrev()", completionHandler: nil)
    }
}
