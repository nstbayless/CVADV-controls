# Improved Controls for Castlevania: The Adventure (Gameboy)

*By NaOH*

## Patching Instructions

There are patches for each combination of rom (US/EU; JP; EU Konami GB Vol. 1) and for vcancel and
inertia enabled/disabled (see "Functionality" below). Only one patch should be used.
Please note that the US and EU roms are the same. You may wish to verify your rom before patching by checking a hash (see "ROM HASHES" below).

Patch using FLIPS or any other IPS patcher. Please note that gameboy roms contain an internal checksum (which is not actually used by the gameboy!) -- this
patch does not modify the checksum, but if you so desire you may wish to correct the checksum using a utilitiy such as rgbfix.

## Functionality

This hack adjusts Christopher Belmont's control scheme to be more like Mega Man, Super Mario, Symphony of the Night, or Castlevania: Legends.

- Belmont can now turn around and stop in mid-air.
- Belmont regains control during knockback.
- (vcancel patches only!) When the jump button is released, Belmont immediately starts falling again; this allows the player to make smaller hops if desired.
- (inertia patches only!) When adjusting velocity in mid-air, Belmont only accelerates slowly (rather than changing direction instantaneously).
- Belmont blinks rapidly when struck, as in Castlevania II: Belmont's Revenge.

## Compatability with other hacks

Should be compatible with the speed and/or whip hacks: https://www.romhacking.net/hacks/6762/ (apply the controls hack last.)

## Source Code

The assembly and build scripts for this hack are available on github. Please take a look.

    https://github.com/nstbayless/CVADV-controls

## ROM Hashes

US/EU ROM:
    MD5: 0b4410c6b94d6359dba5609ae9a32909
    SHA256: edb101e924f22149bdcbcfe6603801fdb4ec0139a40493d700fa0205f6dab30c
    CRC32: 216e6aa1

JP ROM:
    MD5: 94135fb63d77d48d2396c60ca8823b69
    SHA256: 5d8ba1f7cd9ee6cd14dca5132b651cf248e08ff7d4274c1d883fbaa5597309e5
    CRC32: a35b9ef5
    
Konami Gameboy Collection Vol. 1 (EU) ROM:
    MD5: 70ccaf1c458dc09b7c703191ef9b8541
    SHA256: 04101e6b6aa9ed4098cabc91e07e087fe03349bd18a82834f3e9987986120717
    CRC32: 203f8727