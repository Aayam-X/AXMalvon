//
//  AXAddressBarHeaderCellView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-30.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit

class AXAddressBarSectionHeaderView: NSTableCellView {
    let titleLabel: NSTextField

    override init(frame frameRect: NSRect) {
        titleLabel = NSTextField(labelWithString: "Section")
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .bold)
        titleLabel.textColor = NSColor.secondaryLabelColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.leadingAnchor.constraint(
                equalTo: leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(
                equalTo: trailingAnchor, constant: -8),
        ])
    }
}
