VideoLoopingDemo
================

iOS demo for custom video player with looping capabilities


Apple's MPMoviePlayerController is an excellent starting point for most applications.
It can get you running very quickly and you can do a lot of customization by adding subviews.
However, sometimes you need to do something beyond its capabilities and in that case you may wish to implement
a custom movie player using AVFoundation.  This is a fairly simple example of a custom player that also includes
a custom looping control.

The looping control appears in the app as a modified video time scrubber but adds the option of looping the video
in four different ways.

No-loop
Loop the entire video
Loop a custom portion of the video
Loop a pre-selected section of the video as specified by parameters passed in at playback

