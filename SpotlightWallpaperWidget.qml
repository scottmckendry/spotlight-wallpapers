import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    layerNamespacePlugin: "spotlight-wallpaper"

    readonly property string placement: "88000820"
    readonly property string country: pluginData.country || "US"
    readonly property string locale: pluginData.locale || "en-US"
    readonly property string wallpaperDir: pluginData.wallpaperDir || (Quickshell.env("HOME") + "/Pictures/Wallpapers/Spotlight")
    readonly property string apiUrl: "https://fd.api.iris.microsoft.com/v4/api/selection?placement="
        + encodeURIComponent(placement) + "&country=" + encodeURIComponent(country)
        + "&locale=" + encodeURIComponent(locale) + "&fmt=json"

    property string state: "idle"
    property string title: "Windows Spotlight"
    property string description: ""
    property string copyright: ""
    property string location: ""
    property string imageUrl: ""
    property string destination: ""
    property string errorText: ""

    property var savedMeta: ({})

    function saveMeta(dest, meta) {
        savedMeta[dest] = meta
        pluginService?.savePluginState(pluginId, "wallpaperMeta", savedMeta)
    }

    function restoreMeta(dest) {
        const meta = savedMeta[dest]
        if (meta) {
            title = meta.title || "Windows Spotlight"
            description = meta.description || ""
            copyright = meta.copyright || ""
            location = meta.location || ""
            imageUrl = meta.imageUrl || ""
            destination = dest
            state = "ready"
            return true
        }
        return false
    }

    property bool _initialised: false

    function loadState() {
        if (_initialised || !pluginService)
            return
        _initialised = true
        savedMeta = pluginService.loadPluginState(pluginId, "wallpaperMeta", {}) || {}
        if (SessionData.wallpaperPath && restoreMeta(SessionData.wallpaperPath))
            return
        destination = SessionData.wallpaperPath || ""
    }

    onPluginServiceChanged: loadState()
    Component.onCompleted: loadState()

    Connections {
        target: SessionData
        function onWallpaperPathChanged() {
            if (!_initialised)
                return
            const path = SessionData.wallpaperPath
            if (path && path !== destination && savedMeta[path]) {
                restoreMeta(path)
            } else if (path && path !== destination) {
                title = "Windows Spotlight"
                description = ""
                copyright = ""
                location = ""
                imageUrl = ""
                destination = ""
                state = "idle"
            }
        }
    }

    readonly property bool busy: state === "fetching" || state === "downloading"
    readonly property string statusText: {
        if (state === "fetching") return "Finding wallpaper…"
        if (state === "downloading") return "Downloading…"
        if (state === "failed") return errorText
        return location || "Get a new Windows Spotlight wallpaper"
    }
    readonly property string iconName: state === "failed" ? "error" : busy ? "progress_activity" : "wallpaper"
    readonly property color iconColor: state === "failed" ? Theme.error : busy ? Theme.primary : Theme.surfaceText

    function filenameFor(locationName) {
        const slug = locationName.toLowerCase().replace(/[^a-z0-9 ]/g, "").trim().replace(/ +/g, "-")
        return (slug || "spotlight-" + Date.now()) + ".jpg"
    }

    function fetchWallpaper() {
        if (busy)
            return

        state = "fetching"
        errorText = ""
        const request = new XMLHttpRequest()
        request.open("GET", apiUrl)
        request.onreadystatechange = function() {
            if (request.readyState !== XMLHttpRequest.DONE)
                return
            if (request.status < 200 || request.status >= 300) {
                root.state = "failed"
                root.errorText = "Spotlight API returned " + request.status
                return
            }
            try {
                const ad = JSON.parse(request.responseText).ad
                const url = ad?.landscapeImage?.asset ?? ""
                const hoverText = ad?.iconHoverText ?? ""
                const place = hoverText.split("\r\n")[0] || ad?.title || "Windows Spotlight"
                if (!url)
                    throw new Error("No landscape image returned")
                root.title = ad?.title || "Windows Spotlight"
                root.description = ad?.description || ""
                root.copyright = ad?.copyright || ""
                root.location = place
                root.imageUrl = url
                root.destination = root.wallpaperDir + "/" + root.filenameFor(place)
                root.state = "downloading"
                downloadProcess.running = true
            } catch (error) {
                root.state = "failed"
                root.errorText = "Invalid Spotlight response: " + error.message
            }
        }
        request.send()
    }

    function applyWallpaper() {
        saveMeta(destination, {
            title: title,
            description: description,
            copyright: copyright,
            location: location,
            imageUrl: imageUrl
        })
        SessionData.setWallpaper(destination)
        state = "ready"
        ToastService.showInfo("Spotlight Wallpaper", title + (location ? " — " + location : ""))
    }

    Process {
        id: downloadProcess
        command: ["curl", "--fail", "--location", "--silent", "--show-error", "--create-dirs",
            "--user-agent", root.userAgent, "--output", root.destination, root.imageUrl]
        onExited: exitCode => {
            if (exitCode === 0) {
                root.applyWallpaper()
            } else {
                root.state = "failed"
                root.errorText = "Download failed (curl exit " + exitCode + ")"
            }
        }
    }

    horizontalBarPill: Component {
        DankIcon {
            name: root.iconName
            size: root.iconSize
            color: root.iconColor
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    verticalBarPill: Component {
        DankIcon {
            name: root.iconName
            size: root.iconSize
            color: root.iconColor
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popout
            headerText: root.title
            detailsText: root.state === "failed" ? root.errorText : (root.location || "")
            showCloseButton: true

            Column {
                width: parent.width
                spacing: Theme.spacingM

                Image {
                    width: parent.width
                    height: 200
                    visible: root.imageUrl !== ""
                    source: root.imageUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                }

                StyledText {
                    width: parent.width
                    visible: root.description !== ""
                    text: root.description
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.WordWrap
                }

                StyledText {
                    width: parent.width
                    visible: root.copyright !== ""
                    text: root.copyright
                    color: Theme.surfaceVariantText
                    font.pixelSize: Theme.fontSizeSmall
                }

                DankButton {
                    width: parent.width
                    text: root.busy ? root.statusText : "Fetch New Wallpaper"
                    iconName: root.busy ? "progress_activity" : "refresh"
                    enabled: !root.busy
                    onClicked: root.fetchWallpaper()
                }

                StyledText {
                    width: parent.width
                    visible: root.state === "failed"
                    text: root.errorText
                    color: Theme.error
                    font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    popoutWidth: 420
    popoutHeight: 520
}
