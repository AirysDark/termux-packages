#!/usr/bin/env bash
# Termux build script for lvm2
TERMUX_PKG_NAME="lvm2"
TERMUX_PKG_HOMEPAGE="https://sourceware.org/lvm2/"
TERMUX_PKG_DESCRIPTION="LVM2 command line utilities and libraries"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="2.03.14"
TERMUX_PKG_SRCURL="https://sourceware.org/pub/lvm2/releases/LVM2.2.03.38.tgz"
TERMUX_PKG_SHA256=""
TERMUX_PKG_DEPENDS=""
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="--prefix=$TERMUX_PREFIX"

# Apply patches before build
termux_step_pre_configure() {
    echo "Applying patches for ${TERMUX_PKG_NAME}..."
    patch -p1 < "$TERMUX_PKG_BUILDER_DIR/fix-stack.patch"
}

termux_step_post_make_install() {
    echo "Installing ${TERMUX_PKG_NAME} binaries, man pages, and docs..."

    # Binaries
    mkdir -p "$TERMUX_PREFIX/bin"
    install -Dm755 lvm lvmdiskscan lvmetad lvmlockd vgchange vgcreate vgdisplay vgextend vgexport vgimport vgimportclone vgmerge vgremove vgreduce vgrename vgscan vgsplit lvchange lvconvert lvcreate lvdisplay lvextend lvmerge lvremove lvreduce lvrename lvresize lvscan "$TERMUX_PREFIX/bin/"

    # Man pages
    mkdir -p "$TERMUX_PREFIX/share/man/man1"
    install -Dm644 doc/*.1 "$TERMUX_PREFIX/share/man/man1/"

    # Documentation
    mkdir -p "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}"
    cp -r README* NEWS* doc/* "$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/"

    echo "Installation complete for ${TERMUX_PKG_NAME}"
}

# Include libdevmapper subpackage
termux_step_create_subpackages() {
    # libdevmapper from subpackage
    cat <<-EOF > libdevmapper.subpackage.sh
    #!/usr/bin/env bash
    TERMUX_PKG_NAME="libdevmapper"
    TERMUX_PKG_DESCRIPTION="Device Mapper library"
    TERMUX_PKG_DEPENDS=""
    TERMUX_PKG_INCLUDE=\$TERMUX_PREFIX/lib/libdevmapper*
    EOF
}