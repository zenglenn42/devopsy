# devopsy

![alt](cc_img/devops-willy-peter-schuab-cc-by-sa-4.0.png)
Graphic by W.P. Schuab

My cubby for devops stuff I craft that others may like too.

# [Contents](#contents)

- [getopt](#getopt)
- [mkpy](#mkpy)

-----

## [getopt](#contents)

Are you throwing together a bash script and would like some fu for parsing your command line arguments into variables?

Take a look at this [skeleton shell script](getopt/test_getopt.sh) which leverages ```getopt```, a shell builtin command for doing just that.

## [mkpy](#contents)

Sometimes in the devops world, you need some makefile fu.  

Here's a non-trivial example of how to use GNU make to perform a manifest-driven build of python from source.

It demonstrates:

* Use of target / dependencies to make your builds idempotent and efficient.
* Downloading the source bundle from an upstream website with optional md5 bundle check.
* Verbosity control (so build warnings & errors don't go unnoticed amidst the chatter).
* Component-based autologging of build output.
* Manifest-based installs for surgical uninstalls if your dev work flow requires that.
* Post-build checking of shared library dependencies and runtime search paths (i.e., rpath audit) so you understands the runtime behavior of your build targets for added insight and security.

<pre>
DevOpsy python makefile

Usage: 

       make             # for help verbiage
       make target
       make target V=1  # for verbose output

where target is one or more of the following:
-----------------------------------------------------------------------------
all			   configure		      python
build			   export		      settings
check			   help
checkenv		   manifests
-----------------------------------------------------------------------------
install			   uninstall
installhere		   uninstallhere
-----------------------------------------------------------------------------
clean			   distclean		      mrclean
-----------------------------------------------------------------------------
</pre>

TODO: This was most recently dev'd on macOS.  Linux should work too, but needs testing.
