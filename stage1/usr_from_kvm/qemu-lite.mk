$(call setup-stamp-file,QEMU_LITE_STAMP)
QEMU_LITE_TMPDIR := $(UFK_TMPDIR)/qemu-lite
QEMU_LITE_SRCDIR := $(QEMU_LITE_TMPDIR)/src
QEMU_LITE_BINARY := $(QEMU_LITE_SRCDIR)/x86_64-softmmu/qemu-system-x86_64
QEMU_LITE_BIOS_BINARIES := bios-256k.bin \
    kvmvapic.bin \
    linuxboot.bin \
    vgabios-stdvga.bin \
    efi-virtio.rom

QEMU_LITE_CONFIGURATION_OPTS := --disable-bluez --disable-brlapi \
    --disable-bzip2 --disable-curl --disable-curses --disable-debug-tcg \
    --disable-fdt --disable-glusterfs --disable-gtk --disable-libiscsi \
    --disable-libnfs --disable-libssh2 --disable-libusb --disable-linux-aio \
    --disable-lzo --disable-opengl --disable-qom-cast-debug --disable-rbd \
    --disable-rdma --disable-sdl --disable-seccomp --disable-slirp --disable-snappy \
    --disable-spice --disable-strip --disable-tcg-interpreter --disable-tcmalloc \
    --disable-tools --disable-tpm --disable-usb-redir --disable-uuid --disable-vnc \
    --disable-vnc-jpeg --disable-vnc-png --disable-vnc-sasl --disable-vte \
    --disable-xen --enable-attr --enable-cap-ng --enable-kvm --enable-virtfs \
    --target-list=x86_64-softmmu
QEMU_LITE_ACI_BINARY := $(HV_ACIROOTFSDIR)/qemu-lite

QEMU_LITE_GIT := https://github.com/01org/qemu-lite.git
QEMU_LITE_GIT_COMMIT := qemu-lite-v1

$(call setup-stamp-file,QEMU_LITE_BUILD_STAMP,/build)
$(call setup-stamp-file,QEMU_LITE_BIOS_BUILD_STAMP,/bios_build)
$(call setup-stamp-file,QEMU_LITE_CONF_STAMP,/conf)
$(call setup-stamp-file,QEMU_LITE_CLONE_STAMP,/clone)
$(call setup-stamp-file,QEMU_LITE_DIR_CLEAN_STAMP,/dir-clean)
$(call setup-filelist-file,QEMU_LITE_DIR_FILELIST,/dir)
$(call setup-clean-file,QEMU_LITE_CLEANMK,/src)

S1_RF_SECONDARY_STAMPS += $(QEMU_LITE_STAMP)
S1_RF_INSTALL_FILES += $(QEMU_LITE_BINARY):$(QEMU_LITE_ACI_BINARY):-
INSTALL_DIRS += \
    $(QEMU_LITE_SRCDIR) :- \
    $(QEMU_LITE_TMPDIR) :-

# Bios files needs to be removed (source will be removed by QEMU_LITE_DIR_CLEAN_STAMP)
CLEAN_FILES += $(foreach bios,$(QEMU_LITE_BIOS_BINARIES),$(HV_ACIROOTFSDIR)/${bios})

$(call generate-stamp-rule,$(QEMU_LITE_STAMP),$(QEMU_LITE_CLONE_STAMP) $(QEMU_LITE_CONF_STAMP) $(QEMU_LITE_BUILD_STAMP) $(QEMU_LITE_ACI_BINARY) $(QEMU_LITE_BIOS_BUILD_STAMP) $(QEMU_LITE_DIR_CLEAN_STAMP),,)

$(QEMU_LITE_BINARY): $(QEMU_LITE_BUILD_STAMP)

$(call generate-stamp-rule,$(QEMU_LITE_BIOS_BUILD_STAMP),$(QEMU_LITE_CONF_STAMP) $(UFK_CBU_STAMP),, \
	for bios in $(QEMU_LITE_BIOS_BINARIES); do \
		$(call vb,vt,COPY BIOS,$$$${bios}) \
		cp $(QEMU_LITE_SRCDIR)/pc-bios/$$$${bios} $(HV_ACIROOTFSDIR)/$$$${bios} $(call vl2,>/dev/null); \
	done)

$(call generate-stamp-rule,$(QEMU_LITE_BUILD_STAMP),$(QEMU_LITE_CONF_STAMP),, \
    $(call vb,vt,BUILD EXT,qemu-lite) \
	$$(MAKE) $(call vl2,--silent) -C "$(QEMU_LITE_SRCDIR)" $(call vl2,>/dev/null))

$(call generate-stamp-rule,$(QEMU_LITE_CONF_STAMP),$(QEMU_LITE_CLONE_STAMP),, \
	$(call vb,vt,CONFIG EXT,qemu-lite) \
	cd $(QEMU_LITE_SRCDIR); ./configure $(QEMU_LITE_CONFIGURATION_OPTS) $(call vl2,>/dev/null))

# Generate filelist of qemu-lite directory (this is both srcdir and
# builddir). Can happen after build finished.
$(QEMU_LITE_DIR_FILELIST): $(QEMU_LITE_BUILD_STAMP)
$(call generate-deep-filelist,$(QEMU_LITE_DIR_FILELIST),$(QEMU_LITE_SRCDIR))

# Generate clean.mk cleaning qemu-lite directory
$(call generate-clean-mk,$(QEMU_LITE_DIR_CLEAN_STAMP),$(QEMU_LITE_CLEANMK),$(QEMU_LITE_DIR_FILELIST),$(QEMU_LITE_SRCDIR))

GCL_REPOSITORY := $(QEMU_LITE_GIT)
GCL_DIRECTORY := $(QEMU_LITE_SRCDIR)
GCL_COMMITTISH := $(QEMU_LITE_GIT_COMMIT)
GCL_EXPECTED_FILE := Makefile
GCL_TARGET := $(QEMU_LITE_CLONE_STAMP)
GCL_DO_CHECK :=

include makelib/git.mk

$(call undefine-namespaces,QEMU_LITE)
