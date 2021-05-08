#REQUIRES -version 5
<#PSScriptInfo
.VERSION 1.0
.GUID 33c74633-0fa9-447c-8964-5a3274b09d56
.AUTHOR markus.kalske@hotmail.com
.COMPANYNAME 
.COPYRIGHT Markus Kalske
.TAGS
.LICENSEURI 
.PROJECTURI 
.ICONURI 
.EXTERNALMODULEDEPENDENCIES 
.REQUIREDSCRIPTS 
.EXTERNALSCRIPTDEPENDENCIES 
.RELEASENOTES
#>

<# 
.DESCRIPTION 
 3D fun stuff with powershell
.NOTES    
    This powershell script is build up based from c-sharp learning material and examples that is available via internet.
    - http://csharphelper.com/blog/2014/10/create-a-3d-surface-more-quickly-with-wpf-xaml-and-c/
    - http://csharphelper.com/blog/2017/05/make-3d-globe-wpf-c/
    - https://www.codeproject.com/Articles/125694/How-To-Make-A-Walking-Robot-In-WPF-Part-3-Emissive
    - https://www.codeproject.com/Articles/1087090/WFTools-D-A-Small-WPF-Library-To-Build-D-Simulatio
    Also some minor example how to do something in powershell was found from here
    - https://gist.github.com/nikonthethird/2ab6bfad9a81d5fe127fd0d1c2844b7c
    - https://devblogs.microsoft.com/scripting/weekend-scripter-create-a-holiday-greeting-using-powershell-and-wpf/

#> 
Using Assembly PresentationCore
Using Assembly PresentationFramework
Using Namespace System.Windows
Using Namespace System.Drawing
using namespace Microsoft.Windows.PowerShell.Gui.Internal
Using Namespace System.Windows.Markup
using Namespace System.Windows.Controls
using Namespace System.Windows.Media
using Namespace System.Windows.Media.Media3D
Using namespace System.Windows.Media.Effects
Using Namespace System.Windows.Input
using namespace System.Windows.Media.Animation
using namespace System.Windows.DependencyObject
Using Namespace System.Windows.Threading
using namespace System.Diagnostics
using namespace System.Collections.Generic
using namespace System.Runtime.InteropServices
using namespace System.Windows.Controls.Primitives
Using Namespace System.ComponentModel
Using Namespace System.Linq
Using Namespace System.Reflection
Using Namespace System.Text
[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null


<#
    .SYNOPSIS
    Move ball
    .DESCRIPTION
    3D fun stuff with powershell
    This example is built from instruction examples found at http://csharphelper.com/blog/2014/10/draw-a-3d-surface-with-wpf-xaml-and-c/
    .NOTES
    SCRIPT REVISION NOTES:
    INIT  DATE        VERSION    NOTES
    MK    2019-12-29  1.0        Initial Script Release
#>

function Cleanup-Variables {
    <#
    .SYNOPSIS
    Clean all variables that were loaded and used in this powershell session.
    .DESCRIPTION
    Clean all variables.
    .COMPONENT
    pshTemplate
    .ROLE
    Call this function end of your script.
    .PARAMETER    
    .EXAMPLE    
    .NOTES
    SCRIPT REVISION NOTES:
    INIT  DATE        VERSION    NOTES
    MK    2015-08-05  1.0        Initial Script Release

    UNIT TEST AND VERIFICATION INSTRUCTIONS:    
    #>
    Get-Variable -ErrorAction SilentlyContinue | Where-Object { $startupVariables -notcontains $_.Name } | % { Remove-Variable -Name "$($_.Name)" -Force -Scope "global" -ErrorAction SilentlyContinue }
} # function Cleanup-Variables

. .\class\MathUtils.ps1
. .\class\WpfTriangle.ps1
. .\class\WpfRectangle.ps1
. .\class\WpfCube.ps1
. .\class\WpfCylinder.ps1
. .\class\WpfSphere.ps1
. .\class\storyboard.ps1
. .\class\camerabox.ps1
. .\class\scene3d.ps1


# Because powershell is a runtime code, we cannot use XAML x:Class attribute and commit the code behind this. This behaviour requires compiler and powershell doesn't provide that.
# For this reason we loose ability to call code behind XAML to call keydown and mousedown etc. things.
# If you want to use keys or mouse commands you need to register those on the fly and hoopup on the fly to the wanted object, so not the most ideal situation for the realtime commands to commit.
# There is an issue with realtime register keys, after enough key presses to fast committed the powershell crashes.
[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    x:Name="Window" Title="3D fun stuff" Height="500" Width="500">
    <Grid x:Name="Grid">
        <Viewport3D Grid.Row="0" Grid.Column="0"
            Name="MainViewport" />
    </Grid>
</Window>
"@

# Change in CameraPhi up/down Option Constant prevents this value to be changed
New-Variable -Name FlyCameraDPhi -Value 0.05 -Option Constant
New-Variable -Name FlyCameraDTheta -Value 0.05 -Option Constant
New-Variable -Name FlyCameraDR -Value 0.05 -Option Constant


Function durationM([double]$seconds)
{
    [int]$milliseconds = [int]($seconds * 1000);
    return $milliseconds;
}

Function durationTS([double]$seconds)
{
    $ts = New-Object TimeSpan(0, 0, 0, 0, (durationM($seconds)));
    return $ts;
}


Function positionLight
{
    Param(
    [System.Windows.Media.Media3D.Point3D]$position
    )
    [System.Windows.Media.Media3D.DirectionalLight]$directionalLight = New-Object System.Windows.Media.Media3D.DirectionalLight
    $color = [System.Drawing.Color]::gray
    $mediaColor = [System.Windows.Media.Color]::FromArgb($color.A, $color.R, $color.G, $color.B)
    $directionalLight.Color = $mediaColor
    $directionalLight.Direction = [System.Windows.Media.Media3D.Point3D]::new(0, 0, 0) - $position;
    return $directionalLight;
}

Function getOrigin{
    Param(
        [System.Windows.Media.Media3D.GeometryModel3D]$model,
        [Double]$x,
        [Double]$y,
        [Double]$z
    )
    [System.Windows.Media.Media3D.Point3D]$origin = "$((([double]$model.Bounds.Location.X) + ([double]$model.Bounds.SizeX / 2)),((([double]$model.Bounds.Location.Y)) + (([double]$model.Bounds.SizeY) / 2)),(([double]$model.Bounds.Location.Z) + ([double]$model.Bounds.SizeZ / 2)))"
    Return [System.Windows.Media.Media3D.Point3D]$origin
}

function turnModel{
    Param(
        [System.Windows.Media.Media3D.Point3D]$center,
        [System.Windows.Media.Media3D.GeometryModel3D]$model,
        [System.Windows.Media.Media3D.Model3DGroup]$modelgroup,
        [double]$beginAngle,
        [double]$endAngle,
        [double]$seconds,
        [bool]$forever
    )
    # vectors serve as 2 axes to turn our model
    $vector = New-Object System.Windows.Media.Media3D.Vector3D(0, 1, 0);
    $vector2 = New-Object System.Windows.Media.Media3D.Vector3D(1, 0, 0);
    $vector3 = New-Object System.Windows.Media.Media3D.Vector3D(0, 0, 1);

    # create rotations to use.  we can set a 0.0 degrees for our rotations since we are going to animate them
    $rotation = New-Object System.Windows.Media.Media3D.AxisAngleRotation3D($vector, 0.0);
    $rotation2 = New-Object System.Windows.Media.Media3D.AxisAngleRotation3D($vector2, 0.0);
    $rotation3 = New-Object System.Windows.Media.Media3D.AxisAngleRotation3D($vector3, 0.0);

    # create double animations to animate each of our rotations
    $doubleAnimation = New-Object System.Windows.Media.Animation.DoubleAnimation($beginAngle, $endAngle, (durationTS($seconds)));
    $doubleAnimation2 = New-Object System.Windows.Media.Animation.DoubleAnimation($beginAngle, $endAngle, (durationTS($seconds)));
    $doubleAnimation3 = New-Object System.Windows.Media.Animation.DoubleAnimation($beginAngle, $endAngle, (durationTS($seconds)));

    # set the repeat behavior and duration for our animations
    if ($forever)
    {
        $doubleAnimation.RepeatBehavior = "Forever";
        $doubleAnimation2.RepeatBehavior = "Forever";
        $doubleAnimation3.RepeatBehavior = "Forever";
    }

    $doubleAnimation.BeginTime = durationTS(0.0);
    $doubleAnimation2.BeginTime = durationTS(0.0);
    $doubleAnimation3.BeginTime = durationTS(0.0);

    # create 2 rotate transforms to apply to our model.  each needs a rotation and a center point
    $rotateTransform = New-Object System.Windows.Media.Media3D.RotateTransform3D($($rotation), $center);
    $rotateTransform2 = New-Object System.Windows.Media.Media3D.RotateTransform3D($($rotation2), $center);
    $rotateTransform3 = New-Object System.Windows.Media.Media3D.RotateTransform3D($($rotation3), $center);

    # create a transform group to hold our 2 transforms
    $transformGroup = New-Object System.Windows.Media.Media3D.Transform3DGroup;
    $transformGroup.Children.Add($rotateTransform);
    $transformGroup.Children.Add($rotateTransform2);
    $transformGroup.Children.Add($rotateTransform3);

    # set our model transform to the transform group 
    if($model){
        $model.Transform = $transformGroup;
    }
    if($modelgroup){
        $modelgroup.Transform = $transformGroup;
    }

    # begin the animations -- specify a target object and property for each animation -- in this case,
    # the targets are the two rotations we created and we are animating the angle property for each one
    $rotation.BeginAnimation([System.Windows.Media.Media3D.AxisAngleRotation3D]::AngleProperty, $doubleAnimation);
    $rotation2.BeginAnimation([System.Windows.Media.Media3D.AxisAngleRotation3D]::AngleProperty, $doubleAnimation2);
    $rotation3.BeginAnimation([System.Windows.Media.Media3D.AxisAngleRotation3D]::AngleProperty, $doubleAnimation3);
}


Class Scene{
    static [double]$scenesize = 20
}

Class Window{
    [Double]$FlyCameraPhi = [Math]::PI / 8.0   # 30 degrees
    [Double]$FlyCameraTheta = [Math]::PI / 8.0 # 30 degrees
    [Double]$FlyCameraR = 30.0
    [System.Xml.XmlNodeReader]$reader

    # Jos tyypitän tämän niin hajoaa
    $window
    [double]$floorthickness = [scene]::scenesize / 100
    $viewport

    # tehdään constructori
    # Jos tyypitän $window niin hajoaa
    Window([System.Xml.XmlNodeReader]$reader,$window){
        $this.reader = $reader
        $this.window = $window
    }
}

Function myAmbientLight{
    $newcolor = (new-object System.Windows.Media.Media3D.AmbientLight -property @{Color = 'black'})
    $transformgroup.Children.Add($newcolor)
}

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)
# Tee Window luokka ja suorita se
$test = [Window]::new([System.Xml.XmlNodeReader]$reader,[System.Windows.Window]$window)
$test.window.Add_Loaded({
    $test.window.content.ShowGridLines = $true
    $test.window.content.Background = 'Black'
    $Global:MainViewPort = $test.window.FindName('MainViewport')
    # create a cube with dimensions as some fraction of the scene size
    [WpfCube]$cube = [WpfCube]::new($([System.Windows.Media.Media3D.Point3D]("0, 3, 0")), ([scene]::scenesize / 6), ([scene]::scenesize / 6), ([scene]::scenesize / 6))
    # construct our geometry model from the cube object
    [System.Windows.Media.Media3D.GeometryModel3D]$cubeModel = $cube.CreateModel([System.Drawing.Color]::Aquamarine)
    [System.Windows.Media.Media3D.GeometryModel3D]$floorModel = [WpfCube]::CreateCubeModel("$(-([scene]::scenesize / 2),-($floorthickness),-([scene]::scenesize/2))",([scene]::scenesize),$floorthickness,[scene]::scenesize,[System.Drawing.Color]::Tan)
    # create a model group to hold our model
    [System.Windows.Media.Media3D.Model3DGroup]$global:groupScene = New-Object System.Windows.Media.Media3D.Model3DGroup
    [Sphere]$sphere = [Sphere]::New($([System.Windows.Media.Media3D.Point3D]("0, 3, 0")), ([scene]::scenesize / 100), ([scene]::scenesize / 100), ([scene]::scenesize / 100),2.74066683953478,0.6,8.00816300307612)
    [Sphere]$spheresky = [Sphere]::New($([System.Windows.Media.Media3D.Point3D]("0, 3, 0")), ([scene]::scenesize), ([scene]::scenesize), ([scene]::scenesize),0,0,0)
    [Sphere]$global:ball = [Sphere]::New($sphere,2.74066683953478,1.0,8.00816300307612,1,20,30,"face.jpg",$true)
    [Sphere]$opponentball = [Sphere]::New($sphere,0,1.0,0,1,20,30,"face.jpg",$true)
    [Sphere]$sky = [Sphere]::New($spheresky,0,0.0,0,50,20,30,"Sky.jpg",$false)
    # add our cube to the model group
    $groupScene.Children.Add($cubeModel)
    $groupScene.Children.Add($floorModel)
    # add a directional light
    $groupScene.Children.Add((positionLight -position ("$(-([scene]::scenesize), ([scene]::scenesize / 2), 0.0)")))
    # add ambient lighting
    $groupScene.Children.Add((new-object System.Windows.Media.Media3D.AmbientLight -property @{Color = 'gray'}))
    # add a camera
    $global:camera = [CameraBox]::new()
    $global:camera2 = [CameraBox]::new()
    $global:camera3 = [CameraBox]::new()
    $MainViewPort.camera = $camera2.camera
    $camera.camera.lookdirection = "-0.999925369660457,0,0.0122170008352693"
    $camera.camera.position = $ball.origin
    $camera3.camera.lookdirection = "-0.999925369660457,0,0.0122170008352693"
    $camera3.camera.position = $ball.origin
    $camera2.camera.position = [System.Windows.Media.Media3D.Point3D]::new(-[Scene]::scenesize, [Scene]::scenesize / 2, [Scene]::scenesize)
    $camera2.camera.LookDirection = [System.Windows.Media.Media3D.Vector3D]::new(20,-10,-20);
    $camera2.camera.FieldOfView = 60
    # create a visual model that we can add to our viewport
    $visual = New-Object System.Windows.Media.Media3D.ModelVisual3D
    $spherevisual = New-Object System.Windows.Media.Media3D.ModelVisual3D
    $opponentvisual = New-Object System.Windows.Media.Media3D.ModelVisual3D
    $skyvisual = New-Object System.Windows.Media.Media3D.ModelVisual3D
    # populate the visual with the geometry model we made
    $visual.Content = $groupScene
    $spherevisual.content = ($ball.GetModelGroup())
    $opponentvisual.content = ($opponentball.GetModelGroup())
    $skyvisual.content = ($sky.GetModelGroup())
    $MainViewPort.Children.Add($visual)
    $MainViewPort.Children.Add($spherevisual)
    $MainViewPort.Children.Add($opponentvisual)
    $MainViewPort.Children.Add($skyvisual)
    $cubeModelOrigin = getOrigin -model $cubeModel
    $global:transformGroup = New-Object System.Windows.Media.Media3D.Transform3DGroup;
    turnModel -center $cubeModelOrigin -model $cubeModel -beginAngle 0 -endAngle 360 -seconds 3 -forever $true
    turnModel -center $sky.origin -modelgroup $sky.GetModelGroup() -beginAngle 0 -endAngle 360 -seconds 960 -forever $true
    [double]$camera.amount = 0.00
    [double]$Camera.amount *= $Camera.Scale
    $timer.Start()
})

[Int32] $stepsMilliseconds = 50

[DispatcherTimer] $timer = New-Object DispatcherTimer -Property @{
    Interval = New-Object TimeSpan 0, 0, 0, 0, $stepsMilliseconds
}

Function TimerTick([object]$sender, [EventArgs]$e)
		{
		}
$timer.add_Tick({
	if($Camera.MovingUpDirectionIsLocked -eq $true){
        $camera.Move($camera.camera.LookDirection, +$camera.amount)
        $ball.Move("$($camera.camera.LookDirection.X),$($camera.camera.LookDirection.Y),$($camera.camera.LookDirection.Z)", +$camera.amount)
        $camera3.Move($camera.camera.LookDirection, +$camera.amount)
    }
    elseif($Camera.MovingDownDirectionIsLocked -eq $true){
        $camera.Move($camera.camera.LookDirection, -$camera.amount)
        $inverseX = [double]$camera.camera.LookDirection.X * -1
        $inverseY = [double]$camera.camera.LookDirection.Y * -1
        $inverseZ = [double]$camera.camera.LookDirection.Z * -1
        $ball.Move("$inverseX,$inverseY,$inverseZ", +$camera.amount)
        $camera3.Move($camera.camera.LookDirection, -$camera.amount)
    }
})
[System.Windows.EventManager]::RegisterClassHandler([system.windows.Window], [Keyboard]::KeyDownEvent , [KeyEventHandler]{
    Param ([Object] $sender, [System.Windows.Input.KeyEventArgs]$eventArgs)
        Switch ($eventArgs.key){
            'up'{
                $Camera.MovingUpDirectionIsLocked = $true
                if($Camera.MovingDownDirectionIsLocked -eq $true){
                    [double]$camera.amount = 0.00
                    $Camera.MovingDownDirectionIsLocked = $false
                    $Camera.MovingUpDirectionIsLocked = $true
                    Break;
                }
                elseif($camera.amount -le 0.34) {
                    [double]$camera.amount = ([double]$camera.amount + 0.02)
                    [double]$Camera.amount *= $Camera.Scale
                    $Camera.MovingDownDirectionIsLocked = $false
                    $Camera.MovingUpDirectionIsLocked = $true
                    Break;
                }
            }
            'Down'{
                $Camera.MovingDownDirectionIsLocked = $true
                if($Camera.MovingUpDirectionIsLocked -eq $true){
                    [double]$camera.amount = 0.00
                    $Camera.MovingUpDirectionIsLocked = $false
                    $Camera.MovingDownDirectionIsLocked = $true
                    Break;
                }
                elseif($camera.amount -le 0.34) {
                    [double]$camera.amount = ([double]$camera.amount + 0.02)
                    [double]$Camera.amount *= $Camera.Scale
                    $Camera.MovingUpDirectionIsLocked = $false
                    $Camera.MovingDownDirectionIsLocked = $true
                    Break;
                }
            }
            'Left'{
                [double]$turnamount = 5
                $Camera.ChangeYaw($turnamount)
                [System.Windows.Media.Media3D.Vector3D]$vector = New-Object System.Windows.Media.Media3D.Vector3D(0, 1, 0)
                $ball.Rotate($vector,$turnamount)
                $Camera3.ChangeYaw($turnamount)
                Break;
            }
            'Right'{
                [double]$turnamount = 5
                $Camera.ChangeYaw(-$turnamount)
                [System.Windows.Media.Media3D.Vector3D]$vector = New-Object System.Windows.Media.Media3D.Vector3D(0, -1, 0)
                $ball.Rotate($vector,$turnamount)
                $Camera3.ChangeYaw(-$turnamount)
                Break;
            }
            'D1'{
                $MainViewPort.camera = $camera2.camera
                Break;
            }
            'D2'{
                $MainViewPort.camera = $camera.camera
                Break;
            }
            'D3'{
                $MainViewPort.camera = $camera3.camera
                Break;
            }
            'w'{
                $direction = "up"
                $camera2.PositionFlyCamera($camera2.FlyCameraPhi,$flyCameraDPhi,$direction)
                Break;
            }
            's'{
                $direction = "down"
                $camera2.PositionFlyCamera($camera2.FlyCameraPhi,$flyCameraDPhi,$direction)
                Break;
            }
            'a'{
                $direction = "left"
                $camera2.PositionFlyCamera($camera2.FlyCameraTheta,$FlyCameraDTheta,$direction)
                Break;
            }
            'd'{
                $direction = "right"
                $camera2.PositionFlyCamera($camera2.FlyCameraTheta,$FlyCameraDTheta,$direction)
                Break;
            }
            'r'{
                $direction = "zoomin"
                $camera2.PositionFlyCamera($camera2.FlyCameraR,$FlyCameraDR,$direction)
                Break;
            }
            'f'{
                $direction = "zoomout"
                $camera2.PositionFlyCamera($camera2.FlyCameraR,$FlyCameraDR,$direction)
                Break;
            }
            't'{
                [double]$turnamount = 5
                $Camera3.ChangePitch($turnamount)
                Break;
            }
            'g'{
                [double]$turnamount = 5
                $Camera3.ChangePitch(-$turnamount)
                Break;
            }
            'space'{
                Write-Warning "välilyöntiä painettu"
                # Tähän kutsu animointiin, jotta saadaan pallo hyppää animoidusti
                [System.Windows.Namescope]::SetNameScope($this,[system.windows.NameScope]::new())
                $ball.jump()
                Break;
            }
        }
})


[System.Windows.EventManager]::RegisterClassHandler([system.windows.Window], [Keyboard]::KeyUpEvent , [KeyEventHandler] {
Param ([Object] $sender, [System.Windows.Input.KeyEventArgs]$eventArgs)
})



$test.window.ShowDialog() | Out-Null

#$mainWindow.ShowDialog() | Out-Null
Cleanup-Variables


