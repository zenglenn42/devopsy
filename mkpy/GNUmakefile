#============================================================================
#
# Build python from source in a robust way.
# 
# Derivative work of open source project while at Zenoss.
# Copyright (C) Zenoss, Inc. 2013, all rights reserved.
#
#============================================================================
.DEFAULT_GOAL := help # all|build|clean|distclean|devinstall|install|help

#---------------------------------------------------------------------------#
# The following targets are supported:
#
#    make <target>, where target is one of the following:
#
#    build,   clean
#    install, uninstall
#    help,    settings
#
# However, if you want to make python available to subsequent parts of a
# larger build, use the export target:
#
#    export         # Build python into a sandbox-relative
#                   # area visible by other python-hungry components that
#                   # need either python or related headers and libs.
#---------------------------------------------------------------------------#

#============================================================================
# Build component configuration.
#============================================================================
COMPONENT = python

# Fetch required python version from common.mk.  Use this token
# to specify which Python-x.y.z.tgz source archive to download.
#
# e.g., 2.7.16
#
python_version = $(strip $(REQD_PYTHON_MIN_VER))

# The starting point for building python from source is acquiring the
# source *.tgz archive off the net.  Specify some url's that host the source 
# archive.  
#
upstream_src_url = http://www.python.org/ftp/python/$(python_version)

# Specify if libpython is statically or dynamically linked against
# source-built python.
SHARED_LIBPYTHON = yes

# Decide if the LD_LIBRARY_PATH environment variable will influence
# the shared library loader at runtime when our dynamically linked python
# interpreter is invoked and the loader is resolving the path to libpythonX.Y.so.
ignore_LD_LIBRARY_PATH = yes

#============================================================================
# Hide common build macros, idioms, and default rules in a separate file.
#============================================================================

#---------------------------------------------------------------------------#
# Pull in common.mk
#---------------------------------------------------------------------------#
# Locate and include common build idioms tucked away in 'common.mk'
# This holds convenience macros and default target implementations.
#
# Generate a list of directories starting here and going up the tree where we
# should look for an instance of common.mk to include.
#
#     ./common.mk ../common.mk ../../common.mk ../../../common.mk
#---------------------------------------------------------------------------#
NEAREST_COMMON_MK := $(word 1,$(wildcard ./common.mk $(shell for slash in $$(echo $(abspath .) | sed -e "s|.*\(/obj/\)\(.*\)|\1\2|g" -e "s|.*\(/src/\)\(.*\)|\1\2|g" | sed -e "s|[^/]||g" -e "s|/|/ |g"); do string=$${string}../;echo $${string}common.mk; done | xargs echo)))

ifeq "$(NEAREST_COMMON_MK)" ""
    $(warning "Missing common.mk")
    $(warning "Unable to find our file of build idioms in the current or parent directories.")
    $(error   "A fully populated src tree usually resolves that.")
else
    include $(NEAREST_COMMON_MK)
endif

#----------------------------------------------------------------------------
# Verify we're using version of gnumake that supports .ONESHELL since that
# simplifies multi-line rules.
# https://lists.gnu.org/archive/html/info-gnu/2010-07/msg00023.html
#----------------------------------------------------------------------------
REQD_MAKE_MIN_VER = 3.82
REQD_MAKE_BRAND   = GNU
CHECK_MAKE_VERSION_BRAND += make:$(REQD_MAKE_MIN_VER):$(REQD_MAKE_BRAND)

CHECKED_MAKE_VERSION_BRAND = .checked_make_version_brand
$(CHECKED_MAKE_VERSION_BRAND):
	@for tool_version_brand in $(CHECK_TOOLS_VERSION_BRAND) ;\
	do \
		tool=`echo $${tool_version_brand} | cut -d":" -f1`;\
		case "$${tool}" in \
			"make") \
				dotted_min_desired_ver=`echo $${tool_version_brand} | cut -d":" -f2` ;\
				min_desired_ver=`echo $${dotted_min_desired_ver} |tr "." " "|$(AWK) '{printf("(%d*100)+(%d*10)+(%d)\n",$$1,$$2,$$3)}'|$(BC)` ;\
				dotted_actual_ver=`make -v 2>&1 | head -1 | $(AWK) '{print $$3}' | tr -d '"' | tr -d "'"` ;\
				actual_ver=`echo $${dotted_actual_ver} |tr "." " "|$(AWK) '{printf("(%d*100)+(%d*10)+(%d)\n",$$1,$$2,$$3)}'|$(BC)` ;\
				$(call echol,"chkver $${tool} >= $${dotted_min_desired_ver}","CHKVER $${tool}    >= $${dotted_min_desired_ver}") ;\
				if [ $${actual_ver} -lt $${min_desired_ver} ];then \
					$(call echol,"ERROR: make version is $${dotted_actual_ver}  Expecting version  >= $${dotted_min_desired_ver}") ;\
					$(call echol,"       Upgrade to avoid vexing 'unexpected end of file' errors.") ;\
					exit 1;\
				else \
					desired_brand=`echo $${tool_version_brand} | cut -d":" -f3` ;\
					actual_brand=`make -v 2>&1 | head -1 | awk '{print $$1}'` ;\
					if [ ! -z "$${desired_brand}" -a "$${actual_brand}" != "$${desired_brand}" ];then \
						$(call echol,"ERROR: make brand is $${actual_brand}.  Expecting $${desired_brand}.") ;\
						$(call echol,"ERROR: make brand is $${actual_brand}.  Expecting $${desired_brand}.") ;\
						exit 1;\
					fi ;\
				fi ;\
				;;\
			*) \
				$(call echol,"ERROR: You're asking me to check the version of a tool i don't know about: $${tool}") ;\
				$(call echol,"       Please update the $@ target portion of common.mk with the proper fu.") ;\
				exit 1;\
				;;\
		esac ;\
	done
	#$(call cmd,TOUCH,$@)

#---------------------------------------------------------------------------#
# Variables for this makefile
#---------------------------------------------------------------------------#
bldtop = build

# Specify the sandbox-relative place to install python/headers/libs for 
# subsequent use during the larger build.  Enables separation of build and
# install targets.
exportdir = $(bldtop)/export/$(python_pkg)

# Specify the directory where we download and build python from source.
externaldir = $(bldtop)/external

# Installing 'python' is relatively easy.  However uninstalling is another
# matter.  Beyond the built python interpreter itself, there are over 4000 files
# spread across 3 directories that embody the python footprint.  We get around
# some of the install and uninstall short-comings in the upstream python 
# build by creating a manifest of the installed files, links, and directories.
#
# Specify the directory where the python manifests reside.
manifesttop    = $(heredir)/manifests
manifestdir    = $(manifesttop)/$(python_pkg)
files_manifest = $(abspath $(manifestdir)/files.manifest)
links_manifest = $(abspath $(manifestdir)/links.manifest)
dirs_manifest  = $(abspath $(manifestdir)/dirs.manifest)

# e.g., Convert 2.7.16 into 2.7
python_version_maj_min := $(shell echo $(python_version) | cut -d. -f1-2)

# Since this usually involves pulling the *.tgz from
# an external network, provide a means for checking the integrity
# of the *.tgz before proceeding with the build.
check_md5 = yes

ifeq "$(check_md5)" "yes"
Python-2.7.16.tgz_md5  = f1a2ace631068444831d01485466ece0
#Python-x.y.z.tgz_md5 = https://www.python.org/downloads/release/x.y.z
endif

# Attributes associated with the python src tgz we're processing.
python                         = Python
python_pkg                     = $(python)-$(python_version)
python_pkg_tgz                 = $(python_pkg).tgz
$(python_pkg_tgz)_local_path   = ./$(python_pkg).tgz
$(python_pkg_tgz)_upstream_url = $(upstream_src_url)/$(python_pkg).tgz

# Convenience macros for key files we build or reference.
program           = python
built_python     := $(externaldir)/$(python_pkg)/$(program)
built_target     := $(built_python)
python_configure := $(externaldir)/$(python_pkg)/configure
python_makefile  := $(externaldir)/$(python_pkg)/Makefile

#---------------------------------------------------------------------------#
# Work-around a potential issue with hard-links failing in our vagrant dev 
# environment.  If hardlinks are not supported on the filesystem then you'll 
# get a failure in the upstream python build in this rule:
#
#    Python-x.y.z/Makefile
#    ---------------------
#    490 libpython$(VERSION).so: $(LIBRARY_OBJS)
#              ..
# >> 493       $(LN) -f $(INSTSONAME) $@; \
#---------------------------------------------------------------------------#
LN           = ln -s

#---------------------------------------------------------------------------#
# Configure-time options common to statically and dynamically linked python.
#
# Specifying:
#
# 1. system pkg-config 
# 2. version of ln that works when hardlinks don't (e.g., some vagrant dev VMs).
# 3. install prefix (e.g., /opt/devopsy)
# 4. place where python modules live (e.g., /opt/devopsy/lib/{pythonX.Y}
#---------------------------------------------------------------------------#
common_opts := PKG_CONFIG=$(which PKG_CONFIG) LN="$(LN)" --prefix=$(prefix) --libdir=$(prefix)/lib

#---------------------------------------------------------------------------#
# Make devopsy package more relocatable by removing hardcoded shared-library
# search path dependency upon /opt/devopsy/lib.
#
# At runtime, have the dynamic loader search for libpython*.so relative to
# where python is installed (e.g., up one directory and down into ./lib).
# via link-time $ORIGIN/../lib idiom:
#
#    bin/python
#    lib/libpython*.so
#
# See: http://man7.org/linux/man-pages/man8/ld.so.8.html  (search on ORIGIN).
#
# NB: Jump through some hoops so LDFLAGS ends up as:
#
#         LDFLAGS = .. -Wl,-rpath,\$$ORIGIN/../lib
#
#     since python's configure script needs that apparently:
#     See: http://bugs.python.org/issue5201
#
# This is a departure from the idiom:
#
#         LDFLAGS = '-Wl,-R$$(prefix)/lib'
#
# which essentially hardcodes the location of libpython to /opt/devopsy/lib.
#---------------------------------------------------------------------------#
ORIGIN = '\$$$$ORIGIN'
LIBPYTHON_RPATH = '$(ORIGIN)/../lib'
ifeq "$(ignore_LD_LIBRARY_PATH)" "yes"
    # Ignore LD_LIBRARY_PATH when it comes to resolving the location of
    # libpython*.so at runtime.
    RPATH_OPT = -Wl,-rpath,$(LIBPYTHON_RPATH) -Wl,-z,origin
else
    # Allow LD_LIBRARY_PATH to influence the search path for shared libraries at
    # runtime.
    #
    # Adding --enable-new-dtags sets RPATH /and/ RUNPATH to the same value
    # within the ELF dynamic string table. The presence of RUNPATH causes RPATH 
    # to be ignored at runtime.  RUNPATH provides a mechanism for setting
    # default search directories that may be overridden by LD_LIBRARY_PATH
    # on the deployed system.
    #
    # See: http://blog.tremily.us/posts/rpath/
    RPATH_OPT = -Wl,-rpath,$(LIBPYTHON_RPATH),--enable-new-dtags -Wl,-z,origin
endif
# Squelch nuisance warnings in the upstream build that are not actionable to us.
#python_CFLAGS = -Wno-unused-but-set-variable -Wunknown-warning-option
python_LDFLAGS = $(RPATH_OPT)

ifeq "$(SHARED_LIBPYTHON)" "yes"
    $(python_pkg)_configure_opts = $(common_opts) --enable-shared
else
    $(python_pkg)_configure_opts = $(common_opts)
endif

#============================================================================
# Subset of standard build targets our makefiles should implement.  
#
# See: http://www.gnu.org/prep/standards/html_node/Standard-Targets.html#Standard-Targets
#============================================================================

#---------------------------------------------------------------------------#
# Build Targets
#---------------------------------------------------------------------------#
.PHONY: all build
all build: python

$(externaldir) $(manifestdir):
	$(call cmd,MKDIR,$@)

$(externaldir)/%.tgz : local_path   = $($(@F)_local_path)
$(externaldir)/%.tgz : upstream_url = $($(@F)_upstream_url)
.ONESHELL: $(externaldir)/%.tgz
$(externaldir)/%.tgz : | $(CHECKED_MAKE_VERSION_BRAND) $(externaldir)
	@if [ -f "$(local_path)" ];then
		$(call cmd_noat,CP,$(local_path),$@)
		rc=$$?
		if [ $${rc} -ne 0 ];then
			exit $${rc}
		fi
	else
		for src_tgz_url in $(upstream_url)
		do
			($(call cmd_noat,CURL,$@,$${src_tgz_url}))
			rc=$$?
			if [ $${rc} -eq 0 ];then
				break
			fi
		done
	fi
	if [ ! -f "$@" ];then
		echo "Unable to stage $@"
		exit 1
	fi

#---------------------------------------------------------------------------#
# In several cases below, we use the .SECONDARY target to prevent associated 
# dependencies from being automatically removed by make.  This happens when
# a sub-rule fires during the course of a dependency chain-of-events to build
# some high-level target.  Preserving secondary targets minimizes unnecessary
# rebuild activity.
#---------------------------------------------------------------------------#

ifeq "$(check_md5)" "yes"
#---------------------------------------------------------------------------#
# NB: Specify python.tgz as secondary so it doesn't get auto-deleted by the 
#     md5chk rule.  It's handy to have pristine source *.tgz hanging around 
#     and the download step can be relatively expensive.
#---------------------------------------------------------------------------#
.SECONDARY: $(externaldir)/$(python_pkg_tgz)
%.tgz.md5chk: expected_md5 = $($(patsubst %.tgz.md5chk,%.tgz,$(@F))_md5)
%.tgz.md5chk: srctgz = $(patsubst %.tgz.md5chk,%.tgz,$@)
%.tgz.md5chk: %.tgz
	@if [ -z "$(expected_md5)" ];then
		echo "Expected md5 sum for $(srctgz) is unknown."
		echo "Please make this known to the makefile if you want md5 sum checking."
		exit 1
	fi
ifeq "$(MD5SUM)" "md5"
	actual_md5=$$($(MD5SUM) $(srctgz) | awk '{print $$4}')
else
	actual_md5=$$($(MD5SUM) $(srctgz) | awk '{print $$1}')
endif
	valid_md5_list="$(expected_md5) end_of_list"
	for valid_md5 in $${valid_md5_list}
	do
		case $${valid_md5} in
			"end_of_list")
				echo "md5 check failed for $@"
				exit 1
				;;
			[0-9,a-f,A-F]*)
				if [ "$${actual_md5}" = "$${valid_md5}" ];then
					echo $${actual_md5} > $@
					break
				fi
				;;
			*)
				echo "unexpected md5 string: $${valid_md5}"
				;;
		esac
	done
endif

%.tgz.unpacked : srctgz = $(patsubst %.tgz.unpacked,%.tgz,$@)
ifeq "$(check_md5)" "yes"
.SECONDARY: $(externaldir)/$(python_pkg_tgz).md5chk
%.tgz.unpacked : %.tgz.md5chk
else
%.tgz.unpacked : %.tgz
endif
	$(call cmd,UNTGZ,$(srctgz),$(@D))
	$(call cmd,TOUCH,$@)

#---------------------------------------------------------------------------#
# Be careful to specify order-only dependency between configure script
# and the *.unpacked sentinel file otherwise we'll get nuisance untar's of
# the python tgz even when the archived is alread unpacked.
#
# Why?  File modification times internal to the package are generally very old
# relative to our sentinel file that indicates the archive has been unpacked.
# It's likely the *.unpacked file will have a more recent modtime than
# the aged configure script within the python source archive that "depends"
# upon being unpacked from the archive for it's existence.
#---------------------------------------------------------------------------#
.ONESHELL: $(python_configure)
.SECONDARY: $(externaldir)/$(python_pkg).tgz.unpacked
$(python_configure): | $(externaldir)/$(python_pkg).tgz.unpacked
	@if [ ! -f "$(@)" ];then
		echo Recreate ./configure by unpacking tgz again.
		if [ -f "$(externaldir)/$(python_pkg).tgz.unpacked" ]; then
			$(call cmd_noat,RM,$(externaldir)/$(python_pkg).tgz.unpacked)
		fi
		if ! $(call cmd_noat,BUILD,$@,.,$(externaldir)/$(python_pkg).tgz.unpacked,) ;then
			exit 1
		fi
	fi

# Preserve configure-created, upstream Makefile during build process 
# so it is available later for use in install targets.
.SECONDARY: $(externaldir)/$(python_pkg)/Makefile
%/Makefile : configure_opts = $($(notdir $(@D))_configure_opts)
%/Makefile : %/configure
	@cd $(@D) ;\
	$(call cmd_noat,CFGBLD,$(@D),$(configure_opts))

# Re-enable this once I have a configure front-end for this build.
# The following fu doesn't play so well on macOS where I'm dev'ing.
# It's more linux-friendly.
#
#ifdef SHARED_LIBPYTHON
#	@cd $(@D) ;\
#	export LDFLAGS='$(python_LDFLAGS)' ;\
#	export CFLAGS='$(python_CFLAGS)'   ;\
#	$(call cmd_noat,CFGBLD,$(@D),$(configure_opts))
#else
#	@cd $(@D) ;\
#	export CFLAGS='$(python_CFLAGS)' ;\
#	$(call cmd_noat,CFGBLD,$(@D),$(configure_opts))
#endif


# Force a reconfigure of the python source, by triggering
# the rule that causes python's Makefile to be created.
.PHONY: configure
.ONESHELL: configure
configure: 
	@if [ -f "$(python_makefile)" ];then
		$(call cmd_noat,RM,$(python_makefile))
	fi
	if ! $(call cmd_noat,BUILD,$@,.,$(python_makfile),) ;then
		exit 1
	fi

.PHONY: python
python: $(built_python)

$(built_python): | $(CHECKED_ENV)


# Build python from source.  
# (Makefile must already be configured into existence.)
%/$(python_pkg)/python: %/$(python_pkg)/Makefile
	$(call cmd,BUILD,$@,$(<D),all,)


# Create the install directory.  If the DESTDIR variable
# is null, you may need rootly powers.
#
# e.g., $(DESTDIR)/opt/devopsy
#
$(_DESTDIR)$(prefix):
	@($(call cmd_noat,MKDIR,$@)) ;\
	rc=$$? ;\
	if [ $${rc} -ne 0 ] ; then \
		echo $(LINE) ;\
		echo "Maybe you intended 'sudo make install' or 'make installhere' instead?" ;\
		echo ;\
		exit $${rc} ;\
	else \
		$(call cmd_noat,CHOWN,,$(INST_OWNER),$(INST_GROUP),$@) ;\
		rc=$$? ;\
		if [ $${rc} -ne 0 ] ; then \
			exit $${rc} ;\
		fi ;\
	fi

#---------------------------------------------------------------------------#
# Install the complete python package under $(DESTDIR)$(prefix).
#
# e.g., $(DESTDIR)/opt/devopsy/{bin,lib,include}
#
# $(prefix) is set to a default value in common.mk.
#
# $(DESTDIR) is a shell variable, often null, but may be used for staged
# installs to a temporary location.  It's generally used during packaging
# builds but also leveraged in our sandbox-relative install targets 
# (e.g., export, installhere).
#
# Use the upstream's altinstall target for most of this, but
# overcome some weakness there with our manifests to
# ensure all files, links, and directories have desired ownership.
# Otherwise altinstall it will leave a subset of files and links 
# owned by root.
#
# NB: Some files in the python package have embedded spaces.  Manipulate the
#     internal field separator (IFS) during file reads to get the full
#     filename.
#---------------------------------------------------------------------------#
.PHONY: install
install: uppercase_target = $(shell echo $@ | tr '[:lower:]' '[:upper:]')
install: $(files_manifest) $(links_manifest) $(dirs_manifest)
install: | $(_DESTDIR)$(prefix)
	@if [ ! -f "$(built_python)" ]; then \
                echo "Unable to install $(program).  Missing $(built_python)." ;\
                echo $(LINE) ;\
                echo "Run 'make build' first" ;\
                echo ;\
                exit 1 ;\
        fi
	@if ($(call cmd_noat,MAKE_ALTINST,$(uppercase_target),$(dir $(built_python)),altinstall,DESTDIR=$(_DESTDIR) INSTALL="$(INSTALL) -c -o $(INST_OWNER) -g $(INST_GROUP)",$(_DESTDIR)$(bindir)/$(program))) ;then \
		cd $(_DESTDIR)$(bindir)
		if [ -f python$(python_version_maj_min) ] ;then \
			if [ ! -L python ]; then \
				if ! ($(call cmd_noat,SYMLINK,python$(python_version_maj_min),python)) ; then \
					echo "Unable to create python symlink." ;\
					exit 1 ;\                                       
				fi ;\
			fi ;\
		else \
			echo "Missing $(_DESTDIR)$(bindir)/python$(python_version_maj_min)" ;\
			echo "Unable to create python symlink." ;\
			exit 1 ;\
		fi ;\
		saveIFS=$(IFS) ;\
		IFS=$(echo -en "\n\b") ;\
		while read installedFile ;\
		do \
			_installedFile=$(_DESTDIR)$${installedFile} ;\
			if [ -f "$${_installedFile}" -o -L "$${_installedFile}" ];then \
				if ! ($(call cmd_noat,CHOWN,,$(INST_OWNER),$(INST_GROUP),$${_installedFile})) ;then \
					IFS=$${saveIFS} ;\
					exit 1 ;\
				fi ;\
			fi ;\
		done < $(files_manifest) ;\
		while read installedLink ;\
		do \
			_installedLink=$(_DESTDIR)$${installedLink} ;\
			if [ -L "$${_installedLink}" ];then \
				if ! ($(call cmd_noat,CHOWN_LINK,$(INST_OWNER),$(INST_GROUP),$${_installedLink})) ;then \
					IFS=$${saveIFS} ;\
					exit 1 ;\
				fi ;\
			fi ;\
		done < $(links_manifest) ;\
		while read installedDir ;\
		do \
			_installedDir=$(_DESTDIR)$${installedDir} ;\
			if [ -d "$${_installedDir}" ];then \
				if ! ($(call cmd_noat,CHOWN,,$(INST_OWNER),$(INST_GROUP),$${_installedDir})) ;then \
					IFS=$${saveIFS} ;\
					exit 1 ;\
				fi ;\
			fi ;\
		done < $(dirs_manifest) ;\
		IFS=$${saveIFS} ;\
	else \
		echo "Error installing using python's makefile." ;\
		echo "Maybe you intended 'sudo make install' instead?" ;\
		exit 1 ;\
	fi

#---------------------------------------------------------------------------#
# Attempt a sandbox-relative install.  If that fails, then we should probably
# fix that before attempting a 'sudo make install' onto the system.
#
# This is also our mechanism for creating manifests prior to a system-level 
# install.  Manifests give us traceability of files associated with a 
# component and surgical uninstall ability.
#---------------------------------------------------------------------------#
.PHONY: installhere
installhere: uppercase_target = $(shell echo $@ | tr '[:lower:]' '[:upper:]')
installhere: 
	@if [ ! -f "$(built_python)" ]; then \
                echo "Unable to install $(program).  Missing $(built_python)." ;\
                echo $(LINE) ;\
                echo "Run 'make build' first" ;\
                echo ;\
                exit 1 ;\
        fi
	@if ($(call cmd_noat,MAKE_ALTINST,$(uppercase_target),$(dir $(built_python)),altinstall,DESTDIR=$(abspath $(_DESTDIR)) INSTALL="$(INSTALL) -c -o $(INST_OWNER) -g $(INST_GROUP)",$(_DESTDIR)$(bindir)/$(program))) ;then \
		cd $(abspath $(_DESTDIR)$(bindir)) ;\
		if [ -f python$(python_version_maj_min) ] ;then \
			if [ ! -L python ]; then \
				if ! ($(call cmd_noat,SYMLINK,python$(python_version_maj_min),python)) ; then \
					echo "Unable to create python symlink." ;\
					exit 1 ;\                                       
				fi ;\
			fi ;\
		else \
			echo "Missing $(_DESTDIR)$(bindir)/python$(python_version_maj_min)" ;\
			echo "Unable to create python symlink." ;\
			exit 1 ;\
		fi ;\
	else \
		echo "Error installing using python's makefile." ;\
		echo "Maybe you intended 'sudo make install' instead?" ;\
		exit 1 ;\
	fi
	$(call cmd,CHOWN,-R,$(INST_OWNER),$(INST_GROUP),$(abspath $(_DESTDIR)))

#---------------------------------------------------------------------------#
# Export the python interpreter, headers, and libs to an area under the 
# build tree where subsequent portions of the build can refer and use.  This 
# is key for separating our build and install targets at the product-level 
# source build.
#---------------------------------------------------------------------------#
exportto := $(exportdir)$(prefix)
.PHONY: export
export: $(exportto)

$(exportto): uppercase_target = $(shell echo $@ | tr '[:lower:]' '[:upper:]')
$(exportto): 
	@if [ ! -f "$(built_python)" ]; then \
                echo "Unable to export $(program).  Missing $(built_python)." ;\
                echo $(LINE) ;\
                echo "Run 'make build' first" ;\
                echo ;\
                exit 1 ;\
        fi
	@if ($(call cmd_noat,MAKE_ALTINST,$(uppercase_target),$(dir $(built_python)),altinstall,DESTDIR=$(abspath $(exportdir)),$(exportdir))) ;then \
		cd $(abspath $(exportdir)/$(bindir))
		if [ -f python$(python_version_maj_min) ] ;then \
			if [ ! -L python ]; then \
				if ! ($(call cmd_noat,SYMLINK,python$(python_version_maj_min),python)) ; then \
					echo "Unable to create python symlink." ;\
					exit 1 ;\                                       
				fi ;\
			fi ;\
		else \
			echo "Missing $(exportdir)/$(bindir)/python$(python_version_maj_min)" ;\
			echo "Unable to create python symlink." ;\
			exit 1 ;\
		fi ;\
	else \
		echo "Error installing $(program) under $@." ;\
		exit 1 ;\
	fi

#---------------------------------------------------------------------------#
# Target used to trigger an install of the python package to a 
# sandbox-relative location:
#
#    ./here/opt/devopsy/{bin,lib,include}
#
# before attempting a system level install:
#
#    /opt/devopsy/{bin,lib,include}
#---------------------------------------------------------------------------#
$(heredir)$(bindir)/python:
	@$(MAKE) --no-print-directory installhere

#---------------------------------------------------------------------------#
# Targets to create manifests of all the associated files, links, and 
# directories that make up the installed python footprint.  These are used 
# to audit comprises the installed package and to enable robust installs and 
# surgical uninstalls.
#
# Here we call into subshellcmd because the underlying manifest creation
# macros employ a subshell which is not tolerated well by the cmd macro.
# You'll get an error, otherwise, from echo because the subshell is not quoted.
#---------------------------------------------------------------------------#
%/files.manifest: $(heredir)$(bindir)/python | $(manifestdir)
	@($(call subshellcmd_noat,MK_F_MANIFEST,$(heredir),$(prefix),$@))

%/links.manifest: $(heredir)$(bindir)/python | $(manifestdir)
	@($(call subshellcmd_noat,MK_L_MANIFEST,$(heredir),$(prefix),$@))

%/dirs.manifest: $(heredir)$(bindir)/python | $(manifestdir)
	@($(call subshellcmd_noat,MK_D_MANIFEST,$(heredir),$(prefix),$(_DESTDIR)$(prefix),$@))
	$(call cmd,CHOWN,-R,$(INST_OWNER),$(INST_GROUP),$(manifestdir))

.PHONY: manifests
manifests: $(files_manifest) $(links_manifest) $(dirs_manifest)


#---------------------------------------------------------------------------#
# Manifest-based uninstall.
#---------------------------------------------------------------------------#
.ONESHELL: uninstall
.PHONY: uninstall
uninstall: 
	@if [ ! -d "$(_DESTDIR)$(prefix)" ];then
		echo
		echo "$(_DESTDIR)$(prefix) not found.  Nothing to uninstall."
		echo
	else
		if [ ! -w "$(_DESTDIR)$(prefix)" ];then
			echo not writable
			echo
			echo "Unable to remove files under $(_DESTDIR)$(prefix)"
			echo "Maybe you intended 'sudo make uninstall' instead?"
			echo
		else
			count=`ls -a1 $(_DESTDIR)$(prefix) 2>/dev/null | wc -l`
			if ((count<=2));then
				echo
				echo "Nothing to uninstall under $(_DESTDIR)$(prefix)"
				echo
				exit 0
			fi
			if [ ! -f "$(files_manifest)" -o ! -f "$(dirs_manifest)" ];then
				echo
				echo "Unable to uninstall without a manifest of installed files and directories."
				echo
				echo "Please run: 'make manifests uninstall'"
				echo
				exit 1
			else
				saveIFS=$(IFS)
				IFS=$(echo -en "\n\b")
				while read delFile
				do
					_delFile=$(_DESTDIR)$${delFile}
					if [ -f "$${_delFile}" -o -L "$${_delFile}" ];then
						$(call echol,"rm -f $${_delFile}","RM     $${_delFile}")
						rm -rf "$${_delFile}"
						rc=$$?
						if [ $${rc} -ne 0 ];then
							echo "Error removing $${_delFile}"
							echo "Giving up on $@."
							echo "Maybe you intended 'sudo make uninstall' instead?"
							IFS=$${saveIFS}
							exit $${rc} 
						fi
					fi
				done < $(files_manifest)
				while read delLink
				do
					_delLink=$(_DESTDIR)$${delLink}
					if [ -L "$${_delLink}" -o -f "$${_delLink}" ];then
						$(call echol,"rm -f $${_delLink}","RMLINK $${_delLink}")
						rm -rf "$${_delLink}"
						rc=$$?
						if [ $${rc} -ne 0 ];then
							echo "Error removing $${_delLink}"
							echo "Giving up on $@."
							echo "Maybe you intended 'sudo make uninstall' instead?"
							IFS=$${saveIFS}
							exit $${rc}
						fi
					fi
				done < $(links_manifest)
				if find $(_DESTDIR)$(prefix) -type f -o -type l 2>/dev/null 1>&2 ;then
					while read delDir
					do
						case $${delDir} in
							/|/usr|/opt|/etc|/var|/bin|/sbin|/lib|/home|/root|/sys|/dev|/boot)	
								:;;
							*)
								_delDir=$(_DESTDIR)$${delDir}
								if [ -d "$${_delDir}" ];then
									count=`ls -a1 $${_delDir} 2>/dev/null | wc -l`
									if ((count<=2));then

										$(call echol,"rm -rf $${_delDir}","RMDIR  $${_delDir}")
										rm -rf "$${_delDir}"
										rc=$$?
										if [ $${rc} -ne 0 ];then
											echo "Error removing $${_delDir}"
											echo "   rm -rf $${_delDir}"
											echo "Giving up on $@."
											echo "Maybe you intended 'sudo make uninstall' instead?"
											echo "Otherwise you will need to manually remove python from $(_DESTDIR)$(prefix)"
											IFS=$${saveIFS}
											exit 1 
										fi
									else
										$(call echol, "Sipping $${_delDir}.  Non-empty.","SKIP    $${_deldir}.  Non-empty.")
									fi
								fi
								;;
						esac
					done < $(dirs_manifest)
				fi
				IFS=$${saveIFS}
				if [ -d "$(heredir)" ];then
					if ! $(MAKE) --no-print-directory uninstallhere ;then
						exit 1
					fi
				fi
			fi
		fi
	fi

.PHONY: help
help: dflt_component_help

# Variables of interest that we dump out if you run 'make settings'
# This will give you an idea of how the build will behave as currently
# configured.
control_variables  = bldtop 
control_variables += CHECKED_ENV
control_variables += DESTDIR
control_variables += exportdir 
control_variables += exportto 
control_variables += INST_GROUP 
control_variables += INST_OWNER 
control_variables += NEAREST_COMMON_MK 
control_variables += python_pkg_tgz
control_variables += python_version 
control_variables += prefix 
control_variables += SHARED_LIBPYTHON 
control_variables += upstream_src_url 

.PHONY: settings
settings: 
	$(call show-vars,"Current makefile settings:",$(control_variables))

.PHONY: clean
clean:
	@if [ -d "$(bldtop)" ];then \
		if [ "$(abspath $(bldtop))" != "$(abspath $(srcdir))" ];then \
			($(call cmd_noat,RMDIR,$(bldtop))) ;\
			rc=$$? ;\
			if [ $${rc} -ne 0 ] ; then \
				echo $(LINE) ;\
				echo "Problem removing $(bldtop)." ;\
				echo ;\
				exit $${rc} ;\
			fi ;\
		else \
			$(call echol,"Error: Ignorning request to remove the build directory which is") ;\
			$(call echol,"       currently the same as your source directory.") ;\
			$(call echol,$(LINE)) ;\
			$(call echol,"       bldtop $(abspath $(bldtop))") ;\
			$(call echol,"       srcdir $(abspath $(srcdir))") ;\
		fi ;\
	fi

.PHONY: mrclean
mrclean distclean: installed_python = $(_DESTDIR)$(bindir)/$(program)
mrclean distclean: clean dflt_component_distclean
	@for delfile in $(_COMPONENT).log ;\
	do \
		if [ -f "$${delfile}" ];then \
			$(call cmd_noat,RM,$${delfile}) ;\
		fi ;\
	done

.PHONY: uninstallhere
uninstallhere:
	@if [ -d "$(heredir)" ];then \
		$(call cmd_noat,RMDIR,$(heredir)) ;\
	fi

CHECKED_SHLIB_DEPS = .checked_shlib_deps
$(CHECKED_SHLIB_DEPS):
	$(call subshellcmd_noat,LSSHLIBS,$(built_target),$@)

CHECKED_RPATHS = .checked_rpaths
$(CHECKED_RPATHS):
	$(call subshellcmd_noat,LSRPATHS,$(built_target),$@)

.phony: check
check: $(CHECKED_SHLIB_DEPS) $(CHECKED_RPATHS)
	@if [ ! -f "$(built_target)" ]; then \
		echo "Unable to check $(program).  Missing $(built_target)." ;\
		echo $(LINE) ;\
		echo "Run 'make build' first" ;\
		echo ;\
		exit 1 ;\
	fi
	@echo "Shared libraries needed by $(built_target) at runtime: " ;\
	echo $(LINE) ;\
	if [ -f "$(CHECKED_SHLIB_DEPS)" -a -s "$(CHECKED_SHLIB_DEPS)" ];then \
		$(CAT) $(CHECKED_SHLIB_DEPS) ;\
	else \
		echo "(none)";\
	fi
	@echo
	@echo "Embedded rpaths in $(built_target) which influence runtime shlib resolution: " ;\
	echo $(LINE) ;\
	if [ -f "$(CHECKED_RPATHS)" -a -s "$(CHECKED_RPATHS)" ];then \
		$(CAT) $(CHECKED_RPATHS) ;\
	else \
		echo "(none)";\
		echo ;\
		echo "[INFO]" ;\
		echo ;\
		echo "Since no rpath attributes were found, standard system lib paths and" ;\
		echo "LD_LIBRARY_PATH will be used at runtime by the loader to resolve any" ;\
		echo "shared libarary dependencies required by $(built_target)." ;\
	fi

#=============================================================================
# TODO:
#
# At configure time, search for the *.pc (pkg-config) files associated
# with these devel packages:
#
#       bzip2-devel    
#       openssl-devel 
#       ncurses-devel 
#       readline-devel 
#       tk-devel
#       sqlite-devel 
#       zlib-devel
#
# lest you get chatter at the end of the python build about inability to
# build various modules:
#
# Python build finished, but the necessary bits to build these modules were not found:
# _bsddb             _tkinter           bsddb185        
# bz2                dbm                dl              
# gdbm               imageop            sunaudiodev     
#
# See: http://toomuchdata.com/2012/06/25/how-to-install-python-2-7-3-on-centos-6-2/
#=============================================================================
