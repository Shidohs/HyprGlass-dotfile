pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Hyprland
import qs.services

Item {
    id: root

    property var shellRoot: null
    property var keybindsLoader: null

    GlobalShortcut {
        name: "take_screenshot"
        description: "Screenshot capture"

        onPressed: {
            if (!root.shellRoot || root.shellRoot.screenshotActive)
                return;

            console.log("[Shell] Screenshot requested");
            root.shellRoot.screenshotActive = true;
        }
    }

    GlobalShortcut {
        name: "power_menu"
        description: "Power menu"

        onPressed: {
            console.log("[Shell] Power menu requested");
            PowerService.showOverlay();
        }
    }

    GlobalShortcut {
        name: "app_launcher"
        description: "App Launcher"

        onPressed: LauncherService.show()
    }

    GlobalShortcut {
        name: "quick_settings"
        description: "Quick Settings"

        onPressed: QuickSettingsService.show("dashboard")
    }

    GlobalShortcut {
        name: "volume_up"
        description: "Increase volume"

        onPressed: {
            AudioService.increaseVolume();
            OsdService.showVolume(AudioService.volume, AudioService.muted);
        }
    }

    GlobalShortcut {
        name: "volume_down"
        description: "Decrease volume"

        onPressed: {
            AudioService.decreaseVolume();
            OsdService.showVolume(AudioService.volume, AudioService.muted);
        }
    }

    GlobalShortcut {
        name: "volume_mute"
        description: "Mute volume"

        onPressed: {
            AudioService.toggleMute();
            OsdService.showVolume(AudioService.volume, AudioService.muted);
        }
    }

    GlobalShortcut {
        name: "brightness_up"
        description: "Increase brightness"

        onPressed: {
            BrightnessService.increaseBrightness();
            OsdService.showBrightness(BrightnessService.brightness);
        }
    }

    GlobalShortcut {
        name: "brightness_down"
        description: "Decrease brightness"

        onPressed: {
            BrightnessService.decreaseBrightness();
            OsdService.showBrightness(BrightnessService.brightness);
        }
    }

    GlobalShortcut {
        name: "wallpaper_picker"
        description: "Wallpaper picker"

        onPressed: WallpaperService.toggle()
    }

    GlobalShortcut {
        name: "clipboard_history"
        description: "Clipboard history"

        onPressed: {
            console.log("[Shell] Clipboard shortcut pressed");
            ClipboardService.toggle();
        }
    }

    GlobalShortcut {
        name: "orbit_assistant"
        description: "Orbit assistant"

        onPressed: AiService.toggleWindow()
    }

    GlobalShortcut {
        name: "keybinds_help"
        description: "Keybinds help"

        onPressed: root.keybindsLoader.toggle()
    }
}
