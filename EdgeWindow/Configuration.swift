//
//  Configuration.swift
//  EdgeWindow
//
//  Created by WeiHan on 2024/8/22.
//

import Foundation
import AppKit

class Configuration {

    static var shared: Configuration = .init()

    public private(set) var screens: [Screen] = .init()

    private init() { }
}

extension Configuration {

    private var keyName: String {
        "screens"
    }

    func save() {
        let array = screens.map { $0.dict }
        UserDefaults.standard.set(array, forKey: keyName)
        UserDefaults.standard.synchronize()
    }

    func load() {
        merge(screens: NSScreen.screens.map({ Screen($0) }))

        let array = UserDefaults.standard.object(forKey: keyName) as? [[String: Any]]

        if let new_screens = array?.map({ Screen.init(from: $0) }) {
            merge(screens: new_screens)
        }
    }

    private func merge(screens new_screens: [Screen]) {
        // Merge the new incoming screen to existing list.
        for s in new_screens {
            if let idx = screens.firstIndex(of: s) {
                screens[idx] = s
            } else {
                screens.append(s)
            }
        }
    }

    func match(screen: NSScreen) -> Screen? {
        screens.first { $0.screenID == screen.screenID }
    }
}

class Screen: Equatable {
    public private(set) var screenID: Int
    public private(set) var screenName: String?

    var edgeInset: NSEdgeInsets

    private init() {
        screenID = 0
        edgeInset = NSEdgeInsetsZero
    }

    init(_ screen: NSScreen) {
        screenID = screen.screenID
        screenName = screen.localizedName
        edgeInset = NSEdgeInsetsZero
    }

    static func == (lhs: Screen, rhs: Screen) -> Bool {
        lhs.screenID == rhs.screenID
    }

    var descriptions: String {
        "\(self) ID: \(screenID) Name:\(screenName ?? "<Unknown>") Insets:\(edgeInset)"
    }
}

extension Screen {

    private enum JSONKey: String {
        case screenID, screenName
        case top, left, bottom, right
    }

    var dict: [String: Any] {
        [
            JSONKey.screenID.rawValue: screenID,
            JSONKey.screenName.rawValue: screenName ?? "",
            JSONKey.top.rawValue: edgeInset.top,
            JSONKey.left.rawValue: edgeInset.left,
            JSONKey.bottom.rawValue: edgeInset.bottom,
            JSONKey.right.rawValue: edgeInset.right,
        ]
    }

    convenience init(from dict: [String: Any]) {
        self.init()
        screenID = dict[JSONKey.screenID.rawValue] as? Int ?? 0
        screenName = dict[JSONKey.screenName.rawValue] as? String
        edgeInset = NSEdgeInsetsMake(dict[JSONKey.top.rawValue] as? CGFloat ?? 0,
                                     dict[JSONKey.left.rawValue] as? CGFloat ?? 0,
                                     dict[JSONKey.bottom.rawValue] as? CGFloat ?? 0,
                                     dict[JSONKey.right.rawValue] as? CGFloat ?? 0)
    }
}
