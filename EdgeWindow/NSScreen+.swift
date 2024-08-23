//
//  NSScreen+.swift
//  EdgeWindow
//
//  Created by WeiHan on 2024/8/23.
//

import Cocoa

extension NSScreen {

    var screenID: Int {
        deviceDescription[NSDeviceDescriptionKey(rawValue: "NSScreenNumber")] as? Int ?? 0
    }
}

extension NSScreen {

    class func screenContainingFrame(frame: NSRect) -> NSScreen? {
        let screens = NSScreen.screens

        // Check if the frame is contained within any screen
        for screen in screens {
            if screen.frame.contains(frame) {
                return screen
            }
        }

        let midPoint = NSPoint(x: frame.midX, y: frame.midY)

        // Check if the frame's center point is contained within any screen
        for screen in screens {
            if screen.frame.contains(midPoint) {
                return screen
            }
        }

        // If no screen contains the frame, find the nearest screen
        return nearestScreen(for: frame, in: screens)
    }

    class private func nearestScreen(for frame: NSRect, in screens: [NSScreen]) -> NSScreen? {
        var nearestScreen: NSScreen?
        var nearestDistance: CGFloat = .greatestFiniteMagnitude

        for screen in screens {
            let distance = distanceFromFrame(frame, to: screen.frame)

            if distance < nearestDistance {
                nearestDistance = distance
                nearestScreen = screen
            }
        }

        return nearestScreen
    }

    /// Calculate the distance from the frame to the screen's edge
    class private func distanceFromFrame(_ frame: NSRect, to screenFrame: NSRect) -> CGFloat {
        let midPoint1 = NSPoint(x: frame.midX, y: frame.midY)
        let midPoint2 = NSPoint(x: screenFrame.midX, y: screenFrame.midY)
        let dx = midPoint1.x - midPoint2.x
        let dy = midPoint1.y - midPoint2.y
        return sqrt(dx * dx + dy * dy)
    }
}
