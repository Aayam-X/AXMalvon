//
//  AXWebView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-06.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import AppKit
import WebKit

enum ContextualMenuAction {
    case openInNewTab
    // Add other stuff
}

fileprivate let favIconScript = "document.querySelector('link[rel=\"icon\"], link[rel=\"shortcut icon\"]').getAttribute('href');"

class AXWebView: WKWebView {
    var isSplitView: Bool = false
    var contextualMenuAction: ContextualMenuAction?
    
    // MARK: - Functions
    
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
        
        self.layer?.borderColor = NSColor.controlAccentColor.cgColor
    }
    
    override func becomeFirstResponder() -> Bool {
        if isSplitView {
            self.layer?.borderWidth = 1.0
            let appProperties = (window as! AXWindow).appProperties
            appProperties.sidebarView.webView_updateSelection(webView: self)
            
            self.window?.title = self.title ?? "Untitled Tab"
            appProperties.webContainerView.windowTitleLabel.stringValue = self.title ?? "Untitled Tab"
        }
        
        return super.becomeFirstResponder()
    }
    
    override func removeFromSuperview() {
        if isSplitView {
            self.layer?.borderWidth = 0.0
            isSplitView = false
        }
        
        super.removeFromSuperview()
    }
    
    override func resignFirstResponder() -> Bool {
        if isSplitView {
            self.layer?.borderWidth = 0.0
        }
        
        return super.resignFirstResponder()
    }
    
    // MARK: - Favicon
    
    public func getFavicon(completion: @escaping(URL?) -> ()) {
        evaluateJavaScript(favIconScript) { result, error in
            if let favIconURL = result as? String {
                completion(URL(string: favIconURL))
                return
            }
            
            // If cannot find icon
            if let url = self.url {
                completion(URL(string: "https://www.google.com/s2/favicons?sz=16&domain_url=" + url.absoluteString))
                return
            }
            
            // Everything failed
            completion(nil)
            return
        }
    }
    
    // MARK: - Right click menu
    override func willOpenMenu(_ menu: NSMenu, with event: NSEvent) {
        super.willOpenMenu(menu, with: event)
        
        var objectType: String? = nil
        
        for item in menu.items {
            switch item.identifier?.rawValue {
            case "WKMenuItemIdentifierOpenLinkInNewWindow":
                objectType = "Link"
            case "WKMenuItemIdentifierOpenImageInNewWindow":
                objectType = "Image"
            case "WKMenuItemIdentifierOpenMediaInNewWindow":
                objectType = "Media"
            case "WKMenuItemIdentifierOpenFrameInNewWindow":
                objectType = "Frame"
            default:
                break
            }
        }
        
        if let objectType = objectType {
            let newMenuItem = NSMenuItem(title: "Open \(objectType) in New Tab", action: #selector(openLinkInNewTab(_:)), keyEquivalent: "")
            newMenuItem.representedObject = menu.items[1] // Open in new window
            menu.items.insert(newMenuItem, at: 1)
            menu.items.insert(.separator(), at: 3)
        }
    }
    
    override func didCloseMenu(_ menu: NSMenu, with event: NSEvent?) {
        super.didCloseMenu(menu, with: event)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            self.contextualMenuAction = nil
        }
    }
    
    @objc func openLinkInNewTab(_ sender: NSMenuItem) {
        contextualMenuAction = .openInNewTab
        
        if let originalItem = sender.representedObject as? NSMenuItem {
            _ = originalItem.target?.perform(originalItem.action, with: originalItem)
        }
    }
    
    // MARK: - Web Searching
    
    // Code Borrowed From: https://github.com/sstahurski/SearchWKWebView
    func highlightAllOccurencesOfString(string: String) {
        if let path = Bundle.main.url(forResource: "WKWebViewSearch", withExtension: "js") {
            do {
                let data: Data = try Data(contentsOf: path)
                let jsCode: String = String(decoding: data, as: UTF8.self)
                
                self.evaluateJavaScript(jsCode, completionHandler: nil)
                let searchString = "WKWebView_HighlightAllOccurencesOfString('\(string)')"
                self.evaluateJavaScript(searchString, completionHandler: nil)
                
            } catch {
                print("could not load javascript:\(error)")
                
            }
            
        }
    }
    
    func handleSearchResultCount(completionHandler: @escaping (_ count: Int) -> Void) {
        //count function
        let countString = "WKWebView_SearchResultCount"
        
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
    
    func removeAllHighlights() {
        self.evaluateJavaScript("WKWebView_RemoveAllHighlights()", completionHandler: nil)
    }
    
    func searchNext() {
        self.evaluateJavaScript("WKWebView_SearchNext()", completionHandler: nil)
    }
    
    func searchPrevious() {
        self.evaluateJavaScript("WKWebView_SearchPrev()", completionHandler: nil)
    }
}
