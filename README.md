# Zotero: Better Bib(La)Tex

This extension aims to make Zotero effective for us LaTeX holdouts. It adds the following features:

## Duplicate keys; integration with [Zotero: Report Customizer](https://github.com/friflaj/zotero-report-customizer)

The plugin will generate bibtex comments to show whether a key conflicts and with which entry. This plugin now
integrates with [Zotero: Report Customizer](https://github.com/friflaj/zotero-report-customizer), to display the bibtex key plus
any conflicts between them in the zotero report.

## Set your own, fixed citation keys

You can fix the citation key for a reference by adding the text "bibtex: [your citekey]" (sans quotes) anywhere in the
"extra" field of the reference.

## Drag and drop/hotkey citations

You can drag and drop citations into your LaTeX editor, and it will add a proper \cite{citekey}. The actual command is
configurable by setting the config option in the BBT preferences (see below). Do not include the leading backslash. This
feature requires a one-time setup: go to zotero preferences, tab Export, under Default Output Format, select "Bib(La)TeX citations".

If you want even more convenience (and you're on Windows), install [AutoHotKey](http://www.autohotkey.com/), modify the [Zotero sample macro](https://raw.github.com/friflaj/zotero-better-bibtex/master/FastCite.ahk), and add it to your AutoHotKey.ahk. If you use this macro unmodified, when you select one or more entries in Zotero, it will copy them, bring TexMaker to the forground, and paste your citation at the cursor. Caution: this macro does *not* check that you are in Zotero when you activate it, nor that TexMaker is actually running.

## Recursive collection export

You can export collections including/excluding its child collections.

## JabRef groups import

During import, if JabRef explicit (not dynamic) groups are present, collections will be created to mirror these

## Configurable citekey generator

This plugin also implements a new citekey generator for those entries that don't have one set explicitly; the formatter follows the
[JabRef key formatting syntax](http://jabref.sourceforge.net/help/LabelPatterns.php).

## Date field exports

Export dates like 'forthcoming' as 'forthcoming' instead of empty.

## Pull export

You can fetch your library as part of your build, using curl (for example by using the included zoterobib.yaml arara
rule), or with a biblatex remote statement like \addbibresource[location=remote]{http://localhost:23119/better-bibtex/collection?/0/8CV58ZVD.biblatex}.
For Zotero standalone this is enabled by default; for Zotero embedded, you need to enable the embedded webserver from the BBT preferences screen (see below). You can then fetch your bibliography on the url
http://localhost:23119/better-bibtex/collection?\[collectionID].\[format], where collectionID is:
* the ID you get by right-clicking your collection and selecting "Show collection key"
* the path "/[library id]/full/path/to/collection" (the library id is the first number from the key you get in the option above; it's always '0' for your personal library)

The format is either 'bibtex' or 'biblatex', and determines the translator used for export.

Zotero needs to be running for this to work.

## Force citation key

You can force the citation key to whatever Better BibTex would have exported by selecting references, right-clicking, and selecting "Generate BibTex key".

# Things to watch out for

## Duplicate keys

In case you have ambiguous keys (both resolve to Smith2013 for example), drag and drop won't yield the same keys
as export (which does disambiguate them). You will have to either:
* Set an explicit cite key for at least one of them, or
* Configure your generator to generate non-ambigous keys (see below)

The plugin will generate bibtex comments to show whether a key conflicts and with which entry

## Configuration

The Better BibTex configuration pane can be found under the regular Zotero preferences pane, tab 'Better Bib(La)Tex'.

# Installation (one-time)

After installation, the plugin will auto-update to newer releases. Install by downloading the [latest
version](https://raw.github.com/friflaj/zotero-better-bibtex/master/zotero-better-bibtex-0.1.28.xpi) (**0.1.28**, released
on 2014-02-17 11:55). If you are not prompted with a Firefox installation dialog then double-click the downloaded xpi; Firefox ought to start and present you with the installation dialog.

For standalone Zotero, do the following:

1. In the main menu go to Tools > Add-ons
2. Select 'Extensions'
3. Click on the gear in the top-right corner and choose 'Install Add-on From File...'
4. Choose .xpi that you’ve just downloaded, click 'Install'
5. Restart Zotero

# Support - read carefully

My time is extremely limited for a number of very great reasons (you shall have to trust me on this). Because of this, I cannot accept bug reports
or support requests on anything but the latest version, currently at **0.1.28**. If you submit an issue report,
please include the version that you are on. By the time I get to your issue, the latest version might have bumped up already, and you
will have to upgrade (you might have auto-upgraded already however) and re-verify that your issue still exists. Apologies for the inconvenience, but such
are the breaks.

## Known issues

If you see a duplicate translator for Better BibLaTeX, go to "preferences/advanced/files", reset translators and
restart.

# Plans

* add "citekey" columns to reference list view
* Submission to Mozilla Extension registry
* JabRef groups export

# Notes

BibLaTeX features from https://github.com/andersjohansson/zotero-biblatex-translator
