
INSTALL_LOCATION_VALUE=$(shell echo $(INSTALL_LOCATION))

fastuidraw-config: fastuidraw-config.in
	@echo Generating $@
	@cp $< $@
	@sed -i 's!@FASTUIDRAW_release_LIBS@!$(FASTUIDRAW_release_LIBS)!g' $@
	@sed -i 's!@FASTUIDRAW_GLES_release_LIBS@!$(FASTUIDRAW_GLES_release_LIBS)!g' $@
	@sed -i 's!@FASTUIDRAW_GL_release_LIBS@!$(FASTUIDRAW_GL_release_LIBS)!g' $@
	@sed -i 's!@FASTUIDRAW_debug_LIBS@!$(FASTUIDRAW_debug_LIBS)!g' $@
	@sed -i 's!@FASTUIDRAW_GLES_debug_LIBS@!$(FASTUIDRAW_GLES_debug_LIBS)!g' $@
	@sed -i 's!@FASTUIDRAW_GL_debug_LIBS@!$(FASTUIDRAW_GL_debug_LIBS)!g' $@
	@sed -i 's!@LIBRARY_release_CFLAGS@!$(LIBRARY_release_CFLAGS)!g' $@
	@sed -i 's!@LIBRARY_GLES_release_CFLAGS@!$(LIBRARY_GLES_release_CFLAGS)!g' $@
	@sed -i 's!@LIBRARY_GL_release_CFLAGS@!$(LIBRARY_GL_release_CFLAGS)!g' $@
	@sed -i 's!@LIBRARY_debug_CFLAGS@!$(LIBRARY_debug_CFLAGS)!g' $@
	@sed -i 's!@LIBRARY_GLES_debug_CFLAGS@!$(LIBRARY_GLES_debug_CFLAGS)!g' $@
	@sed -i 's!@LIBRARY_GL_debug_CFLAGS@!$(LIBRARY_GL_debug_CFLAGS)!g' $@
	@sed -i 's!@INSTALL_LOCATION@!$(INSTALL_LOCATION_VALUE)!g' $@
	@sed -i 's!@BUILD_GLES!$(BUILD_GLES)!g' $@
	@sed -i 's!@BUILD_GL!$(BUILD_GL)!g' $@
	@chmod a+x $@
# added to .PHONY to force regeneration so that if an environmental
# variable (BUILD_GL, BUILD_GLES, INSTALL_LOCATION) changes, we can
# guarantee that fastuidraw-config reflects it correctly.
.PHONY: fastuidraw-config
.SECONDARY: fastuidraw-config
CLEAN_FILES+=fastuidraw-config
INSTALL_EXES+=fastuidraw-config shell_scripts/fastuidraw-create-resource-cpp-file.sh
TARGETLIST+=fastuidraw-config

# $1: release or debug
# $2: GL or GLES
# $3: (0: skip build target 1: add build target)
define pkgconfrulesapi
$(eval ifeq ($(3),1)
fastuidraw$(2)-$(1).pc: fastuidraw-backend.pc.in fastuidraw-$(1).pc
	@echo Generating $$@
	@cp $$< $$@
	@sed -i 's!@TYPE@!$(1)!g' $$@
	@sed -i 's!@API@!$(2)!g' $$@
	@sed -i 's!@INSTALL_LOCATION@!$(INSTALL_LOCATION_VALUE)!g' $$@
	@sed -i 's!@LIBRARY_CFLAGS@!$$(LIBRARY_$(2)_COMMON_CFLAGS) $$(LIBRARY_GL_GLES_$(1)_CFLAGS)!g' $$@
	@sed -i 's!@LIBRARY_LIBS@!$$(LIBRARY_$(2)_LIBS)!g' $$@
.PHONY:fastuidraw$(2)-$(1).pc
.SECONDARY: fastuidraw$(2)-$(1).pc
pkg-config-files: fastuidraw$(2)-$(1).pc
INSTALL_PKG_FILES+=fastuidraw$(2)-$(1).pc
TARGETLIST+=fastuidraw$(2)-$(1).pc
endif
)
CLEAN_FILES+=fastuidraw$(2)-$(1).pc
endef

# $1: release or debug
define pkgconfrules
$(eval fastuidraw-$(1).pc: fastuidraw.pc.in
	@echo Generating $$@
	@cp $$< $$@
	@sed -i 's!@TYPE@!$(1)!g' $$@
	@sed -i 's!@INSTALL_LOCATION@!$(INSTALL_LOCATION_VALUE)!g' $$@
	@sed -i 's!@LIBRARY_CFLAGS@!$$(LIBRARY_$(1)_BASE_CFLAGS)!g' $$@
.PHONY:fastuidraw-$(1).pc
.SECONDARY: fastuidraw-$(1).pc
CLEAN_FILES+=fastuidraw-$(1).pc
INSTALL_PKG_FILES+=fastuidraw-$(1).pc
TARGETLIST+=fastuidraw-$(1).pc
$(call pkgconfrulesapi,$(1),GL,$(BUILD_GL))
$(call pkgconfrulesapi,$(1),GLES,$(BUILD_GLES)))
endef


$(call pkgconfrules,release)
$(call pkgconfrules,debug)
TARGETLIST+=pkg-config-files
.PHONY:pkg-config-files

install: $(INSTALL_LIBS) $(INSTALL_EXES) $(INSTALL_PKG_FILES)
	-install -d $(INSTALL_LOCATION_VALUE)/lib
	-install -d $(INSTALL_LOCATION_VALUE)/lib/pkgconfig
	-install -d $(INSTALL_LOCATION_VALUE)/bin
	-install -d $(INSTALL_LOCATION_VALUE)/include
	-install -t $(INSTALL_LOCATION_VALUE)/lib $(INSTALL_LIBS)
	-install -m 644 -t $(INSTALL_LOCATION_VALUE)/lib/pkgconfig $(INSTALL_PKG_FILES)
	-install -t $(INSTALL_LOCATION_VALUE)/bin $(INSTALL_EXES)
	-find inc/ -type d -printf '%P\n' | xargs -I '{}' install -d $(INSTALL_LOCATION_VALUE)/include/'{}'
	-find inc/ -type f -printf '%P\n' | xargs -I '{}' install -m 644 inc/'{}' $(INSTALL_LOCATION_VALUE)/include/'{}'
TARGETLIST+=install

install-docs: docs
	-install -d $(INSTALL_LOCATION_VALUE)/share/doc/fastuidraw/html/
	-install -t $(INSTALL_LOCATION_VALUE)/share/doc/fastuidraw TODO.txt README.md COPYING ISSUES.txt docs/*.txt
	-find docs/doxy/html -type d -printf '%P\n' | xargs -I '{}' install -d $(INSTALL_LOCATION_VALUE)/share/doc/fastuidraw/html/'{}'
	-find docs/doxy/html -type f -printf '%P\n' | xargs -I '{}' install -m 644 docs/doxy/html/'{}' $(INSTALL_LOCATION_VALUE)/share/doc/fastuidraw/html/'{}'
TARGETLIST+=install-docs

install-demos: $(DEMO_TARGETLIST)
	-install -d $(INSTALL_LOCATION_VALUE)/bin
	-install -t $(INSTALL_LOCATION_VALUE)/bin $(DEMO_TARGETLIST)
TARGETLIST+=install-demos

uninstall:
	-rm -rf $(INSTALL_LOCATION_VALUE)/include/fastuidraw
	-rm -f $(addprefix $(INSTALL_LOCATION_VALUE)/lib/,$(notdir $(INSTALL_LIBS)))
	-rm -f $(addprefix $(INSTALL_LOCATION_VALUE)/lib/pkgconfig/,$(notdir $(INSTALL_PKG_FILES)))
	-rm -f $(addprefix $(INSTALL_LOCATION_VALUE)/bin/,$(notdir $(INSTALL_EXES)))
TARGETLIST+=uninstall

uninstall-docs:
	-rm -r $(INSTALL_LOCATION_VALUE)/share/doc/fastuidraw
TARGETLIST+=uninstall-docs

uninstall-demos:
	-rm -f $(addprefix $(INSTALL_LOCATION_VALUE)/bin/,$(notdir $(DEMO_TARGETLIST)))
TARGETLIST+=uninstall-demos
