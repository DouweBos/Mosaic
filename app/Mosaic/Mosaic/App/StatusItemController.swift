// App/StatusItemController.swift
// Mosaic
//
// The menu bar item: layouts for the window you're in, arrangements, and settings.

import AppKit
import KeyboardShortcuts

final class StatusItemController: NSObject, NSMenuDelegate {
    private unowned let delegate: AppDelegate
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    init(delegate: AppDelegate) {
        self.delegate = delegate
        super.init()
        let image = NSImage(resource: .menuBarIcon)
        image.isTemplate = true
        image.accessibilityDescription = "Mosaic"
        statusItem.button?.image = image
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    // Rebuilt on every open: it names the frontmost app and marks the active arrangement.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let mover = delegate.mover
        let trusted = WindowAccess.isTrusted

        if !trusted {
            menu.addItem(ActionMenuItem("Grant Accessibility Access…", symbol: "exclamationmark.triangle") { [delegate] in
                WindowAccess.requestTrust()
                delegate.showSettings(tab: .general)
            })
            menu.addItem(.separator())
        }

        for group in Region.groups {
            for region in group {
                let item = ActionMenuItem(region.title, symbol: region.symbol) { mover.snapFocusedWindow(to: region) }
                item.setShortcut(for: KeyboardShortcuts.Name.regions[region])
                item.isAvailable = trusted
                menu.addItem(item)
            }
            menu.addItem(.separator())
        }
        let next = ActionMenuItem("Next Display", symbol: "arrow.right.to.line") { mover.moveFocusedWindow(displayOffset: 1) }
        next.setShortcut(for: .nextDisplay)
        let previous = ActionMenuItem("Previous Display", symbol: "arrow.left.to.line") {
            mover.moveFocusedWindow(displayOffset: -1)
        }
        previous.setShortcut(for: .previousDisplay)
        let restore = ActionMenuItem("Restore", symbol: "arrow.uturn.backward") { mover.restoreFocusedWindow() }
        restore.setShortcut(for: .restore)
        for item in [next, previous, restore] {
            item.isAvailable = trusted
            menu.addItem(item)
        }

        menu.addItem(.separator())
        menu.addItem(arrangementsItem())
        if let app = NSWorkspace.shared.frontmostApplication, let bundleID = app.bundleIdentifier,
           app.processIdentifier != ProcessInfo.processInfo.processIdentifier {
            let ignored = Preferences.ignoredApps.contains(bundleID)
            menu.addItem(ActionMenuItem("Ignore \(app.localizedName ?? bundleID)", symbol: "eye.slash",
                                        state: ignored ? .on : .off) {
                Preferences.setIgnored(bundleID, !ignored)
            })
        }

        menu.addItem(.separator())
        menu.addItem(ActionMenuItem("Settings…", symbol: "gearshape") { [delegate] in delegate.showSettings() })
        menu.addItem(ActionMenuItem("About Mosaic", symbol: "info.circle") {
            NSApp.activate()
            NSApp.orderFrontStandardAboutPanel(nil)
        })
        menu.addItem(.separator())
        menu.addItem(ActionMenuItem("Quit Mosaic", symbol: "xmark.square") { NSApp.terminate(nil) })
    }

    private func arrangementsItem() -> NSMenuItem {
        let submenu = NSMenu()
        let arrangements = delegate.store.arrangements
        let signature = DisplayCatalog.signature
        if arrangements.isEmpty {
            let empty = ActionMenuItem("No Arrangements Yet") {}
            empty.isAvailable = false
            submenu.addItem(empty)
        }
        for arrangement in arrangements {
            let isActive = delegate.engine.active?.id == arrangement.id
            let item = ActionMenuItem(arrangement.name, state: isActive ? .on : .off) { [delegate] in
                delegate.engine.apply(arrangement)
            }
            // Arrangements made for other displays still apply, mapped onto whatever is connected.
            if arrangement.displaySignature != signature {
                item.toolTip = "Made for a different set of displays"
            }
            item.isAvailable = WindowAccess.isTrusted
            submenu.addItem(item)
        }
        submenu.addItem(.separator())
        submenu.addItem(ActionMenuItem("Save Current Layout…", symbol: "camera.viewfinder") { [delegate] in
            delegate.captureArrangement()
        })
        submenu.addItem(ActionMenuItem("Edit Arrangements…", symbol: "slider.horizontal.3") { [delegate] in
            delegate.showSettings(tab: .arrangements)
        })
        let item = NSMenuItem(title: "Arrangements", action: nil, keyEquivalent: "")
        item.image = NSImage(systemSymbolName: "square.grid.2x2", accessibilityDescription: nil)
        item.submenu = submenu
        return item
    }
}
