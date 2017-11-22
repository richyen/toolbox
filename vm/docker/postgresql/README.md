Bare PGDG PostgreSQL install on CentOS 6.6

Simply build a Dockerfile for a specific version of PostgreSQL from the PostgreSQL YUM repo with `build_dockerfile.sh 9.5`

If you like, you can ask the build script to actually build the image for you by adding a `do_build` at the end: `build_dockerfile.sh 9.5 do_build`
