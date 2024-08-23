//
//  AppDelegate.swift
//  EdgeWindow
//
//  Created by WeiHan on 2024/8/8.
//

import Cocoa
import Accessibility

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItem: NSStatusItem!
    var windowObserver: WindowObserver!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "gear", accessibilityDescription: "Edge Window")
        }

        let menu = NSMenu()

        let runItem = NSMenuItem(title: "Trigger", action: #selector(runAction), keyEquivalent: "")
        menu.addItem(runItem)

        let showLogItem = NSMenuItem(title: "Show Log", action: #selector(showLog), keyEquivalent: "")
        menu.addItem(showLogItem)

        menu.addItem(NSMenuItem.separator())

        let configItem = NSMenuItem(title: "Config...", action: #selector(showSetting), keyEquivalent: "")
        menu.addItem(configItem)

        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        // Set the menu for the status item
        statusItem.menu = menu

        if !AXIsProcessTrusted() {
            promptForAccessibilityPermission()
            return
        }

        Configuration.shared.load()

        windowObserver = WindowObserver()
        windowObserver.startObserving()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

extension AppDelegate {
    @objc func runAction() {
        windowObserver.startObserving()
    }

    @objc func showLog() {
        if let logFileURL = Logger.logFileURL {
            NSWorkspace.shared.open(logFileURL)
        }
    }

    @objc func showSetting() {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let wc = storyboard.instantiateController(withIdentifier: "SettingWindow") as? NSWindowController

        wc?.window?.makeKeyAndOrderFront(nil)
        wc?.showWindow(nil)
    }

    @objc func showMenu() {
        Logger.debug("show menu")
    }

    private func promptForAccessibilityPermission() {
        Logger.debug("request accessibility permission")
        let alert = NSAlert()

        alert.messageText = "Enable Accessibility Permission"
        alert.informativeText = "To use Window Restrictor, you need to grant Accessibility permission in System Preferences."
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string:"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }

        NSApp.terminate(nil)
    }
}

