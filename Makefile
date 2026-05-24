# Minimal makefile for Sphinx documentation
#

# You can set these variables from the command line, and also
# from the environment for the first two.
SPHINXOPTS    ?=
SPHINXBUILD   ?= sphinx-build
SOURCEDIR     = source
BUILDDIR      = build
PROJ	      = complit
PROJDIR       = $(shell pwd)
REMOTE        = $(shell git remote get-url origin)

# Put it first so that "make" without argument is like "make help".
help:
	@$(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

.PHONY: help Makefile

# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option.  $(O) is meant as a shortcut for $(SPHINXOPTS).
%: Makefile
	@$(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

pages: html
	cd build/html && tar zcf /tmp/$(PROJ)-html.tar.gz . 
	cd /tmp && git clone --branch gh-pages --single-branch $(PROJDIR) $(PROJ)_build
	cd /tmp/$(PROJ)_build \
		&& git remote set-url origin $(REMOTE) && git pull \
		&& touch .nojekyll && git add .nojekyll \
		&& tar zxf /tmp/$(PROJ)-html.tar.gz \
		&& git add . \
		&& git commit -m "Updated gh-pages" \
		&& git push
	rm -rf /tmp/$(PROJ)_build
	rm /tmp/$(PROJ)-html.tar.gz

