import QtQuick
import qs.Common

QtObject {
    function check(done) {
        Proc.runCommand("spotlightWallpapers.depCheck", ["sh", "-c", "command -v curl"], (stdout, exitCode) => {
            if (exitCode === 0) {
                done(null);
                return;
            }
            done({
                "title": I18n.tr("curl is required"),
                "details": I18n.tr("Install 'curl' and re-enable this plugin.")
            });
        });
    }
}
