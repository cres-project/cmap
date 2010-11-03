## This Makefile.mozextention is for the test extension 
PROJECT=qth_toolbar

package:: make_structure make_xpi

make_structure: clean
	-mkdir $(PROJECT)
	tar cf - --exclude=.svn chrome/ chrome.manifest install.rdf components/ defaults/ | ( cd $(PROJECT) && tar xvf - )

make_xpi:
	cd $(PROJECT)/chrome && \
	zip -r $(PROJECT).jar content skin && \
	cd .. && \
	zip -r ../$(PROJECT).xpi chrome.manifest install.rdf components defaults chrome/$(PROJECT).jar && cd ..

clean:
	-rm -rf $(PROJECT)
