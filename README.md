VideoLoopingDemo
================

iOS demo for custom video player with looping capabilities


Apple's MPMoviePlayerController is an excellent starting point for most applications.
It can get you running very quickly and you can do a lot of customization by adding subviews.
However, sometimes you need to do something beyond its capabilities and in that case you may wish to implement
a custom movie player using AVFoundation.  This is a fairly simple example of a custom player that also includes
a custom looping control.  You may want to implement your own custom video player if you need to play more than
one movie at once or if you need to completely customize the player controls.  Feel free to use this example
as a starting point.  The code is far from perfect - it was originally written for iOS 5 and was pre ARC and before auto-layout.  

The looping control appears in the app as a modified video time scrubber but adds the option of looping the video
in four different ways.

No-loop
Loop the entire video
Loop a custom portion of the video
Loop a pre-selected section of the video as specified by parameters passed in at playback


When a user chooses to use the custom portion of the video option, they will be able to drag cut point controls
on the scrubber to set a begin and end point for the section they wish to loop.  These cut points will be saved
to core data.


Build Notes:

This project uses Cocoa Pods.  Currently the only pod needed is Magical Record which is used to simplify the
implementation to save and reload the custom video cut points.
