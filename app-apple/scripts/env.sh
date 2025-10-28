#!/bin/bash
tmp_root=./tmp
xcconfig_path="Passepartout/Config.xcconfig"
platforms="iOS macOS tvOS"
devices="mac iphone ipad appletv"
certs_p12_path="/Volumes/Personale/Passepartout/certificates.p12"
certs_profiles_root=~/Library/Developer/Xcode/UserData/Provisioning\ Profiles
certs_zip_path="../../notes/certificates.zip"
certs_tmp_root="$tmp_root/certs"
