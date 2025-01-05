//
//  AXNewTabView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2025-01-01.
//  Copyright © 2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit

protocol AXNewTabViewDelegate: AnyObject {
    func didSelectItem(url: URL)
}

class AXNewTabView: NSView {
    weak var delegate: AXNewTabViewDelegate?

    var currentlyRightClickedItem: Int?

    private let visualEffectView: NSVisualEffectView = {
        let view = NSVisualEffectView()
        view.material = .sidebar
        view.blendingMode = .behindWindow
        view.state = .active
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let headerLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Favourites")
        label.font = NSFont.boldSystemFont(ofSize: 24)
        label.textColor = .labelColor
        label.alignment = .left  // Align header title to the left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let tabGroupScrollView: NSScrollView = {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private lazy var collectionView: NSCollectionView = {
        let layout = NSCollectionViewFlowLayout()
        layout.itemSize = NSSize(width: 100, height: 120)  // Increased size
        layout.sectionInset = NSEdgeInsets(
            top: 10, left: 10, bottom: 10, right: 10)
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10

        let view = NSCollectionView()
        view.collectionViewLayout = layout
        view.delegate = self
        view.dataSource = self
        view.backgroundColors = [.clear]
        view.allowsMultipleSelection = false  // Ensure only one item can be selected at a time
        view.register(
            AXNewTabTopSiteCardCollectionViewItem.self,
            forItemWithIdentifier: NSUserInterfaceItemIdentifier("TopSiteCard"))
        view.translatesAutoresizingMaskIntoConstraints = false
        view.menu = contextMenu
        return view
    }()

    private lazy var contextMenu: NSMenu = {
        let menu = NSMenu()
        menu.delegate = self

        menu.addItem(
            NSMenuItem(
                title: "Edit", action: #selector(editSite(_:)),
                keyEquivalent: ""))
        menu.addItem(
            NSMenuItem(
                title: "Delete", action: #selector(deleteSite(_:)),
                keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(
            NSMenuItem(
                title: "Add New Site", action: #selector(addNewSite),
                keyEquivalent: ""))
        return menu
    }()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        addSubview(visualEffectView)
        addSubview(headerLabel)
        addSubview(tabGroupScrollView)
        tabGroupScrollView.documentView = collectionView

        setupConstraints()
    }

    private func setupConstraints() {
        // Visual Effect View
        visualEffectView.activateConstraints([
            .allEdges: .view(self)
        ])

        // Header Label
        headerLabel.activateConstraints([
            .top: .view(self, constant: 20),
            .left: .view(self, constant: 20),
        ])

        // Scroll View
        tabGroupScrollView.activateConstraints([
            .top: .view(headerLabel, constant: 20),
            .bottom: .view(self),
            .horizontalEdges: .view(self),
        ])
    }

    @objc
    private func editSite(_ sender: NSMenuItem) {
        guard let index = currentlyRightClickedItem else { return }
        self.currentlyRightClickedItem = nil

        let site = AXNewTabFavouritesManager.shared.getAllSites()[index]

        let sheetVC = AXSiteEditSheet(
            title: site.title, url: site.url, isNewSite: false, index: index
        ) { [weak self] title, url in
            AXNewTabFavouritesManager.shared.updateSite(
                at: index, with: .init(title: title, url: url))
            self?.collectionView.reloadItems(at: [
                IndexPath(item: index, section: 0)
            ])
        }

        if let window = self.window {
            let newWindow = NSWindow(contentViewController: sheetVC)

            window.beginSheet(newWindow)
        }
    }

    @objc
    private func deleteSite(_ sender: NSMenuItem) {
        guard let index = currentlyRightClickedItem else { return }
        AXNewTabFavouritesManager.shared.deleteSite(at: index)
        collectionView.reloadData()
    }

    @objc
    private func addNewSite() {
        let sheetVC = AXSiteEditSheet(isNewSite: true) {
            [weak self] title, url in
            AXNewTabFavouritesManager.shared.addSite(
                .init(title: title, url: url))
            self?.collectionView.reloadData()
        }

        if let window = self.window {
            let newWindow = NSWindow(contentViewController: sheetVC)
            window.beginSheet(newWindow)
        }
    }
}

extension AXNewTabView: NSCollectionViewDelegate, NSCollectionViewDataSource {
    func collectionView(
        _ collectionView: NSCollectionView, numberOfItemsInSection section: Int
    ) -> Int {
        return AXNewTabFavouritesManager.shared.getAllSites().count
    }

    func collectionView(
        _ collectionView: NSCollectionView,
        itemForRepresentedObjectAt indexPath: IndexPath
    ) -> NSCollectionViewItem {
        let item =
            collectionView.makeItem(
                withIdentifier: NSUserInterfaceItemIdentifier("TopSiteCard"),
                for: indexPath) as? AXNewTabTopSiteCardCollectionViewItem
            ?? AXNewTabTopSiteCardCollectionViewItem()
        item.mouseUpSelector = collectionViewMouseDown
        item.onRightMouseDown = collectionViewRightMouseDown(index:)

        let site = AXNewTabFavouritesManager.shared.getAllSites()[
            indexPath.item]
        item.configure(title: site.title, url: site.url, index: indexPath.item)
        return item
    }

    func collectionViewMouseDown(url: String) {
        delegate?.didSelectItem(url: URL(string: url)!)
    }

    func collectionViewRightMouseDown(index: Int) {
        self.currentlyRightClickedItem = index
    }
}

extension AXNewTabView: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        let isHidden = currentlyRightClickedItem == nil
        menu.items[0].isHidden = isHidden
        menu.items[1].isHidden = isHidden
        menu.items[2].isHidden = isHidden
    }
}
