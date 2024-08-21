//
//  WindowObserver.swift
//  EdgeWindow
//
//  Created by WeiHan on 2024/8/8.
//

import Cocoa
import Accessibility
import ApplicationServices

struct WindowInfo {
    let appName: String
    let title: String?
    let frame: CGRect
    let screen: NSScreen?
}

/// https://stackoverflow.com/a/43927394/1677041
func maybeCast<T>(_ value: T, to cfType: AXValue.Type) -> AXValue? {
    guard CFGetTypeID(value as CFTypeRef) == AXValueGetTypeID() else {
        return nil
    }

    return (value as! AXValue)
}

func pointFromAXValue(_ axValue: AXValue) -> CGPoint? {
    var point = CGPoint.zero

    if AXValueGetValue(axValue, .cgPoint, &point) {
        return point
    }

    return nil
}

func sizeFromAXValue(_ axValue: AXValue) -> CGSize? {
    var size = CGSize.zero

    if AXValueGetValue(axValue, .cgSize, &size) {
        return size
    }

    return nil
}

func getAllWindowsWithScreenInfo() -> [WindowInfo] {
    var windowInfos: [WindowInfo] = []
    let runningApps = NSWorkspace.shared.runningApplications

    Logger.debug("found \(runningApps.count) app(s)")

    for app in runningApps {
        guard let appName = app.localizedName else {
            Logger.debug("no named for app \(app) pid \(app.processIdentifier)")
            continue
        }

        let appRef = AXUIElementCreateApplication(app.processIdentifier)

        var windowList: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowList)

        guard result == .success, let windows = windowList as? [AXUIElement] else {
            Logger.debug("result \(result == .success ? "yes" : "no") window list: \(windowList) for app pid \(app.processIdentifier)")
            continue
        }

        for window in windows {
            var title: CFTypeRef?
            AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &title)

            var positionValue: CFTypeRef?
            AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue)

            var sizeValue: CFTypeRef?
            AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue)

            let windowTitle = title as? String

            guard let positionValue = maybeCast(positionValue, to: AXValue.self),
                  let sizeValue = maybeCast(sizeValue, to: AXValue.self) else {
                Logger.debug("invalid value type found")
                continue
            }

            guard let position = pointFromAXValue(positionValue),
                  let size = sizeFromAXValue(sizeValue) else {
                Logger.debug("no valid info for app: \(appName) position \(positionValue) size \(sizeValue)")
                continue
            }

            // Logger.debug("appName: \(appName)")
            // Logger.debug("title: \(windowTitle ?? "<untitled>")")
            // Logger.debug("pos: \(position)")
            // Logger.debug("size: \(size)")

            let frame = CGRect(origin: position, size: size)
            let screen = NSScreen.screens.first(where: { $0.frame.contains(frame) })
            let windowInfo = WindowInfo(appName: appName, title: windowTitle, frame: frame, screen: screen)
            windowInfos.append(windowInfo)
        }
    }

    return windowInfos
}

//func resizeWindows(windowInfos: [WindowInfo], targetSize: CGSize) {
//    for windowInfo in windowInfos {
//        let appRef = AXUIElementCreateApplication(windowInfo.appName.hashValue) // Use the process identifier instead of app name
//
//        var window: AXUIElement?
//        let result = AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &window)
//
//        if result == .success, let window = window {
//            var currentFrame = windowInfo.frame
//
//            // Resize logic: only resize if the window is larger than the target size
//            if currentFrame.size.width > targetSize.width || currentFrame.size.height > targetSize.height {
//                currentFrame.size.width = min(currentFrame.size.width, targetSize.width)
//                currentFrame.size.height = min(currentFrame.size.height, targetSize.height)
//
//                // Set the new frame
//                AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, NSValue(rect: currentFrame))
//            }
//        }
//    }
//}


class WindowObserver {
    let restrictedEdgeInsets: NSEdgeInsets
    private var mainScreen: NSScreen?

    init(_ restrictedEdgeInsets: NSEdgeInsets) {
        self.restrictedEdgeInsets = restrictedEdgeInsets
        self.mainScreen = NSScreen.main
        self.startObserving()
    }

    private func startObserving() {
        // Register for notifications
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(windowDidResize(_:)),
                                               name: NSWindow.didResizeNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(windowDidMove(_:)),
                                               name: NSWindow.didMoveNotification,
                                               object: nil)

        let info = getAllWindowsWithScreenInfo()

        Logger.debug("app: \(info)")

        // Add observer for all startObservingexisting windows
        for window in NSApplication.shared.windows {
            windowDidMove(Notification(name: NSWindow.didMoveNotification, object: window))
            windowDidResize(Notification(name: NSWindow.didResizeNotification, object: window))
        }
    }

    @objc func windowDidResize(_ notification: Notification) {
        Logger.debug("resize: \(notification)")
        guard let window = notification.object as? NSWindow else { return }
        restrictWindow(window)
    }

    @objc func windowDidMove(_ notification: Notification) {
        Logger.debug("move: \(notification)")
        guard let window = notification.object as? NSWindow else { return }
        restrictWindow(window)
    }

    private func restrictWindow(_ window: NSWindow) {
        guard AXIsProcessTrusted() else {
            return
        }

        guard let screen = window.screen ?? mainScreen else { return }
        var frame = window.frame

        // Restrict size
        if frame.width > screen.visibleFrame.width - restrictedEdgeInsets.left - restrictedEdgeInsets.right {
            frame.size.width = screen.visibleFrame.width - restrictedEdgeInsets.left - restrictedEdgeInsets.right
        }
        if frame.height > screen.visibleFrame.height - restrictedEdgeInsets.top - restrictedEdgeInsets.bottom {
            frame.size.height = screen.visibleFrame.height - restrictedEdgeInsets.top - restrictedEdgeInsets.bottom
        }

        // Restrict position
        if frame.origin.x < screen.visibleFrame.origin.x + restrictedEdgeInsets.left {
            frame.origin.x = screen.visibleFrame.origin.x + restrictedEdgeInsets.left
        }
        if frame.origin.y < screen.visibleFrame.origin.y + restrictedEdgeInsets.bottom {
            frame.origin.y = screen.visibleFrame.origin.y + restrictedEdgeInsets.bottom
        }
        if frame.origin.x + frame.size.width > screen.visibleFrame.origin.x + screen.visibleFrame.width - restrictedEdgeInsets.right {
            frame.origin.x = screen.visibleFrame.origin.x + screen.visibleFrame.width - restrictedEdgeInsets.right - frame.size.width
        }
        if frame.origin.y + frame.size.height > screen.visibleFrame.origin.y + screen.visibleFrame.height - restrictedEdgeInsets.top {
            frame.origin.y = screen.visibleFrame.origin.y + screen.visibleFrame.height - restrictedEdgeInsets.top - frame.size.height
        }

        // Set the frame if it has changed
        if window.frame != frame {
            window.setFrame(frame, display: true)
        }
    }
}
