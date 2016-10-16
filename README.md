# discourse-citestore
A plugin for Discourse that enables storing citations and quoting them with shorthand.

**The plugin is not yet ready, nor usable.**

# Purpose
This plugin will allow you to add citation data into database and enable 
full-text quotations with a shorthand. For example, `[us-constitution 
1]` should be replaced with the first paragraph of the Constitution, 
etc. Usable with legal sources, religious texts, technical definitions 
that are frequently cited in discussions.

# Basic features
 - [x] Basic functionality for adding and retrieving data from storage
 - [x] Advanced functionality for adding and retrieving data from storage (routes)
 - [ ] Replace shorthands
 - [ ] Enable Admin GUI for adding data into storage

# Terminology
 - shorthand: the entire code for a citation, e.g. `[us-constitution 1]`
 - handle: the name of the storage, e.g. `us-constitution`
 - locus: the place within the storage, e.g. `1`
 - storage: the PluginStore storage for (a) all handles or (b) a specific store (consisting of all loci for one handle)

# Collaborators

jsilvanus

# License

MIT
