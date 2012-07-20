---
date: '2010-09-26'
title: XBMC on Zotac Zbox HD-ID11
tags: [howto, xbmc]
encoding: utf-8
---

**Update:** *Since doing this I've installed [OpenELEC.tv] instead. This is a XBMC distribution that aims to be lean (~80MB for the entire system), optimized to run from flash storage and boots very fast. Installation took under minute.*

*Instead of messing with asound.conf I entered plughw:0,7 as a custom audio device in the XBMC configuration screen for audio. This won't get you navigation sounds, but atleast it works with video.*

[OpenELEC.tv]:http://openelec.tv/


I've bought a [Zotac Zbox HD-ID11] with the intent of running [XBMC] on it as a
replacement for my now old Popcorn Hour A-100. To keep the cost down I decided
to make do with 1Gb of RAM and to run the OS from a [SD card].

[Zotac Zbox HD-ID11]: http://zotac.com/index.php?option=com_wrapper&view=wrapper&Itemid=100083&lang=en
[XBMC]: http://xbmc.org/
[SD card]: http://www.prisjakt.nu/produkt.php?p=443866

In total this gives med a full HD-capable HTPC for roughly 2500 SEK

Actually installing XBMC on this thing proved to be somehwat harder than anticipated so here's what I did to get everything installed.

## Installing XBMC

XBMC and [XBMCFreak] release live systems as ISO-images that can be put on a CD or USB stick for booting into a live XBMC-system. XBMCFreak aims to make these images work with ION-base systems such as the HD-ID11. I haven't had much luck with either of them though out of the box.

First obstacle has been actually getting a bootable USB-stick. I've tried a couple of tools that claimed to be capable of turning andy ISO of a live system into a bootable USB. None did an impressive job on the XBMC ISOs. Starting from a pure Ubuntu system might work though.

In the end I used XBMCFreaks special [USB edition]. However if I were to do it again I would probably start from a stock Ubuntu ISO. Upgrading from Lucid to Maverick while keeping the xbmc-live package intact provided some challenge.

[XBMCFreak]: http://www.xbmcfreak.nl/
[USB edition]: http://www.xbmcfreak.nl/xbmcfreak-usblive-10-00-beta2/

To get the system to play nice with the SD-card while booting from USB I had to make sure that the SD-card wasn't installed while booting. To get the installation to succeed with partitioning the card I instead inserted it after the disk detection had failed and reran the detection.

## Configuring Audio

The most frustrating thing about this whole experience has been getting the HDMI audio to work. Scanning the web for help gives lots of usless advice that mostly doesn't work, and almost never provide any rationale for the suggestions.

To actually pipe sound through the HDMI-interface you need the GPU up and running. Apparently audio and video has to be mixed in some funny way involving the NVidia
drivers. So make sure the nvidia drivers are 190+ (I'm running 260 something now) and that the xorg server is running when testing stuff.

The actual problem is that the hardware is quite new and thus the drivers [hasn't quite caught up yet][hdaudio]. To have any shot of getting it to work you need ALSA version 1.0.23.

[hdaudio]: http://www.kernel.org/pub/linux/kernel/people/tiwai/docs/HD-Audio.html

<pre>
  xbmc@XBMCLive:~$ cat /proc/asound/version
  Advanced Linux Sound Architecture Driver Version 1.0.23.
</pre>

Now there seems to be two way to achieve this:

* Update to the latest ALSA release by compiling the source. To this end there is [this handy script][updatealsa] doing all the work.
* Run Ubuntu Maverick Meerkat as your base system. (This is what I did)

[updatealsa]: http://ubuntuforums.org/showthread.php?p=6589810

Step two is to make sure the correct audio device is used when playing audio. For some reason the driver will provide you with four different HDMI interfaces.
<pre>
  xbmc@XBMCLive:~$ aplay -l
  **** List of PLAYBACK Hardware Devices ****
  card 0: NVidia [HDA NVidia], device 3: NVIDIA HDMI [NVIDIA HDMI]
    Subdevices: 1/1
    Subdevice #0: subdevice #0
  card 0: NVidia [HDA NVidia], device 7: NVIDIA HDMI [NVIDIA HDMI]
    Subdevices: 0/1
    Subdevice #0: subdevice #0
  card 0: NVidia [HDA NVidia], device 8: NVIDIA HDMI [NVIDIA HDMI]
    Subdevices: 1/1
    Subdevice #0: subdevice #0
  card 0: NVidia [HDA NVidia], device 9: NVIDIA HDMI [NVIDIA HDMI]
    Subdevices: 1/1
    Subdevice #0: subdevice #0
</pre>

By default I guess device 3 is used. This won't produce much audio though so you have to tell the system to use one of the other interfaces (a wild guess is that theese interfaces needs to be combined in some manner to enable full surround. As I'm only aiming for 2.0 I can't really tell though).

One way to achieve this is to add this configuration to */etc/asound.conf* (just create the file, [it isn't supposed to be there by default][asoundrc]):
<pre>
pcm.!default {
type hw
card 0
device 7
}
ctl.!default {
type hw
card 0
}
</pre>

[asoundrc]: http://alsa.opensrc.org/.asoundrc

There are som tips scattered around the web involving apllying patches and messing around with the internals of ALSA and module loading to get everything setup. For me it was enough to get ALSA 1.0.23 installed and picking the correct audio device as default.

