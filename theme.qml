// skylineOS

import QtQuick 2.12
import QtQuick.Layouts 1.11
import SortFilterProxyModel 0.2
import QtMultimedia 5.9
import QtGraphicalEffects 1.12
import "qrc:/qmlutils" as PegasusUtils
import "utils.js" as Utils
import "layer_home"
import "layer_grid"
import "layer_settings"
import "layer_help"
import "Lists"
import "resources" as Resources

FocusScope {
    id: root

    // Load settings
    property var settings: {
        return {
            gameBackground:         api.memory.has("Game Background") ? api.memory.get("Game Background") : "Screenshot",
            timeFormat:             api.memory.has("Time Format") ? api.memory.get("Time Format") : "12hr",
            wordWrap:               api.memory.has("Word Wrap on Titles") ? api.memory.get("Word Wrap on Titles") : "Yes",
            batteryPercentSetting:  api.memory.has("Display Battery Percentage") ? api.memory.get("Display Battery Percentage") : "No",
            enableDropShadows:      api.memory.has("Enable DropShadows") ? api.memory.get("Enable DropShadows") : "Yes",
            playBGM:                api.memory.has("Background Music") ? api.memory.get("Background Music") : "No",
            softCount:              api.memory.has("Number of recent games") ? api.memory.get("Number of recent games") : 12,
            homeView:               api.memory.has("Home view") ? api.memory.get("Home view") : "Systems",
        }
    }

    // number of games that appear on the recentScreen, not including the All Software button
    property int softCount: settings.softCount
    property string homeView: settings.homeView

    ListLastPlayed  { id: listRecent; max: softCount}
    ListLastPlayed  { id: listByLastPlayed}
    ListMostPlayed  { id: listByMostPlayed}
    ListPublisher   { id: listByPublisher}
    ListFavorites   { id: listFavorites}
    ListAllGames    { id: listByTitle}
    Resources.Music { id: music}

    property int currentCollection: api.memory.has('Last Collection') ? api.memory.get('Last Collection') : -1
    property int nextCollection: api.memory.has('Last Collection') ? api.memory.get('Last Collection') : -1
    property var currentGame
    property var softwareList: [listByLastPlayed, listByMostPlayed, listByTitle, listByPublisher]
    property int sortByIndex: api.memory.has('sortIndex') ? api.memory.get('sortIndex') : 0
    property string searchtext
    property bool wordWrap: (settings.wordWrap === "Yes") ? true : false;
    property bool showPercent: (settings.batteryPercentSetting === "Yes") ? true : false;
    property bool enableDropShadows: (settings.enableDropShadows === "Yes") ? true: false;
    property bool playBGM: (settings.playBGM === "Yes") ? true : false;

    onNextCollectionChanged: { changeCollection() }

    function changeCollection() {
        if (nextCollection != currentCollection) {
            currentCollection = nextCollection;
            searchtext = ""
            //gameGrid.currentIndex = 0;
        }
    }

    property int collectionIndex: 0
    property int currentGameIndex: 0
    property int screenmargin: vpx(30)
    property real screenwidth: width
    property real screenheight: height
    property bool widescreen: ((height/width) < 0.7)
    property real helpbarheight: Math.round(screenheight * 0.1041) // Calculated manually based on mockup
    property bool darkThemeActive

    function showSoftwareScreen() {
        softwareScreen.focus = true;
        toSoftware.play();
    }
    
    function showFavoritesScreen() {
        favoritesScreen.focus = true;
        toSoftware.play();
    }
    
    function showSystemsScreen() {
        systemsScreen.focus = true;
        toSoftware.play();
    }

    function showSettingsScreen() {
        settingsScreen.focus = true;
        settingsSfx.play();
    }

    function showRecentScreen() {
        recentScreen.focus = true;
        currentCollection = -1
        homeSfx.play()
    }

    function playGame() {
        root.state = "PLAYGAME"

        launchSfx.play()
    }

    function playSoftware() {
        root.state = "PLAYSOFTWARE"

        launchSfx.play()
    }

    // Launch the current game from RecentList
    function launchGame(game) {
        api.memory.set('Last Collection', currentCollection);
        if (game != null)
            game.launch();
        else
            currentGame.launch();
    }

    // Launch current game from SoftwareScreen
    function launchSoftware() {
        api.memory.set('Last Collection', currentCollection);
        softwareList[sortByIndex].currentGame(currentGameIndex).launch();
            //currentGame.launch();
    }
    
    // Preference order for Game Backgrounds, tiles always come first due to assumption that it's set manually
    function getGameBackground(gameData, preference){
        switch (preference) {
            case "Screenshot":
                return gameData ? gameData.assets.tile || gameData.assets.screenshots[0] || gameData.assets.background || gameData.assets.boxFront || "" : "";
            case "Fanart":
                return gameData ? gameData.assets.tile || gameData.assets.background || gameData.assets.screenshots[0] || gameData.assets.boxFront || "" : "";
            case "Boxart":
                return gameData ? gameData.assets.tile || gameData.assets.boxFront || gameData.assets.screenshots[0] || gameData.assets.background || "" : "";
            default:
                return ""
        }
    }

    // Theme settings
    FontLoader { id: titleFont; source: "assets/fonts/Nintendo_Switch_UI_Font.ttf" }

    property var themeLight: {
        return {
            main: "#EBEBEB",
            secondary: "#2D2D2D",
            accent: "#10AEBE",
            highlight: "white",
            text: "#2C2C2C",
            button: "white",
            icon: "#7e7e7e",
            press: "#7Fc0f0f3"
        }
    }

    property var themeDark: {
        return {
            main: "#2D2D2D",
            secondary: "#EBEBEB",
            accent: "#1d9bf3",
            highlight: "black",
            text: "white",
            button: "#515151",
            icon: "white",
            press: "#591d9bf3"
        }
    }

    property var theme : api.memory.get('theme') === 'themeLight' ? themeLight : themeDark ;

    function toggleDarkMode(){
        if(theme === themeLight) {
            api.memory.set('theme', 'themeDark');
        } else {
            api.memory.set('theme', 'themeLight');
        }
    }

    // State settings
    states: [
        State {
            name: "RECENT"; when: recentScreen.focus == true
        },
        State {
            name: "FAVORITES"; when: favoritesScreen.focus == true
        },
        State {
            name: "SYSTEMS"; when: systemsScreen.focus == true
        },
        State {
            name: "SOFTWARE"; when: softwareScreen.focus == true
        },
        State {
            name: "SETTINGS"; when: settingsScreen.focus == true
        },
        State {
            name: "PLAYGAME";
        },
        State {
            name: "PLAYSOFTWARE";
        }
    ]

    property int currentScreenID: -3

    transitions: [
        Transition {
            to: "FAVORITES"
            SequentialAnimation {
                PropertyAnimation { target: recentScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: recentScreen; property: "visible"; value: false }
                PropertyAnimation { target: favoritesScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: favoritesScreen; property: "visible"; value: false }
                PropertyAnimation { target: systemsScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: systemsScreen; property: "visible"; value: false }
                PropertyAnimation { target: softwareScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: softwareScreen; property: "visible"; value: false }
                PropertyAnimation { target: settingsScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: settingsScreen; property: "visible"; value: false }
                
                PropertyAction { target: favoritesScreen; property: "visible"; value: true }
                PropertyAnimation { target: favoritesScreen; property: "opacity"; to: 1; duration: 400}
            }
        },
        Transition {
            to: "RECENT"
            SequentialAnimation {
                PropertyAnimation { target: recentScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: recentScreen; property: "visible"; value: false }
                PropertyAnimation { target: favoritesScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: favoritesScreen; property: "visible"; value: false }
                PropertyAnimation { target: systemsScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: systemsScreen; property: "visible"; value: false }
                PropertyAnimation { target: softwareScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: softwareScreen; property: "visible"; value: false }
                PropertyAnimation { target: settingsScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: settingsScreen; property: "visible"; value: false }
                
                PropertyAction { target: recentScreen; property: "visible"; value: true }
                PropertyAnimation { target: recentScreen; property: "opacity"; to: 1; duration: 400}
            }
        },
        Transition {
            to: "SYSTEMS"
            SequentialAnimation {
                PropertyAnimation { target: recentScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: recentScreen; property: "visible"; value: false }
                PropertyAnimation { target: favoritesScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: favoritesScreen; property: "visible"; value: false }
                PropertyAnimation { target: systemsScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: systemsScreen; property: "visible"; value: false }
                PropertyAnimation { target: softwareScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: softwareScreen; property: "visible"; value: false }
                PropertyAnimation { target: settingsScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: settingsScreen; property: "visible"; value: false }
                
                PropertyAction { target: systemsScreen; property: "visible"; value: true }
                PropertyAnimation { target: systemsScreen; property: "opacity"; to: 1; duration: 400}
            }
        },
        Transition {
            to: "SOFTWARE"
            SequentialAnimation {
                PropertyAnimation { target: recentScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: recentScreen; property: "visible"; value: false }
                PropertyAnimation { target: favoritesScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: favoritesScreen; property: "visible"; value: false }
                PropertyAnimation { target: systemsScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: systemsScreen; property: "visible"; value: false }
                PropertyAnimation { target: softwareScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: softwareScreen; property: "visible"; value: false }
                PropertyAnimation { target: settingsScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: settingsScreen; property: "visible"; value: false }
                
                PropertyAction { target: softwareScreen; property: "visible"; value: true }
                PropertyAnimation { target: softwareScreen; property: "opacity"; to: 1; duration: 400}
            }
        },
        Transition {
            to: "SETTINGS"
            SequentialAnimation {
                PropertyAnimation { target: recentScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: recentScreen; property: "visible"; value: false }
                PropertyAnimation { target: favoritesScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: favoritesScreen; property: "visible"; value: false }
                PropertyAnimation { target: systemsScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: systemsScreen; property: "visible"; value: false }
                PropertyAnimation { target: softwareScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: softwareScreen; property: "visible"; value: false }
                PropertyAnimation { target: settingsScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: settingsScreen; property: "visible"; value: false }
                
                PropertyAction { target: settingsScreen; property: "visible"; value: true }
                PropertyAnimation { target: settingsScreen; property: "opacity"; to: 1; duration: 400}
            }
        },
        
        Transition {
            to: "SYSTEMS"
            SequentialAnimation {
                PropertyAnimation { target: recentScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: recentScreen; property: "visible"; value: false }
                PropertyAnimation { target: favoritesScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: favoritesScreen; property: "visible"; value: false }
                PropertyAnimation { target: systemsScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: systemsScreen; property: "visible"; value: false }
                PropertyAnimation { target: softwareScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: softwareScreen; property: "visible"; value: false }
                PropertyAnimation { target: settingsScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: settingsScreen; property: "visible"; value: false }
                
                PropertyAction { target: recentScreen; property: "visible"; value: true }
                PropertyAnimation { target: recentScreen; property: "opacity"; to: 1; duration: 400}
            }
        },
        
        Transition {
            to: "PLAYGAME"
            SequentialAnimation {
                PropertyAnimation { target: recentScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: recentScreen; property: "visible"; value: false }
                PropertyAnimation { target: favoritesScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: favoritesScreen; property: "visible"; value: false }
                PropertyAnimation { target: systemsScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: systemsScreen; property: "visible"; value: false }
                PropertyAnimation { target: softwareScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: softwareScreen; property: "visible"; value: false }
                PropertyAnimation { target: settingsScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: settingsScreen; property: "visible"; value: false }
                
                ScriptAction { script: launchGame(currentGame) }
            }
        },
        Transition {
            to: "PLAYSOFTWARE"
            SequentialAnimation {
                PropertyAnimation { target: recentScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: recentScreen; property: "visible"; value: false }
                PropertyAnimation { target: favoritesScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: favoritesScreen; property: "visible"; value: false }
                PropertyAnimation { target: systemsScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: systemsScreen; property: "visible"; value: false }
                PropertyAnimation { target: softwareScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: softwareScreen; property: "visible"; value: false }
                PropertyAnimation { target: settingsScreen; property: "opacity"; to: 0; duration: 10}
                PropertyAction { target: settingsScreen; property: "visible"; value: false }
                
                ScriptAction { script: launchSoftware() }
            }
        }
    ]


    // Background
    Rectangle {
        id: background
        anchors {
            left: parent.left; right: parent.right
            top: parent.top; bottom: parent.bottom
        }
        color: theme.main
    }
    
    
    // Home screen
    RecentScreen {
        id: recentScreen
        
        opacity: 0
        visible: false
        anchors {
            left: parent.left; right: parent.right
            top: parent.top; bottom: helpBar.top
        }
    }
    
    // Systems screen
    SystemsScreen {
        id: systemsScreen
        
        opacity: 0
        visible: false
        anchors {
            left: parent.left;// leftMargin: screenmargin
            right: parent.right;// rightMargin: screenmargin
            top: parent.top; bottom: helpBar.top
        }
    }

    SettingsScreen {
        id: settingsScreen
        
        opacity: 0
        visible: false
        anchors {
            left: parent.left; leftMargin: screenmargin
            right: parent.right; rightMargin: screenmargin
            top: parent.top; bottom: helpBar.top
        }
    }
    
    // Favorites screen
    FavoritesScreen {
        id: favoritesScreen
        opacity: 0
        visible: false
        anchors {
            left: parent.left;// leftMargin: screenmargin
            right: parent.right;// rightMargin: screenmargin
            top: parent.top; bottom: helpBar.top
        }
    }
    

    // All Software screen
    SoftwareScreen {
        id: softwareScreen
        opacity: 0
        visible: false
        anchors {
            left: parent.left;// leftMargin: screenmargin
            right: parent.right;// rightMargin: screenmargin
            top: parent.top; bottom: helpBar.top
        }
    }
    
    //starting collection is set here
    Component.onCompleted: {
        currentCollection = -1 
        api.memory.unset('Last Collection');
        homeSfx.play()
        if (homeView == "Recent"){
            recentScreen.focus = true
            recentScreen.opacity = 1
            recentScreen.visible = true
        } else {
            systemsScreen.focus = true
            systemsScreen.opacity = 1
            systemsScreen.visible = true
        }
        
    }

    //Changes Sort Option
    function cycleSort() {
        selectSfx.play();
        if (sortByIndex < softwareList.length - 1)
            sortByIndex++;
        else
            sortByIndex = 0;
        api.memory.set('sortIndex', sortByIndex)
    }



    // Help bar
    Item {
        id: helpBar
        anchors {
            left: parent.left; leftMargin: screenmargin
            right: parent.right; rightMargin: screenmargin
            bottom: parent.bottom
        }
        height: helpbarheight

        Rectangle {

            anchors.fill: parent
            color: theme.main
        }

        Rectangle {
            anchors.left: parent.left; anchors.right: parent.right
            height: 1
            color: theme.secondary
        }

        ControllerHelp {
            id: controllerHelp
            width: parent.width
            height: parent.height
            anchors {
                bottom: parent.bottom;
            }
        }

    }

    SoundEffect {
      id: navSound
      source: "assets/audio/Klick.wav"
      volume: 1.0
    }

    SoundEffect {
      id: toSoftware
      source: "assets/audio/EnterBack.wav"
      volume: 1.0
    }

    SoundEffect {
      id: fillList
      source: "assets/audio/Icons.wav"
      volume: 1.0
    }

    SoundEffect {
      id: backSfx
      source: "assets/audio/Nock.wav"
      volume: 1.0
    }

    SoundEffect {
        id: launchSfx
        source: "assets/audio/PopupRunTitle.wav"
        volume: 1.0
    }

    SoundEffect {
        id: homeSfx
        source: "assets/audio/Home.wav"
        volume: 1.0
    }

    SoundEffect {
        id: turnOnSfx
        source: "assets/audio/Turn On.wav"
        volume: 1.0
    }

    SoundEffect {
        id: turnOffSfx
        source: "assets/audio/Turn Off.wav"
        volume: 1.0
    }

    SoundEffect {
        id: selectSfx
        source: "assets/audio/This One.wav"
        volume: 1.0
    }

    SoundEffect {
        id: settingsSfx
        source: "assets/audio/Settings.wav"
        volume: 1.0
    }

    /* This sound effect is broken on RetroPie on Raspberry Pi 4. Reason unknown.
    SoundEffect {  
        id: menuNavSfx
        source: "assets/audio/Tick.wav"
        volume: 1.0
    }*/

    SoundEffect {
        id: borderSfx
        source: "assets/audio/Border.wav"
        volume: 0.25
    }
    

}
