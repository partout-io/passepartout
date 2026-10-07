<!-- dartvel:begin architecture -->
# Modules

A module is a full Dartvel application boundary declared under `dartvel.module` or `dartvel.modules` in `pubspec.yaml`. A parent reaches it through `DV.Modules.<id>` and its typed routes through `DV.Modules.<id>Routes`. Module code never hard-codes its mount point.
<!-- dartvel:end architecture -->
