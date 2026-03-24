#! /bin/sh
./build.sh

mkdir -p bin/miniMem.app/Contents/MacOS
mkdir -p bin/miniMem.app/Contents/Resources
cp bin/miniMem bin/miniMem.app/Contents/MacOS/miniMem
cp assets/low_pressure.svg bin/miniMem.app/Contents/Resources/low_pressure.svg
cp assets/medium_pressure.svg bin/miniMem.app/Contents/Resources/medium_pressure.svg
cp assets/high_pressure.svg bin/miniMem.app/Contents/Resources/high_pressure.svg
cp assets/Info.plist bin/miniMem.app/Contents/Info.plist

mkdir -p bin/ac_tmp
actool assets/liquid_glass.icon --compile bin/ac_tmp \
--minimum-deployment-target 26.0 --platform macosx \
--app-icon liquid_glass --include-all-app-icons \
--output-partial-info-plist bin/ac_tmp/Info.plist >/dev/null

cp bin/ac_tmp/Assets.car bin/miniMem.app/Contents/Resources/Assets.car
cp bin/ac_tmp/liquid_glass.icns bin/miniMem.app/Contents/Resources/liquid_glass.icns
rm -rf bin/ac_tmp
rm bin/miniMem