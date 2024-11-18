# Camp Counselor

A simple application for managing your bandcamp wishlist.

(c) 2023 Marcus Dillavou <line72@line72.net>

Released under the GPLv3 or later

## Installing

Install from [FlatHub.org](https://flathub.org/apps/net.line72.campcounselor).

## Building

You'll need:

- vala
- libgda 6
- gtk4

```
mkdir build
cd build

# Configure
meson ..

# build
ninja

# install
sudo ninja install
```

## Icon

The icon was created using [imaginer](https://imaginer.codeberg.page/) with the following prompt:

```
Draw a Logo for an application called Camp Counselor, logo, color palette, 6 colors
```

and Negative Prompt:

```
text
```

using the OpenJourney provider. It was then tweaked.
