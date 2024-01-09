rm cpm3-nonbanked-serial.img
cp cpm3-nonbanked-serial/CPMLDR.COM .
cp cpm3-nonbanked-serial/CPM3.SYS .
mkfs.cpm -f s100ide -b LBA0.COM -b CPMLDR.COM -t cpm3-nonbanked-serial.img
cpmcp -f s100ide cpm3-nonbanked-serial.img CPM3.SYS 0:
cpmcp -f s100ide cpm3-nonbanked-serial.img CCP.COM 0:
cpmchattr -f s100ide cpm3-nonbanked-serial.img s ccp.com 0:
cpmcp -f s100ide cpm3-nonbanked-serial.img ./CPM3-BASE/*.* 0:
cpmcp -f s100ide cpm3-nonbanked-serial.img ./S100-TOOLS/*.* 1:
cpmcp -f s100ide cpm3-nonbanked-serial.img ./WS4-FILES/*.* 2:
cpmcp -f s100ide cpm3-nonbanked-serial.img ./BASIC-FILES/*.* 3:
cpmcp -f s100ide cpm3-nonbanked-serial.img ./GAMES/*.* 4:


