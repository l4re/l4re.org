# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

import os

project = 'L4Re Operating System Framework'
copyright = 'L4Re project members and individual contributors'
author = 'L4Re project members and individual contributors'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    'myst_parser',
    'sphinxcontrib.doxylink',
    'sphinx.ext.intersphinx',
    'sphinxcontrib.plantuml',
    'sphinx.ext.todo',
    'sphinx_togglebutton',
    'sphinx_inline_tabs',
    'sphinx_copybutton',
]

templates_path = ['../_templates']
exclude_patterns = ['venv', '_build', 'Thumbs.db', '.DS_Store', 'README.md']

highlight_language = "none"

todo_include_todos = False

# -- Intersphinx links -------------------------------------------------------

intersphinx_mapping = {
    'bob' : ('https://bob-build-tool.readthedocs.io/en/latest/', None),
}

# -- Doxygen links -----------------------------------------------------------
doxylink = {
    'l4re': (os.getenv("PATH_L4RE_TAG_FILE") or "", 'https://l4re.org/doc/'),
}

# -- Link checking -----------------------------------------------------------

# These hosts reject linkcheck's requests with 403 but obviously work
linkcheck_ignore = [
    r'https://developer\.arm\.com/',
    r'https://doi\.org/',
    r'http://doi\.acm\.org/',
]


# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'sphinx_book_theme'
html_static_path = ['../_static']
html_last_updated_fmt = "%Y-%m-%d"
# todo: do not load all js  all the time
html_css_files = ["css/custom.css", "css/asciinema-player.css"]
html_logo = "https://l4re.org/gfx/L4Re_rgb_logo_quadratisch.png"

html_theme_options = {
    "repository_url": "https://github.com/l4re/l4re.org",
    "use_source_button": True,
    "path_to_docs": "src",
    "use_edit_page_button": True,
    "use_issues_button": True,
    # Drop the author item: it repeats the copyright holder.
    "footer_content_items": ["copyright", "last-updated", "extra-footer"],
    "extra_footer": '<p>This page is licensed under '
                    '<a href="https://creativecommons.org/licenses/by-sa/4.0/">'
                    'CC-BY-SA 4.0</a>.</p>',
}
