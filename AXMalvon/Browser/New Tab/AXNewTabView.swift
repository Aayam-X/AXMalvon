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

let items = [
    ("Google", "https://www.google.com"),
    ("Gmail", "https://mail.google.com"),
    ("Mathematics", "https://pdsb.elearningontario.ca/d2l/home/26235716"),
    ("ManageBac", "https://turnerfenton.managebac.com/student"),
    ("Classroom", "https://classroom.google.com/"),
    ("Kognity", "https://app.kognity.com/study/app/dashboard")
]

class AXNewTabView: NSView {
    weak var delegate: AXNewTabViewDelegate?

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
        label.alignment = .left // Align header title to the left
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
        layout.itemSize = NSSize(width: 100, height: 120) // Increased size
        layout.sectionInset = NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10

        let view = NSCollectionView()
        view.collectionViewLayout = layout
        view.delegate = self
        view.dataSource = self
        view.backgroundColors = [.clear]
        view.allowsMultipleSelection = false // Ensure only one item can be selected at a time
        view.register(AXNewTabTopSiteCardCollectionView.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier("TopSiteCard"))
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
        NSLayoutConstraint.activate([
            // Visual Effect View
            visualEffectView.topAnchor.constraint(equalTo: topAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),
            visualEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            visualEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),

            // Header Label
            headerLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20), // Align to left

            // Scroll View
            tabGroupScrollView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 20),
            tabGroupScrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            tabGroupScrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tabGroupScrollView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}

extension AXNewTabView: NSCollectionViewDelegate, NSCollectionViewDataSource {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier("TopSiteCard"), for: indexPath) as? AXNewTabTopSiteCardCollectionView ?? AXNewTabTopSiteCardCollectionView()
        item.mouseDownSelector = collectionViewMouseDown

        let site = items[indexPath.item]
        item.configure(title: site.0, url: site.1)
        return item
    }

    func collectionViewMouseDown(url: String) {
        delegate?.didSelectItem(url: URL(string: url)!)
    }
}

class AXNewTabTopSiteCardCollectionView: NSCollectionViewItem {
    internal let myImageView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "")
    private var url: String! = nil

    var mouseDownSelector: ((String) -> Void)?

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
        view.layer?.cornerRadius = 9
        view.layer?.backgroundColor = nil // Removed background color

        myImageView.translatesAutoresizingMaskIntoConstraints = false
        myImageView.wantsLayer = true
        myImageView.layer?.shadowColor = NSColor.black.cgColor
        myImageView.layer?.shadowOpacity = 0.2
        myImageView.layer?.shadowOffset = CGSize(width: 0, height: -2)
        myImageView.layer?.shadowRadius = 4
        myImageView.layer?.cornerRadius = 9

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = NSFont.systemFont(ofSize: 14)
        titleLabel.alignment = .center

        view.addSubview(myImageView)
        view.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            myImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            myImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            myImageView.widthAnchor.constraint(equalToConstant: 60), // Larger image
            myImageView.heightAnchor.constraint(equalToConstant: 60),

            titleLabel.topAnchor.constraint(equalTo: myImageView.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5)
        ])
    }

    func configure(title: String, url: String) {
        titleLabel.stringValue = title
        self.url = url

        let cacheKey = "placeholder_\(title)" // Unique key for caching based on the title
        if let cachedImage = ImageCache.shared.getImage(forKey: cacheKey) {
            self.myImageView.image = cachedImage
        } else {
            let placeholderImage = createPlaceholderImage(for: title)
            ImageCache.shared.setImage(placeholderImage, forKey: cacheKey)
            self.myImageView.image = placeholderImage
        }
    }

    private func createPlaceholderImage(for title: String) -> NSImage {
        let size = CGSize(width: 60, height: 60)
        let firstLetter = String(title.prefix(1)).uppercased()
        let colors: [NSColor] = [
            .systemRed, .systemBlue, .systemGreen, .systemYellow,
            .systemOrange, .systemPurple, .systemPink, .systemTeal, .systemPurple, .systemCyan, .systemIndigo
        ]
        let backgroundColor = colors.randomElement() ?? .systemGray

        let image = NSImage(size: size)
        image.lockFocus()

        // Draw background
        backgroundColor.setFill()
        let rect = NSRect(origin: .zero, size: size)
        rect.fill()

        // Draw first letter
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 24),
            .foregroundColor: NSColor.white,
            .paragraphStyle: {
                let style = NSMutableParagraphStyle()
                style.alignment = .center
                style.lineBreakMode = .byClipping
                return style
            }()
        ]

        let attributedString = NSAttributedString(string: firstLetter, attributes: attributes)
        let textSize = attributedString.size()
        let textRect = CGRect(
            x: (rect.width - textSize.width) / 2,
            y: (rect.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        attributedString.draw(in: textRect)

        image.unlockFocus()
        return image
    }

    override func mouseDown(with event: NSEvent) {
        self.mouseDownSelector?(self.url)
    }
}

private class ImageCache {
    static let shared = ImageCache()
    private var cache = NSCache<NSString, NSImage>()

    private init() {}

    func getImage(forKey key: String) -> NSImage? {
        return cache.object(forKey: key as NSString)
    }

    func setImage(_ image: NSImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}
