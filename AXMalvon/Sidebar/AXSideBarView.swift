//
//  AXSidebarView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-05.
//

import Cocoa

protocol AXSideBarViewDelegate: AnyObject {
    func sidebarView(didSelectTabGroup tabGroupAt: Int)
    func sidebarViewactiveTitle(changed to: String)
}

class AXSidebarView: NSView {
    private var hasDrawn: Bool = false
    weak var delegate: AXSideBarViewDelegate?

    var gestureView = AXGestureView()
    private weak var tabBarView: AXTabBarView?

    var currentTabGroup: AXTabGroup?

    override var tag: Int {
        return 0x01
    }

    override func viewWillDraw() {
        if hasDrawn { return }
        defer { hasDrawn = true }

        //self.layer?.backgroundColor = NSColor.systemIndigo.withAlphaComponent(0.3).cgColor

        gestureView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(gestureView)
        NSLayoutConstraint.activate([
            gestureView.topAnchor.constraint(equalTo: topAnchor),
            gestureView.leftAnchor.constraint(equalTo: leftAnchor),
            gestureView.rightAnchor.constraint(equalTo: rightAnchor),
            gestureView.heightAnchor.constraint(equalToConstant: 39),
        ])
    }

    func changeShownTabBarGroup(_ tabGroup: AXTabGroup) {
        currentTabGroup = tabGroup

        tabGroup.initializeTabBarView()
        updateTabBarView(tabBar: tabGroup.tabBarView!)

        // Update the webview
        if let tabs = currentTabGroup?.tabs {
            let window = self.window as! AXWindow
            gestureView.tabGroupInformationView.profileLabel.stringValue =
                window.defaultProfile.name
            gestureView.tabGroupInformationView.tabGroupLabel.stringValue =
                tabGroup.name

            let tabAt = tabGroup.selectedIndex

            if tabAt == -1 {
                window.containerView.createEmptyView()
            } else {
                window.containerView.updateView(webView: tabs[tabAt].webView)
            }
        }
    }

    private func updateTabBarView(tabBar: AXTabBarView) {
        tabBarView?.removeFromSuperview()

        self.tabBarView = tabBar
        self.tabBarView?.translatesAutoresizingMaskIntoConstraints = false
        self.tabBarView?.delegate = self

        addSubview(tabBarView!)

        NSLayoutConstraint.activate([
            tabBarView!.topAnchor.constraint(equalTo: topAnchor, constant: 44),
            tabBarView!.leadingAnchor.constraint(equalTo: leadingAnchor),
            tabBarView!.trailingAnchor.constraint(equalTo: trailingAnchor),
            tabBarView!.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}

extension AXSidebarView: AXTabBarViewDelegate {
    func activeTabTitleChanged(to: String) {
        delegate?.sidebarViewactiveTitle(changed: to)
    }
    
    func tabBarSwitchedTo(tabAt: Int) {
        print("Switched to tab at \(tabAt).")

        if let tabs = currentTabGroup?.tabs {
            let window = self.window as! AXWindow

            if tabAt == -1 {
                window.containerView.removeAllWebViews()
            } else {
                window.containerView.updateView(webView: tabs[tabAt].webView)
            }
        }
    }
}
