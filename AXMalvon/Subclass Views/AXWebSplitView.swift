//
//  AXWebSplitView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-26.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import AppKit

class AXWebSplitView: NSSplitView, NSSplitViewDelegate {
    
    init() {
        super.init(frame: .zero)
        
        delegate = self
        isVertical = true
        dividerStyle = .thin
    }
    
    func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return 50
    }
    
    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        return false
    }
    
    override func drawDivider(in rect: NSRect) {
        // Writing nothing here makes the divider invisible
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class AXWebSplitViewAddItemView: NSView {
    private var hasDrawn: Bool = false
    
    lazy var addSplitViewLabel: NSTextField = {
        let label = NSTextField()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isEditable = false
        label.alignment = .left
        label.isBordered = false
        label.drawsBackground = false
        label.stringValue = "Create Split View"
        label.textColor = .white
        label.font = .systemFont(ofSize: 15, weight: .medium)
        
        return label
    }()
    
    lazy var plusImageView: NSImageView = {
        let imageView = NSImageView(frame: .zero)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setFrameSize(.init(width: 512, height: 512))
        imageView.sizeThatFits(.init(width: 512, height: 512))
        imageView.imageScaling = .scaleAxesIndependently
        imageView.controlSize = .large
        imageView.contentTintColor = .white
        imageView.image = .init(systemSymbolName: "plus", accessibilityDescription: nil)
        return imageView
    }()
    
    override func viewWillDraw() {
        if !hasDrawn {
            wantsLayer = true
            layer?.backgroundColor = NSColor.purple.cgColor
            layer?.cornerRadius = 5.0
            
            addSubview(addSplitViewLabel)
            addSplitViewLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            addSplitViewLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            
            addSubview(plusImageView)
            plusImageView.bottomAnchor.constraint(equalTo: addSplitViewLabel.topAnchor, constant: -15).isActive = true
            plusImageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            
            hasDrawn = true
        }
    }
}
