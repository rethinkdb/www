Assets in this directory will be merged with assets from an external git repo
(e.g. the documentation repo).

For example, the `/_jekyll/_includes` directory is merged with
`/docs/_jekyll/_includes`, and the result is copied to `/_includes`. That
folder (`_includes`) is generated during the Jekyll build process, and removed
during cleanup.
