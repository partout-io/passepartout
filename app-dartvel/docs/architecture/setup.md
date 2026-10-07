<!-- dartvel:begin architecture -->
# Setup

Local development needs no database server: SQLite is the default locally. `dartvel dev` and `dartvel build` run generation themselves, so `dartvel routes` is rarely run by hand. Do not add `build_runner` or `build.yaml` for Dartvel; there is one generator and it is the CLI.
<!-- dartvel:end architecture -->
