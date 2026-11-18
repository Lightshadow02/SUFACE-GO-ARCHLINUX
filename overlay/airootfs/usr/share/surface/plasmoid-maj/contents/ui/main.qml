// Icône « Mises à jour » de la zone de notification.
// Lit le compteur écrit par surface-updates-check (~/.cache/surface-updates) :
// visible seulement s'il y a des mises à jour ; un clic ouvre Konsole avec « maj ».
import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    property int count: 0
    property string details: ""
    readonly property string lireCmd: "cat \"${XDG_CACHE_HOME:-$HOME/.cache}/surface-updates\" 2>/dev/null"
    readonly property string majCmd: "konsole -e /usr/local/bin/maj"

    Plasmoid.icon: "system-software-update"
    Plasmoid.title: "Mises à jour"
    // Passif = rangé dans les entrées masquées ; Actif = visible dans la barre
    Plasmoid.status: count > 0 ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.PassiveStatus

    toolTipMainText: count > 0 ? count + " mise(s) à jour disponible(s)" : "Système à jour"
    toolTipSubText: count > 0 ? details + "\nTouche pour mettre à jour" : "Touche pour vérifier quand même"

    preferredRepresentation: compactRepresentation
    compactRepresentation: Kirigami.Icon {
        source: Plasmoid.icon
        active: zone.containsMouse
        MouseArea {
            id: zone
            anchors.fill: parent
            hoverEnabled: true
            onClicked: exec.connectSource(root.majCmd)
        }
    }

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            if (source === root.lireCmd) {
                const lignes = (data["stdout"] || "").trim().split("\n")
                root.count = parseInt(lignes[0]) || 0
                root.details = lignes[1] || ""
            }
            disconnectSource(source)
            // Konsole fermée après « maj » : on relit le compteur tout de suite
            if (source === root.majCmd) {
                connectSource(root.lireCmd)
            }
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: exec.connectSource(root.lireCmd)
    }
}
