//
//  SettingViewController.swift
//  EdgeWindow
//
//  Created by WeiHan on 2024/8/8.
//

import Cocoa
import ServiceManagement

class SettingViewController: NSViewController {

    @IBOutlet weak var btnStartAtLogin: NSButton!

    @IBOutlet weak var popupScreens: NSPopUpButton!

    @IBOutlet weak var tfTop: NSTextField!
    @IBOutlet weak var tfLeft: NSTextField!
    @IBOutlet weak var tfBottom: NSTextField!
    @IBOutlet weak var tfRight: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        let numberFormatter = IntegerValueFormatter.init { formatter in
            formatter.numberStyle = .decimal
            formatter.usesSignificantDigits = false
        }

        btnStartAtLogin.state = getLoginItemStatus() ? .on : .off

        tfTop.formatter = numberFormatter
        tfLeft.formatter = numberFormatter
        tfBottom.formatter = numberFormatter
        tfRight.formatter = numberFormatter

        Configuration.shared.load()
        popupScreens.addItems(withTitles: Configuration.shared.screens.map { $0.screenName ?? "<Unknown screen>"})
        Logger.debug("Loaded \(popupScreens.itemTitles.count) screen(s) in total.")

        popupScreens.selectItem(at: 0)
        onPopupScreenChanged(self)
    }

    @IBAction func onStartAtLoginButtonClicked(_ sender: Any) {
        setLoginItem(enabled: btnStartAtLogin.state == .on)
    }

    @IBAction func onPopupScreenChanged(_ sender: Any) {
        let idx = popupScreens.indexOfSelectedItem
        let screen = Configuration.shared.screens[idx]

        tfTop.stringValue = String(format: "%.2f", screen.edgeInset.top)
        tfLeft.stringValue = String(format: "%.2f", screen.edgeInset.left)
        tfBottom.stringValue = String(format: "%.2f", screen.edgeInset.bottom)
        tfRight.stringValue = String(format: "%.2f", screen.edgeInset.right)
    }
}

extension SettingViewController {

    private enum PreferenceKey: String {
        case loginItemStatus
    }

    func setLoginItem(enabled: Bool) {
        let launcherAppIdentifier = Bundle.main.bundleIdentifier!
        let success = SMLoginItemSetEnabled(launcherAppIdentifier as CFString, enabled)

        if success {
            UserDefaults.standard.set(enabled, forKey: PreferenceKey.loginItemStatus.rawValue)
            UserDefaults.standard.synchronize()
            Logger.info("Login item set to \(enabled)")
        } else {
            btnStartAtLogin.state = enabled ? .off : .on
            Logger.error("Failed to set login item")
        }
    }

    func getLoginItemStatus() -> Bool {
        UserDefaults.standard.bool(forKey: PreferenceKey.loginItemStatus.rawValue)
    }
}

extension SettingViewController: NSTextFieldDelegate {

    func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else {
            return
        }

        let idx = popupScreens.indexOfSelectedItem
        let screen = Configuration.shared.screens[idx]

        if textField == tfTop {
            screen.edgeInset.top = CGFloat(textField.floatValue)
        } else if textField == tfLeft {
            screen.edgeInset.left = CGFloat(textField.floatValue)
        } else if textField == tfBottom {
            screen.edgeInset.bottom = CGFloat(textField.floatValue)
        } else if textField == tfRight {
            screen.edgeInset.right = CGFloat(textField.floatValue)
        }

        Logger.debug("Saved \(screen.descriptions)")
        Configuration.shared.save()
    }
}

/// Refer to https://stackoverflow.com/a/75471535/1677041
class IntegerValueFormatter: NumberFormatter {

    init(_ closure: (IntegerValueFormatter) -> Void) {
        super.init()
        closure(self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func isPartialStringValid(_ partialString: String, newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {

        // Ability to reset your field (otherwise you can't delete the content)
        // You can check if the field is empty later
        if partialString.isEmpty {
            return true
        }

        guard let val = Int(partialString), val < maximum as? Int ?? Int.max else {
            return false
        }

        return true
     }
}

