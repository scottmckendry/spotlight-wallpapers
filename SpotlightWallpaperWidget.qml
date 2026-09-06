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

    readonly property string placement: "88000820" // Public subscription ID for Windows Spotlight
    readonly property string country: pluginData.country || "US"
    readonly property string locale: pluginData.locale || "en-US"
    // expand a leading ~ since curl won't
    function expandPath(path) {
        const home = Quickshell.env("HOME")
        if (path === "~")
            return home
        if (path.startsWith("~/"))
            return home + path.slice(1)
        return path
    }

    readonly property string wallpaperDir: expandPath(pluginData.wallpaperDir || "~/Pictures/Wallpapers/Spotlight")
    readonly property string apiUrl: "https://fd.api.iris.microsoft.com/v4/api/selection?placement="
        + encodeURIComponent(placement) + "&country=" + encodeURIComponent(country)
        + "&locale=" + encodeURIComponent(locale) + "&fmt=json"

    // fetch lifecycle: "idle" | "fetching" | "downloading" | "ready" | "failed"
    property string fetchState: "idle"
    property string title: "Windows Spotlight"
    property string description: ""
    property string copyright: ""
    property string location: ""
    property string imageUrl: ""
    property string destination: ""
    property string errorText: ""

    property var savedMeta: ({})
    property bool _initialised: false

    function setDisplay(meta, dest) {
        title = meta.title || "Windows Spotlight"
        description = meta.description || ""
        copyright = meta.copyright || ""
        location = meta.location || ""
        imageUrl = meta.imageUrl || ""
        destination = dest
        fetchState = "ready"
    }

    function resetDisplay() {
        title = "Windows Spotlight"
        description = ""
        copyright = ""
        location = ""
        imageUrl = ""
        destination = ""
        errorText = ""
        fetchState = "idle"
    }

    function saveMeta(dest) {
        savedMeta[dest] = {
            title: title,
            description: description,
            copyright: copyright,
            location: location,
            imageUrl: imageUrl
        }
        pluginService?.savePluginState(pluginId, "wallpaperMeta", savedMeta)
    }

    function restoreMeta(dest) {
        const meta = savedMeta[dest]
        if (!meta)
            return false
        setDisplay(meta, dest)
        return true
    }

    function loadState() {
        if (_initialised || !pluginService)
            return
        _initialised = true
        savedMeta = pluginService.loadPluginState(pluginId, "wallpaperMeta", {}) || {}
        const path = SessionData.wallpaperPath
        if (!(path && restoreMeta(path)))
            destination = path || ""
    }

    onPluginServiceChanged: loadState()
    Component.onCompleted: loadState()

    Connections {
        target: SessionData
        function onWallpaperPathChanged() {
            if (!_initialised)
                return
            const path = SessionData.wallpaperPath
            if (path === destination)
                return
            if (!restoreMeta(path))
                resetDisplay()
        }
    }

    readonly property bool busy: fetchState === "fetching" || fetchState === "downloading"
    readonly property string statusText: {
        if (fetchState === "fetching") return "Finding wallpaper…"
        if (fetchState === "downloading") return "Downloading…"
        if (fetchState === "failed") return errorText
        return location || "Get a new Windows Spotlight wallpaper"
    }
    readonly property string iconName: fetchState === "failed" ? "error" : busy ? "progress_activity" : "wallpaper"
    readonly property color iconColor: fetchState === "failed" ? Theme.error : busy ? Theme.primary : Theme.surfaceText

    function filenameFor(locationName) {
        const slug = locationName.toLowerCase().replace(/[^a-z0-9 ]/g, "").trim().replace(/ +/g, "-")
        return (slug || "spotlight-" + Date.now()) + ".jpg"
    }

    function fetchWallpaper() {
        if (busy)
            return

        fetchState = "fetching"
        errorText = ""
        const request = new XMLHttpRequest()
        request.open("GET", apiUrl)
        request.onreadystatechange = function() {
            if (request.readyState !== XMLHttpRequest.DONE)
                return
            if (request.status < 200 || request.status >= 300) {
                root.fail("Spotlight API returned " + request.status)
                return
            }
            try {
                const ad = JSON.parse(request.responseText).ad
                const url = ad?.landscapeImage?.asset ?? ""
                const place = ad?.iconHoverText?.split("\r\n")[0] || ad?.title || "Windows Spotlight"
                if (!url)
                    throw new Error("No landscape image returned")
                root.title = ad?.title || "Windows Spotlight"
                root.description = ad?.description || ""
                root.copyright = ad?.copyright || ""
                root.location = place
                root.imageUrl = url
                root.destination = root.wallpaperDir + "/" + root.filenameFor(place)
                root.fetchState = "downloading"
                downloadProcess.running = true
            } catch (error) {
                root.fail("Invalid Spotlight response: " + error.message)
            }
        }
        request.send()
    }

    function fail(message) {
        fetchState = "failed"
        errorText = message
    }

    function applyWallpaper() {
        saveMeta(destination)
        SessionData.setWallpaper(destination)
        fetchState = "ready"
        ToastService.showInfo("Spotlight Wallpaper", title + (location ? " — " + location : ""))
    }

    Process {
        id: downloadProcess
        command: ["curl", "--fail", "--location", "--silent", "--show-error", "--create-dirs",
            "--output", root.destination, root.imageUrl]
        onExited: exitCode => {
            if (exitCode === 0)
                root.applyWallpaper()
            else
                root.fail("Download failed (curl exit " + exitCode + ")")
        }
    }

    horizontalBarPill: Component {
        Item {
            implicitWidth: root.iconSize
            implicitHeight: root.iconSize
            anchors.verticalCenter: parent.verticalCenter

            DankIcon {
                id: hIcon
                name: root.iconName
                size: root.iconSize
                color: root.iconColor
                anchors.centerIn: parent
                Behavior on rotation { NumberAnimation { duration: 200 } }
            }
            RotationAnimation {
                target: hIcon
                running: root.busy
                from: 0
                to: 360
                duration: 1000
                loops: Animation.Infinite
            }
            states: State {
                when: !root.busy
                PropertyChanges { hIcon.rotation: 0 }
            }
        }
    }

    verticalBarPill: Component {
        Item {
            implicitWidth: root.iconSize
            implicitHeight: root.iconSize
            anchors.horizontalCenter: parent.horizontalCenter

            DankIcon {
                id: vIcon
                name: root.iconName
                size: root.iconSize
                color: root.iconColor
                anchors.centerIn: parent
                Behavior on rotation { NumberAnimation { duration: 200 } }
            }
            RotationAnimation {
                target: vIcon
                running: root.busy
                from: 0
                to: 360
                duration: 1000
                loops: Animation.Infinite
            }
            states: State {
                when: !root.busy
                PropertyChanges { vIcon.rotation: 0 }
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popout
            headerText: root.title
            detailsText: root.fetchState === "failed" ? root.errorText : root.location
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
                    iconName: root.busy ? "hourglass_empty" : "refresh"
                    enabled: !root.busy
                    onClicked: root.fetchWallpaper()
                }
            }
        }
    }

    popoutWidth: 420
    popoutHeight: 520
}
