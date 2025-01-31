//
//  SwiftConstraintHelper.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2025-01-04.
//  Copyright © 2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit

extension NSView {
    enum ConstraintTarget {
        case constant(CGFloat)
        case view(NSView, constant: CGFloat = 0)
    }

    enum ConstraintLayoutAxis {
        case top
        case topBottom

        case bottom
        case bottomTop

        case left
        case leftRight

        case right
        case rightLeft

        case width
        case height

        case centerX
        case centerY

        case allEdges
        case horizontalEdges
        case verticalEdges
    }

    func activateConstraints(
        _ constraints: [ConstraintLayoutAxis: ConstraintTarget]
    ) {
        self.translatesAutoresizingMaskIntoConstraints = false
        var constraintsToActivate: [NSLayoutConstraint] = []

        for (attribute, target) in constraints {
            switch (attribute, target) {
            // Constraints to another view with optional constant
            case (.top, .view(let view, let constant)):
                constraintsToActivate.append(
                    self.topAnchor.constraint(
                        equalTo: view.topAnchor, constant: constant))

            case (.topBottom, .view(let view, let constant)):
                constraintsToActivate.append(
                    self.topAnchor.constraint(
                        equalTo: view.bottomAnchor, constant: constant))

            case (.bottom, .view(let view, let constant)):
                constraintsToActivate.append(
                    self.bottomAnchor.constraint(
                        equalTo: view.bottomAnchor, constant: constant))

            case (.bottomTop, .view(let view, let constant)):
                constraintsToActivate.append(
                    self.bottomAnchor.constraint(
                        equalTo: view.topAnchor, constant: constant))

            case (.left, .view(let view, let constant)):
                constraintsToActivate.append(
                    self.leftAnchor.constraint(
                        equalTo: view.leftAnchor, constant: constant))

            case (.leftRight, .view(let view, let constant)):
                constraintsToActivate.append(
                    self.leftAnchor.constraint(
                        equalTo: view.rightAnchor, constant: constant))

            case (.right, .view(let view, let constant)):
                constraintsToActivate.append(
                    self.rightAnchor.constraint(
                        equalTo: view.rightAnchor, constant: constant))

            case (.rightLeft, .view(let view, let constant)):
                constraintsToActivate.append(
                    self.rightAnchor.constraint(
                        equalTo: view.leftAnchor, constant: constant))

            case (.width, .view(let view, let constant)):
                constraintsToActivate.append(
                    self.widthAnchor.constraint(
                        equalTo: view.widthAnchor, constant: constant))

            case (.height, .view(let view, let constant)):
                constraintsToActivate.append(
                    self.heightAnchor.constraint(
                        equalTo: view.heightAnchor, constant: constant))

            case (.centerX, .view(let view, let constant)):
                constraintsToActivate.append(
                    self.centerXAnchor.constraint(
                        equalTo: view.centerXAnchor, constant: constant))

            case (.centerY, .view(let view, let constant)):
                constraintsToActivate.append(
                    self.centerYAnchor.constraint(
                        equalTo: view.centerYAnchor, constant: constant))

            // Constant constraints (to oneself)
            case (.width, .constant(let constant)):
                constraintsToActivate.append(
                    self.widthAnchor.constraint(equalToConstant: constant))

            case (.height, .constant(let constant)):
                constraintsToActivate.append(
                    self.heightAnchor.constraint(equalToConstant: constant))

            case (.allEdges, .view(let view, let constant)):
                constraintsToActivate.append(contentsOf: [
                    self.leftAnchor.constraint(
                        equalTo: view.leftAnchor, constant: constant),
                    self.rightAnchor.constraint(
                        equalTo: view.rightAnchor, constant: -constant),
                    self.topAnchor.constraint(
                        equalTo: view.topAnchor, constant: constant),
                    self.bottomAnchor.constraint(
                        equalTo: view.bottomAnchor, constant: -constant),
                ])

            case (.horizontalEdges, .view(let view, let constant)):
                constraintsToActivate.append(contentsOf: [
                    self.leftAnchor.constraint(
                        equalTo: view.leftAnchor, constant: constant),
                    self.rightAnchor.constraint(
                        equalTo: view.rightAnchor, constant: -constant),
                ])

            case (.verticalEdges, .view(let view, let constant)):
                constraintsToActivate.append(contentsOf: [
                    self.topAnchor.constraint(
                        equalTo: view.topAnchor, constant: constant),
                    self.bottomAnchor.constraint(
                        equalTo: view.bottomAnchor, constant: -constant),
                ])

            default:
                fatalError("Unsupported constraint combination")
            }
        }

        NSLayoutConstraint.activate(constraintsToActivate)
    }
}
