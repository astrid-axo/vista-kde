#!/bin/bash

set -ouex pipefail

install_component () {
    kpackagetool6 -g -t "$2" -i "$1" || \
    kpackagetool6 -g -t "$2" -u "$1"
}

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1
# this installs a package from fedora repos
dnf -y install ninja plasma-workspace-devel unzip kvantum qt6-qtmultimedia-devel qt6-qt5compat-devel libplasma-devel qt6-qtbase-devel qt6-qtwayland-devel plasma-activities-devel kf6-kpackage-devel kf6-kglobalaccel-devel qt6-qtsvg-devel wayland-devel plasma-wayland-protocols kf6-ksvg-devel kf6-kcrash-devel kf6-kguiaddons-devel kf6-kcmutils-devel kf6-kio-devel kdecoration-devel kf6-ki18n-devel kf6-knotifications-devel kf6-kirigami-devel kf6-kiconthemes-devel cmake gmp-ecm-devel kf5-plasma-devel libepoxy-devel kwin-devel kf6-karchive kf6-karchive-devel plasma-wayland-protocols-devel qt6-qtbase-private-devel qt6-qtbase-devel kf6-knewstuff-devel kf6-knotifyconfig-devel kf6-attica-devel kf6-krunner-devel kf6-kdbusaddons-devel kf6-sonnet-devel plasma5support-devel plasma-activities-stats-devel polkit-qt6-1-devel qt-devel libdrm-devel kf6-kitemmodels-devel kf6-kstatusnotifieritem-devel layer-shell-qt-devel

# fonts
REACTXP="https://github.com/microsoft/reactxp/raw/refs/heads/master/samples/TodoList/src/resources/fonts"
# curl -O https://github.com/mrbvrz/segoe-ui-linux/archive/refs/heads/master.zip
curl -Ls -o /usr/share/fonts/Lucida-Console.ttf https://github.com/elliotwoods/kimchiandchips/raw/refs/heads/master/oF/apps%20VS/PC%20Encode%203.0/bin/data/Lucida%20Console.ttf

fc-cache -f -r -v

git clone --depth 1 https://gitgud.io/catpswin56/vistathemeplasma /tmp/vistathemeplasma
# cp -r /ctx/VistaThemePlasma /tmp/vistathemeplasma
cd /tmp/vistathemeplasma
CUR="$(pwd)"

sh compile.sh --ninja --wayland
# plasmoids
for i in "$CUR/plasma/plasmoids/src/"*; do
    cd "$i"
    sh install.sh --ninja
done

cd $CUR

for i in "$CUR/plasma/plasmoids/"*; do
    if ! echo $i | grep src; then
        install_component "$i" "Plasma/Applet"
    fi
done

for i in "$CUR/plasma/plasmoids/src/"*; do
    cd "$i"
    sh install.sh --ninja
done

cd $CUR

# kwin components
cp -r "$CUR/kwin/smod" "/usr/share"

for i in "$CUR/kwin/effects/"*; do
    install_component "$i" "KWin/Effect"
done

for i in "$CUR/kwin/tabbox/"*; do
    install_component "$i" "KWin/WindowSwitcher"
done

cp -r "$CUR/kwin/outline" "/usr/share/kwin"
cd /usr/share/
ln -s kwin kwin-x11
ln -s kwin kwin-wayland
cd $CUR

# plasma components
cp -r $CUR/plasma/{desktoptheme,look-and-feel,layout-templates,shells} /usr/share/plasma
install_component "$CUR/plasma/look-and-feel/authuiVista" "Plasma/LookAndFeel"
install_component "$CUR/plasma/layout-templates/io.gitgud.catpswin56.taskbar" "Plasma/LayoutTemplate"
install_component "$CUR/plasma/desktoptheme/Vista-Black" "Plasma/Shell"
install_component "$CUR/plasma/shells/io.gitgud.catpswin56.desktop" "Plasma/Shell"

mkdir -p /usr/share/color-schemes
cp $CUR/plasma/color_scheme/Aero.colors /usr/share/color-schemes

cd $CUR/plasma/sddm/login-sessions
sh install.sh --ninja
cd $CUR/plasma/sddm
cp -r sddm-theme-mod /usr/share/sddm/themes
# tar -zcvf "sddm-theme-mod.tar.gz" sddm-theme-mod
# sddmthemeinstaller -i sddm-theme-mod.tar.gz
#rm sddm-theme-mod.tar.gz

cd $CUR
# misc components
cp -r $CUR/misc/kvantum/Kvantum /etc
echo -e "[General]\ntheme=WindowsVistaKvantum_Aero" > /usr/share/Kvantum/kvantum.kvconfig

cd $CUR/misc/libplasma

VERSION="6.5.5"
URL="https://invent.kde.org/plasma/libplasma/-/archive/v${VERSION}/libplasma-v${VERSION}.tar.gz"
ARCHIVE="libplasma-v${VERSION}.tar.gz"
SRCDIR="libplasma-v${VERSION}"

INSTALLDST="/usr/lib/x86_64-linux-gnu/qt6/qml/org/kde/plasma/core/libcorebindingsplugin.so"
LIBDIR="/usr/lib/x86_64-linux-gnu/"

if [ ! -d ${LIBDIR} ]; then
	LIBDIR="/usr/lib64/"
fi

if [ ! -f ${INSTALLDST} ]; then
	INSTALLDST="/usr/lib64/qt6/qml/org/kde/plasma/core/libcorebindingsplugin.so"
fi

if [ ! -d ./build/${SRCDIR} ]; then
	rm -rf build
	mkdir -p build
	echo "Downloading $ARCHIVE"
	curl $URL -o ./build/$ARCHIVE
	tar -xvf ./build/$ARCHIVE -C ./build/
	echo "Extracted $ARCHIVE"
fi

cp -r src ./build/$SRCDIR/
cd ./build/$SRCDIR/
mkdir -p build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr .. -G Ninja
cmake --build . --target corebindingsplugin

TMPDIR="/tmp/kfiles"
mkdir -p $TMPDIR
cp ./bin/org/kde/plasma/core/libcorebindingsplugin.so $TMPDIR
for filename in "$PWD/bin/libPlasma"*; do
	echo "Copying $filename to $TMPDIR"
    cp "$filename" "$TMPDIR"
done

if [ ! -d ${LIBDIR} ]; then
	LIBDIR="/usr/lib64/"
fi

if [ ! -f ${INSTALLDST} ]; then
	INSTALLDST="/usr/lib64/qt6/qml/org/kde/plasma/core/libcorebindingsplugin.so"
fi

cp "$TMPDIR/libcorebindingsplugin.so" $INSTALLDST

for filename in "$TMPDIR/libPlasma"*; do
	echo "Copying $filename to $LIBDIR"
	cp "$filename" "$LIBDIR"
done

echo "Done."

rm -r $TMPDIR

# cd $CUR/misc/uac-polkitagent
# sh install.sh --ninja
# sh add_rule.sh --ninja

cd $CUR

mkdir -p /usr/share/sounds
tar -xf $CUR/misc/sounds/sounds.tar.gz --directory /usr/share/sounds

mkdir -p /usr/share/icons
tar -xf "$CUR/misc/icons/Windows Vista Aero.tar.gz" --directory /usr/share/icons
tar -xf $CUR/misc/cursors/aero-drop.tar.gz --directory /usr/share/icons

mkdir -p /usr/share/mime/packages
for i in "$CUR/misc/mimetype/"*; do
    cp -r "$i" /usr/share/mime/packages
done

update-mime-database /usr/share/mime

for i in "./misc/branding/"*; do
    cp -r "$i" /etc/kdedefaults
done

kwriteconfig6 --file /etc/kcm-about-distrorc --group General --key LogoPath /etc/kdedefaults/kcminfo.png

git clone https://github.com/furkrn/PlymouthVista
cd PlymouthVista
chmod +x ./compile.sh
chmod +x ./install.sh
./compile.sh
./install.sh -o -s -q


# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File
systemctl enable podman.socket
