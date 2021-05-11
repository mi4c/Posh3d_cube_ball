# Posh3d_cube_ball
My Background, i'm not a coder or advanced powershell scripter, just some n00b scripter. If I would be a coder I would have done this all with some other language. Or I would have used Unity or Blender... I just want to do pure powershell...
I have some basic skills to do some powershell scripting and I do understand little c-sharp to be able to translate it to powershell code.
Many examples rely on injecting c-sharp code into powershell code, I try to avoid that and stay with the pure powershell syntax.
I really don't think I'm an advanced powershell scripter even I do share this "for fun" created script, that I do develop continuously. - I have to remember edit this sentence when I stop developing it. :D

This is just my test how to do some 3D graphics with powershell...
And to get more familiar with powershell classes.

Issue: Powershell does close the console itself as a built in safety reason, when multiple commands try to control the script.
I try to overcome with that and find a way how to get this working without moving up to use some other language.
I know I can run in runspaces multiple things, I have a version of this already working, but I don't share it currently.

Currently issue is that I try to give user too much control with timer ticks and key presses that are too fast and that triggers the powershell safety process.
Powershell idea is: better not to give a script ability to do it's own than give something that is not anymore accurate...

Move ball with keys up,down,left,right

Look ball up and down with keys t,g in camera3

Move skycam with keys w,s,a,d

zoomin/out skycam keys r,f

Change camera view num keys 1,2,3

Cam1 skycam
- maybe i'll try to transfer this camera under mouse control and change ball movent keys to wsad keys.

cam2 ball movement cam

cam3 ball lookcam, so you can look also up without messing the moving algorithm.
- i'm trying to transfer this camera free look into the mouse control

![fun1](/Screenshots/fun1.PNG)
![fun2](/Screenshots/fun2.PNG)
![fun3](/Screenshots/fun3.PNG)

