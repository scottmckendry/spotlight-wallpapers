import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "spotlight-wallpaper"

    StringSetting {
        settingKey: "country"
        label: "Country"
        description: "Two-letter country code sent to Windows Spotlight."
        placeholder: "US"
        defaultValue: "US"
    }

    StringSetting {
        settingKey: "locale"
        label: "Locale"
        description: "Locale sent to Windows Spotlight."
        placeholder: "en-US"
        defaultValue: "en-US"
    }

    StringSetting {
        settingKey: "wallpaperDir"
        label: "Wallpaper Directory"
        description: "Downloaded images are kept here."
        placeholder: "~/Pictures/Wallpapers/Spotlight"
        defaultValue: ""
    }
}
