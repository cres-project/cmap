all: index.html.ja index.html.en

index.html.ja: vizcmap.cgi vizcmap.rhtml.ja
	./vizcmap.cgi 0 lang=ja | tail -n +3 > index.html.ja

index.html.en: vizcmap.cgi vizcmap.rhtml.en
	./vizcmap.cgi 0 lang=en | tail -n +3 > index.html.en
