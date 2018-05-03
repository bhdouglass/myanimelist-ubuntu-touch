import QtQuick 2.4
import Qt.labs.settings 1.0
import Ubuntu.Components 1.3
import Ubuntu.Web 0.2
import Ubuntu.Components.Popups 1.3
import com.canonical.Oxide 1.0 as Oxide

import "Components" as Components

MainView {
    id: root
    objectName: 'mainView'
    applicationName: 'myanimelist.bhdouglass'

    automaticOrientation: true

    width: units.gu(50)
    height: units.gu(75)

    Settings {
        id: settings
        property string lastUrl: 'https://myanimelist.net'
        property string username
        property int defaultAnimeList: 0
        property int defaultMangaList: 0
    }

    Page {
        id: page
        anchors {
            fill: parent
            bottom: parent.bottom
        }
        width: parent.width
        height: parent.height

        header: PageHeader {
            id: header
            visible: false
        }

        WebContext {
            id: webcontext
            userAgent: 'Mozilla/5.0 (Linux; Android 5.0; Nexus 5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.102 Mobile Safari/537.36 Ubuntu Touch Webapp'
        }

        WebView {
            id: webview
            anchors {
                top: parent.top
                bottom: nav.top
            }
            width: parent.width
            height: parent.height

            context: webcontext
            url: settings.lastUrl
            onUrlChanged: {
                var strUrl = url.toString();
                if (settings.lastUrl != strUrl && strUrl.match('(http|https)://myanimelist.net/(.*)')) {
                    settings.lastUrl = strUrl;
                }
            }
            preferences.localStorageEnabled: true
            preferences.appCacheEnabled: true

            function navigationRequestedDelegate(request) {
                var url = request.url.toString();
                var isvalid = false;

                if (!url.match('(http|https)://myanimelist.net/(.*)')) {
                    Qt.openUrlExternally(url);
                    request.action = Oxide.NavigationRequest.ActionReject;
                }
            }

            Component.onCompleted: {
                preferences.localStorageEnabled = true;
            }
        }

        ProgressBar {
            height: units.dp(3)
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }

            showProgressPercentage: false
            value: (webview.loadProgress / 100)
            visible: (webview.loading && !webview.lastLoadStopped)
        }

        Components.BottomNavigationBar {
            id: nav

            function animeList() {
                if (settings.username) {
                    var url = 'https://myanimelist.net/animelist/' + settings.username;
                    if (settings.defaultAnimeList == 0) {
                        url += '?status=7';
                    }
                    else if (settings.defaultAnimeList == 1) {
                        url += '?status=1';
                    }
                    else if (settings.defaultAnimeList == 2) {
                        url += '?status=2';
                    }
                    else if (settings.defaultAnimeList == 3) {
                        url += '?status=3';
                    }
                    else if (settings.defaultAnimeList == 4) {
                        url += '?status=4';
                    }
                    else if (settings.defaultAnimeList == 5) {
                        url += '?status=6';
                    }

                    return url;
                }

                return null;
            }

            function mangaList() {
                if (settings.username) {
                    var url = 'https://myanimelist.net/mangalist/' + settings.username;
                    if (settings.defaultMangaList == 0) {
                        url += '?status=7';
                    }
                    else if (settings.defaultMangaList == 1) {
                        url += '?status=1';
                    }
                    else if (settings.defaultMangaList == 2) {
                        url += '?status=2';
                    }
                    else if (settings.defaultMangaList == 3) {
                        url += '?status=3';
                    }
                    else if (settings.defaultMangaList == 4) {
                        url += '?status=4';
                    }
                    else if (settings.defaultMangaList == 5) {
                        url += '?status=6';
                    }

                    return url;
                }

                return null;
            }

            selectedIndex: -1 // Don't show any items as active
            model: [
                {
                    'name': i18n.tr('Home'),
                    'iconName': 'home',
                    'url': 'https://myanimelist.net',
                },
                {
                    'name': i18n.tr('Anime List'),
                    'iconName': 'view-list-symbolic',
                    'url': animeList(),
                },
                {
                    'name': i18n.tr('Manga List'),
                    'iconName': 'view-list-symbolic',
                    'url': mangaList(),
                },
                {
                    'name': i18n.tr('Settings'),
                    'iconName': 'settings',
                    'url': null,
                }
            ]

            onTabThumbClicked: {
                if (model[index].url) {
                    webview.url = model[index].url;
                }
                else {
                    PopupUtils.open(settingsComponent, root, {
                        username: settings.username,
                        defaultAnimeList: settings.defaultAnimeList,
                        defaultMangaList: settings.defaultMangaList,
                    });
                }
            }
        }
    }

    Component {
        id: settingsComponent

        Dialog {
            id: settingsDialog
            text: i18n.tr('Settings')

            property alias username: user.text
            property alias defaultAnimeList: defaultAnime.selectedIndex
            property alias defaultMangaList: defaultManga.selectedIndex

            function save() {
                settings.username = user.text;
                settings.defaultAnimeList = defaultAnime.selectedIndex;
                settings.defaultMangaList = defaultManga.selectedIndex;
                PopupUtils.close(settingsDialog);
            }

            Label {
                text: i18n.tr('MAL username')
            }

            TextField {
                id: user
                width: parent.width
                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase

                onAccepted: settingsDialog.save()
            }

            OptionSelector {
                id: defaultAnime
                text: i18n.tr('Default Anime List')
                model: [
                    i18n.tr('All'),
                    i18n.tr('Watching'),
                    i18n.tr('Completed'),
                    i18n.tr('On Hold'),
                    i18n.tr('Dropped'),
                    i18n.tr('Plan to Watch'),
                ]
            }

            OptionSelector {
                id: defaultManga
                text: i18n.tr('Default Manga List')
                model: [
                    i18n.tr('All'),
                    i18n.tr('Reading'),
                    i18n.tr('Completed'),
                    i18n.tr('On Hold'),
                    i18n.tr('Dropped'),
                    i18n.tr('Plan to Read'),
                ]
            }

            Button {
                text: i18n.tr('OK')
                color: UbuntuColors.green

                onClicked: settingsDialog.save()
            }
        }
    }

    Connections {
        target: UriHandler
        onOpened: {
            webview.url = uris[0];
        }
    }

    Component.onCompleted: {
        if (Qt.application.arguments[1] && Qt.application.arguments[1].indexOf('myanimelist.net') >= 0) {
            webview.url = Qt.application.arguments[1];
        }
    }
}
