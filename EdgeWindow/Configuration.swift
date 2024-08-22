//
//  Configuration.swift
//  EdgeWindow
//
//  Created by WeiHan on 2024/8/22.
//

import Foundation
import AppKit

struct Configuration {

    static let shared: Configuration = .init()

    var screens: [Screen] = .init()

    private init() {
    }
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

    mutating func load() {
        let array = UserDefaults.standard.object(forKey: keyName) as? [[String: Any]]
        let new_screens = array?.map { Screen.init(from: $0) }

        // Merge the new incoming screen to existing list.
        for s in new_screens ?? [] {
            if let idx = screens.firstIndex(of: s) {
                screens[idx] = s
            }
        }
    }
}

struct Screen: Equatable {
    public private(set) var screenID: Int
    public private(set) var screenName: String?

    var edgeInset: NSEdgeInsets

    init(_ screen: NSScreen) {
        screenID = screen.deviceDescription[NSDeviceDescriptionKey(rawValue: "NSScreenNumber")] as? Int ?? 0
        screenName = screen.localizedName
        edgeInset = NSEdgeInsetsZero
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.screenID == rhs.screenID
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

    init(from dict: [String: Any]) {
        screenID = dict[JSONKey.screenID.rawValue] as? Int ?? 0
        screenName = dict[JSONKey.screenName.rawValue] as? String
        edgeInset = NSEdgeInsetsMake(dict[JSONKey.top.rawValue] as? CGFloat ?? 0,
                                     dict[JSONKey.left.rawValue] as? CGFloat ?? 0,
                                     dict[JSONKey.bottom.rawValue] as? CGFloat ?? 0,
                                     dict[JSONKey.right.rawValue] as? CGFloat ?? 0)
    }
}
