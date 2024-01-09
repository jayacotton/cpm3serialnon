# cpm3serialnon
cpm3 non banked serial console 

This repo is a copy of the code zip file at s100computers.com

I use this to allow multi machine build environment.

The first modification is the use the eprom (master0 v5.4) for console i/o.
caviot: There is no way to find the correct jump address's automaticly so you
need to edit chario3.asm to set the correct address's.

Also the relocator will make a mess out of your jump address's so you need to
encode them at data bytes.
