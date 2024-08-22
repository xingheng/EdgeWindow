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
    let position: CGPoint
    let size: CGSize
    let screen: NSScreen?
    let window: AXUIElement
    let pid: pid_t
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

    Logger.info("found \(runningApps.count) app(s)")

    for app in runningApps {
        guard let appName = app.localizedName else {
            Logger.info("no named for app \(app) pid \(app.processIdentifier)")
            continue
        }

        let appRef = AXUIElementCreateApplication(app.processIdentifier)

        var windowList: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowList)

        guard result == .success, let windows = windowList as? [AXUIElement] else {
            Logger.warning("result \(result == .success ? "yes" : "no") window list: \(String(describing: windowList)) for app pid \(app.processIdentifier)")
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
                Logger.error("invalid value type found")
                continue
            }

            guard let position = pointFromAXValue(positionValue),
                  let size = sizeFromAXValue(sizeValue) else {
                Logger.error("no valid info for app: \(appName) position \(positionValue) size \(sizeValue)")
                continue
            }

            let frame = CGRect(origin: position, size: size)
            let screen = NSScreen.screens.first(where: { $0.frame.contains(frame) })
            let windowInfo = WindowInfo(appName: appName, title: windowTitle, position: position, size: size, screen: screen, window: window, pid: app.processIdentifier)
            windowInfos.append(windowInfo)

            Logger.debug("appName: \(appName)")
            Logger.debug("title: \(windowTitle ?? "<untitled>")")
            Logger.debug("pos: \(position)")
            Logger.debug("size: \(size)")
            Logger.debug("screen: \(screen?.localizedName) \(screen?.visibleFrame) \(screen?.deviceDescription)")
        }
    }

    return windowInfos
}

func resizeWindows(_ windowInfos: [WindowInfo], inset: NSEdgeInsets) {
    for windowInfo in windowInfos {
        let window = windowInfo.window

        // for debug only
        guard windowInfo.appName == "Finder" else {
            continue
        }

        if NSEdgeInsetsEqual(inset, NSEdgeInsetsZero) == false {
            var position = windowInfo.position
            var size = windowInfo.size

            position.x += inset.left
            position.y += inset.top
            size.width -= inset.left + inset.right
            size.height -= inset.top + inset.bottom

            var positionSettable: DarwinBoolean = .init(false)
            var sizeSettable: DarwinBoolean = .init(false)

            AXUIElementIsAttributeSettable(window, kAXPositionAttribute as CFString, &positionSettable)
            AXUIElementIsAttributeSettable(window, kAXSizeAttribute as CFString, &sizeSettable)

            Logger.debug("position settable: \(positionSettable) size settable: \(sizeSettable)")

            if sizeSettable.boolValue {
                let value = AXValueCreate(.cgSize, &size)!
                let result = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, value)

                Logger.info("window \(windowInfo.title ?? "untitled") - app: \(windowInfo.appName)")
                Logger.info("\t old size: \(windowInfo.size)")
                Logger.info("\t new size: \(size)")

                if result == .success {
                    Logger.info("set size succeed")
                } else {
                    Logger.error("set size failed \(result.rawValue)")
                }
            } else {
                Logger.info("window '\(windowInfo.title ?? "<untitled>")' of app '\(windowInfo.appName)' size is not settable")
            }

            if positionSettable.boolValue {
                let value = AXValueCreate(.cgPoint, &position)!
                let result = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, value)

                Logger.info("window \(windowInfo.title ?? "untitled") - app: \(windowInfo.appName)")
                Logger.info("\t old position: \(windowInfo.position)")
                Logger.info("\t new position: \(position)")

                if result == .success {
                    Logger.info("set position succeed")
                } else {
                    Logger.error("set position failed \(result.rawValue)")
                }
            } else {
                Logger.info("window '\(windowInfo.title ?? "<untitled>")' of app '\(windowInfo.appName)' position is not settable")
            }
        }
    }
}


class WindowObserver {
    
    func startObserving() {
        let info = getAllWindowsWithScreenInfo()

        Logger.debug("app: \(info)")
        resizeWindows(info, inset: .init(top: 0, left: 35, bottom: 0, right: 0))
    }
}
