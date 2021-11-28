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
#Using Assembly PresentationCore
#Using Assembly PresentationFramework
Using Namespace System
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
using namespace System.Windows.DependencyProperty
Using Namespace System.Windows.Threading
using namespace System.Diagnostics
using namespace System.Collections.Generic
using namespace System.Runtime.InteropServices
using namespace System.Windows.Controls.Primitives
Using Namespace System.ComponentModel
Using Namespace System.Linq
Using Namespace System.Reflection
Using Namespace System.Text
using Namespace System.Windows.Navigation;
using Namespace System.Windows.Data;
using Namespace System.Windows.Documents;
using Namespace System.Windows.Media.Imaging;
using Namespace System.Windows.Shapes;
[System.Reflection.Assembly]::LoadWithPartialName("PresentationCore") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("PresentationFramework") | Out-Null
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

Trap{
    TrapHandler
}

Function Write-log{
    Param(
        [Parameter(Mandatory = $true,ValueFromPipeline = $true)][String]$msg
    )
    Add-Content .\debug.log "$(Get-Date -Format yyyy-MM-dd_HH:mm): $msg"
}

Function TrapHandler{
    $Global:ErrDescription = ($_.toString() + $_.InvocationInfo.PositionMessage).replace("`r",", ").replace("~","")
    if($Error){
        $Error | Format-List | Out-String | Out-File -Append .\debug.log
    }
}

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
. .\class\camerabox.ps1
. .\class\scene3d.ps1


# Because powershell is a runtime code, we cannot use XAML x:Class attribute and commit the code behind this. This behaviour requires compiler and powershell doesn't provide that.
# For this reason we loose ability to call code behind XAML to call keydown and mousedown etc. things.
# If you want to use keys or mouse commands you need to register those on the fly and hookup on the fly to the wanted object, so not the most ideal situation for the realtime commands to commit.
# There is an issue with realtime register keys, after enough key presses too fast committed the powershell crashes.
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
New-Variable -Name FlyCameraDR -Value 0.25 -Option Constant


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

    [Int]durationM([double]$seconds)
    {
        [int]$milliseconds = ($seconds * 1000);
        return $milliseconds;
    }

    [System.TimeSpan]durationTS([double]$seconds)
    {
        $ts = New-Object System.TimeSpan(0, 0, 0, 0, $this.durationM($seconds));
        return $ts;
    }
}

Add-Type -TypeDefinition @"
using System;
using System.Threading;
using System.Runtime.InteropServices;
namespace W32API
{
    public static class Mouse
    {
        [DllImport("User32.dll")]
        public static extern bool SetCursorPos(int X,int Y);
    }
}
"@

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)
# record of the 3D models we build
$models = @{}
$models_check = @{}

$camera = [CameraBox]::new()
$camera2 = [CameraBox]::new()
$camera3 = [CameraBox]::new()

# create a cube with dimensions as some fraction of the scene size
[WpfCube]$cube = [WpfCube]::new($([System.Windows.Media.Media3D.Point3D]("0, 3, 0")), ([scene]::scenesize / 6), ([scene]::scenesize / 6), ([scene]::scenesize / 6))
# construct our geometry model from the cube object
[System.Windows.Media.Media3D.GeometryModel3D]$cubeModel = $cube.CreateModel([System.Drawing.Color]::Aquamarine)
[System.Windows.Media.Media3D.GeometryModel3D]$floorModel = [WpfCube]::CreateCubeModel("$(-([scene]::scenesize / 2),-($floorthickness),-([scene]::scenesize/2))",([scene]::scenesize),$floorthickness,[scene]::scenesize,[System.Drawing.Color]::Tan)
# create a model group to hold our model
[System.Windows.Media.Media3D.Model3DGroup]$groupScene = New-Object System.Windows.Media.Media3D.Model3DGroup
[Sphere]$sphere = [Sphere]::New($([System.Windows.Media.Media3D.Point3D]("0, 3, 0")), ([scene]::scenesize / 100), ([scene]::scenesize / 100), ([scene]::scenesize / 100),2.74066683953478,0.6,8.00816300307612)
[Sphere]$spheresky = [Sphere]::New($([System.Windows.Media.Media3D.Point3D]("0, 0, 0")), ([scene]::scenesize), ([scene]::scenesize), ([scene]::scenesize),0,0,0)
# $object, Point3D, Radius, num_phi, num_theta, imagefilename, Transparent, Name, models hashmap, Tag
[System.Windows.Media.Media3D.Point3D]$userstartlocation = "9.18277104297157,0.8,-8.98384814917402"
[Sphere]$ball = [Sphere]::New($sphere,$userstartlocation,1,20,30,"face.jpg",$false,"User",$models,"User")
#[Sphere]$ball = [Sphere]::New($sphere,-3.5527136788005E-15,-0.333333333333333,-3.5527136788005E-15,1,20,30,"face.jpg",$false,"User",$models,"User")
[System.Windows.Media.Media3D.Point3D]$opponentstartlocation = "-9.18524945901486,1,9.39554518710787"
# $object, Point3D, Radius, num_phi, num_theta, imagefilename, Transparent, Name, models hashmap, Tag
[Sphere]$opponentball = [Sphere]::New($sphere,$opponentstartlocation,1,20,30,"face.jpg",$false,"Ball2",$models,"Opponent")
# $object, Point3D, Radius, num_phi, num_theta, imagefilename, Transparent, Name, models hashmap, Tag
[System.Windows.Media.Media3D.Point3D]$Skystartlocation = "0,0,0"
[Sphere]$sky = [Sphere]::New($spheresky,$Skystartlocation,50,20,30,"Sky.jpg",$true,"Sky",$models,"Atmosphere")
# Create window class
$mainWindow = [Window]::new([System.Xml.XmlNodeReader]$reader,[System.Windows.Window]$window)
$MainViewPort = $mainWindow.window.FindName('MainViewport')
$models.Add($cubeModel,@{Name = "CubeModel"; Tag = "obstacle"})
$models_check.Add("obstacle",@{Tag = "CubeModel"; Model = $cubeModel})
$models.Add($floorModel,@{Name = "Floor"; Tag = "ground"})
$models_check.Add("ground",@{Tag = "ground"; Model = @($floorModel)})
$MainViewPort.camera = $camera2.camera
$MainViewPort.tag = "Camera2"
$camera.camera.lookdirection = "-0.999925369660457,0,0.0122170008352693"
#$camera.camera.position = "$($ball.origin.x),$($ball.origin.y-0.9999),$($ball.origin.z)"
$camera.camera.position = $ball.origin
$camera3.camera.lookdirection = "-0.999925369660457,0,0.0122170008352693"
$camera3.camera.position = $ball.origin
$camera2.camera.position = [System.Windows.Media.Media3D.Point3D]::new(-[Scene]::scenesize, [Scene]::scenesize / 2, [Scene]::scenesize)
$camera2.camera.LookDirection = [System.Windows.Media.Media3D.Vector3D]::new(20,-10,-20);
$camera2.camera.FieldOfView = 60
$ball.lookdirection = $camera.camera.lookdirection
$opponentball.lookdirection = $camera.camera.lookdirection
# create a visual model that we can add to our viewport
$visual = New-Object System.Windows.Media.Media3D.ModelVisual3D
$spherevisual = New-Object System.Windows.Media.Media3D.ModelVisual3D
$opponentvisual = New-Object System.Windows.Media.Media3D.ModelVisual3D
$skyvisual = New-Object System.Windows.Media.Media3D.ModelVisual3D
# populate the visual with the geometry model we made
$visual.Content = $groupScene
$spherevisual.content = ($ball.GetModelGroup())
#Write-Warning ($spherevisual.content | ConvertTo-Json)
$opponentvisual.content = ($opponentball.GetModelGroup())
$skyvisual.content = ($sky.GetModelGroup())
$transformGroup = New-Object System.Windows.Media.Media3D.Transform3DGroup;
#Write-Warning ($ball | convertto-json)

$mainWindow.window.Add_Loaded({
    $mainWindow.window.content.ShowGridLines = $true
    $mainWindow.window.content.Background = 'Black'
    # add our cube to the model group
    $groupScene.Children.Add($cubeModel)
    $groupScene.Children.Add($floorModel)
    # add a directional light
    $groupScene.Children.Add((positionLight -position ("$(-([scene]::scenesize), ([scene]::scenesize / 2), 0.0)")))
    # add ambient lighting
    $groupScene.Children.Add((new-object System.Windows.Media.Media3D.AmbientLight -property @{Color = 'gray'}))
    # add a camera
    $MainViewPort.Children.Add($visual)
    $MainViewPort.Children.Add($spherevisual)
    $MainViewPort.Children.Add($opponentvisual)
    $MainViewPort.Children.Add($skyvisual)
    $cubeModelOrigin = getOrigin -model $cubeModel
    #turnModel -center $cubeModelOrigin -model $cubeModel -beginAngle 0 -endAngle 360 -seconds 3 -forever $true
    turnModel -center $sky.origin -modelgroup $sky.GetModelGroup() -beginAngle 0 -endAngle 360 -seconds 960 -forever $true
    [double]$camera.amount = 0.00
    [double]$Camera.amount *= $Camera.Scale
    # Need to read into memory this to be able to use later
    $namescope = [System.Windows.Namescope]::SetNameScope($this,[system.windows.NameScope]::new())
    $Global:mythis = $this
    # Set Name Scope and register it with translate transform
    $mythis.RegisterName("UserBall", ($ball.getTranslateTransform()))
    $mythis.RegisterName("OpponentBall", ($opponentball.getTranslateTransform()));
})

    $MainViewPort.Add_MouseMove({
        Param ([Object] $sender, [MouseEventArgs]$eventArgs)
        if($MainViewPort.tag -eq "camera"){
            if($mainWindow.window.WindowState -eq 2){
                $WindowSizeWidth = $mainWindow.window.ActualWidth
                $WindowSizeHeight = $mainWindow.window.ActualHeight
                $CursorPositionX = $WindowSizeWidth/2
                $CursorPositionY = $WindowSizeHeight/2
            } else {
                $WindowPositionX = $mainWindow.window.Left
                $WindowPositionY = $mainWindow.window.Top
                $WindowSizeWidth = $mainWindow.window.ActualWidth
                $WindowSizeHeight = $mainWindow.window.ActualHeight
                $CursorPositionX = ($WindowPositionX + ($WindowSizeWidth/2))
                $CursorPositionY = ($WindowPositionY + ($WindowSizeHeight/2))
            }
            $null = [W32API.Mouse]::SetCursorPos($CursorPositionX,$CursorPositionY)

            if($mainWindow.window.WindowState -ne 2){
                # WINDOW
                # X
                [double]$xfactor = 0.50;
                [double]$yfactor = 0.25;
                if((($mainWindow.window.content.ActualWidth / 2) -gt $eventArgs.GetPosition($this).X) -and ($mainWindow.window.content.ActualWidth / 2) -ne $eventArgs.GetPosition($this).X){
                    # Left
                    [System.Windows.Media.Media3D.Vector3D]$axis = New-Object System.Windows.Media.Media3D.Vector3D(0, 1, 0)
                    $Camera.Rotate($axis,$xfactor,$Camera.position())
                    $Camera3.Rotate($axis,$xfactor,$Camera.position())
                    $ball.RotateX($xfactor)
                }
                elseif((($mainWindow.window.content.ActualWidth / 2) -lt $eventArgs.GetPosition($this).X) -and ($mainWindow.window.content.ActualWidth / 2) -ne $eventArgs.GetPosition($this).X){
                    # Right
                    [System.Windows.Media.Media3D.Vector3D]$axis = New-Object System.Windows.Media.Media3D.Vector3D(0, -1, 0)
                    $Camera.Rotate($axis,$xfactor,$Camera.position())
                    $Camera3.Rotate($axis,$xfactor,$Camera.position())
                    $ball.RotateX(-$xfactor)
                }
                #Y
                if(((($mainWindow.window.content.ActualHeight / 2)-11.5) -gt $eventArgs.GetPosition($this).Y) -and (($mainWindow.window.content.ActualHeight / 2)-11.5) -ne $eventArgs.GetPosition($this).Y){
                    # Up
                    $Camera.ChangePitch($yfactor)
                    $ball.RotateY($yfactor)
                } 
                elseif(((($mainWindow.window.content.ActualHeight / 2)-11.5) -lt $eventArgs.GetPosition($this).Y) -and (($mainWindow.window.content.ActualHeight / 2)-11.5) -ne $eventArgs.GetPosition($this).Y){
                    # Down
                    $Camera.ChangePitch(-$yfactor)
                    $ball.RotateY(-$yfactor)
                }
            } else {
                # FULL SCREEN
                # X
                [double]$xfactor = 0.50;
                [double]$yfactor = 0.25;
                if((($mainWindow.window.ActualWidth / 2) -gt $eventArgs.GetPosition($this).X) -and ($mainWindow.window.ActualWidth / 2) -ne $eventArgs.GetPosition($this).X){
                    # Left
                    [System.Windows.Media.Media3D.Vector3D]$axis = New-Object System.Windows.Media.Media3D.Vector3D(0, 1, 0)
                    $Camera.Rotate($axis,$xfactor,$Camera.position())
                    $Camera3.Rotate($axis,$xfactor,$Camera.position())
                    $ball.RotateX($xfactor)
                } 
                elseif((($mainWindow.window.ActualWidth / 2) -lt $eventArgs.GetPosition($this).X) -and ($mainWindow.window.ActualWidth / 2) -ne $eventArgs.GetPosition($this).X){
                    # Right
                    [System.Windows.Media.Media3D.Vector3D]$axis = New-Object System.Windows.Media.Media3D.Vector3D(0, -1, 0)
                    $Camera.Rotate($axis,$xfactor,$Camera.position())
                    $Camera3.Rotate($axis,$xfactor,$Camera.position())
                    $ball.RotateX(-$xfactor)
                }
                #Y
                if(((($mainWindow.window.ActualHeight / 2)-23) -gt $eventArgs.GetPosition($this).Y) -and (($mainWindow.window.ActualHeight / 2)-23) -ne $eventArgs.GetPosition($this).Y){
                    # Up
                    $Camera.ChangePitch($yfactor)
                    $ball.RotateY($yfactor)
                } 
                elseif(((($mainWindow.window.ActualHeight / 2)-23) -lt $eventArgs.GetPosition($this).Y) -and (($mainWindow.window.ActualHeight / 2)-23) -ne $eventArgs.GetPosition($this).Y){
                    # Down
                    $Camera.ChangePitch(-$yfactor)
                    $ball.RotateY(-$yfactor)
                }
            }

            $null = [W32API.Mouse]::SetCursorPos($CursorPositionX,$CursorPositionY)
        }
    })

    $MainViewPort.Add_MouseDown({
        Param ([Object] $sender, [MouseButtonEventArgs]$eventArgs)
        if($eventArgs.LeftButton){
            $mouse_position = $eventArgs.GetPosition($MainViewPort)
            Write-Warning $mouse_position
            [HitTestResult]$result = [VisualTreeHelper]::HitTest($MainViewPort, $mouse_position)
            [RayMeshGeometry3DHitTestResult]$mesh_result = $result -as [RayMeshGeometry3DHitTestResult]
            if($mesh_result -ne $null){
                Write-warning ($models[$mesh_result.ModelHit]).Name
                Write-Warning ($mesh_result)
                Write-Warning $mesh_result.DistanceToRayOrigin
                Write-Warning $mesh_result.PointHit.ToString()
                [MeshGeometry3D]$mesh = $mesh_result.MeshHit
                Write-Warning $mesh.positions[$mesh_result.VertexIndex1].toString()
                Write-Warning $mesh.positions[$mesh_result.VertexIndex2].toString()
                Write-Warning $mesh.positions[$mesh_result.VertexIndex3].toString()
            }
        }
    })


[Int32] $stepsMilliseconds = 10

[DispatcherTimer] $timer = New-Object DispatcherTimer -Property @{
    Interval = New-Object TimeSpan 0, 0, 0, 0, $stepsMilliseconds
}

#Function TimerTick([object]$sender, [EventArgs]$e){}
$timer.Tag = [SphereAction]::Nothing
$timer.add_Tick({
    if($timer -ne $null){
        $timer.Stop()
        $timer.Start()
    }
    
	if($Camera.MovingUpDirectionIsLocked -eq $true){
        $camera.Move($camera3.camera.LookDirection, +$camera.amount)
        $ball.Move("$($camera3.camera.LookDirection.X),$($camera3.camera.LookDirection.Y),$($camera3.camera.LookDirection.Z)", +$camera.amount)
        $camera3.Move($camera3.camera.LookDirection, +$camera.amount)
        [SphereAction] $action = $ball.Intersect($ball,$opponentball)
        Switch ($action){
            'Collision' {
                $opponentball.move("$($camera3.camera.LookDirection.X),$($camera3.camera.LookDirection.Y),$($camera3.camera.LookDirection.Z)", +$camera.amount)
            }
            Default{}
        }
        [SphereAction] $cubeaction = $ball.Intersect($ball,$cubeModel)
        Switch ($cubeaction){
            'Collision' {
                #Write-Warning "Hit with $($Models[$cubeModel].Name)"
                $inverseX = [double]$camera3.camera.LookDirection.X * -1
                $inverseY = [double]$camera3.camera.LookDirection.Y * -1
                $inverseZ = [double]$camera3.camera.LookDirection.Z * -1
                $camera.Move($camera3.camera.LookDirection, (-$camera.amount*2))
                $ball.Move("$inverseX,$inverseY,$inverseZ", (+$camera.amount*2))
                $camera3.Move($camera3.camera.LookDirection, (-$camera.amount*2))
            }
            Default{}
        }
    }
    elseif($Camera.MovingDownDirectionIsLocked -eq $true){
        $camera.Move($camera3.camera.LookDirection, -$camera.amount)
        $inverseX = [double]$camera3.camera.LookDirection.X * -1
        $inverseY = [double]$camera3.camera.LookDirection.Y * -1
        $inverseZ = [double]$camera3.camera.LookDirection.Z * -1
        $ball.Move("$inverseX,$inverseY,$inverseZ", (+$camera.amount*2))
        $camera3.Move($camera3.camera.LookDirection, (-$camera.amount*2))
        [SphereAction] $action = $ball.Intersect($ball,$opponentball)
        Switch ($action){
            'Collision' {
                $inverseX = [double]$camera3.camera.LookDirection.X * -1
                $inverseY = [double]$camera3.camera.LookDirection.Y * -1
                $inverseZ = [double]$camera3.camera.LookDirection.Z * -1
                $opponentball.move("$inverseX,$inverseY,$inverseZ", +$camera.amount)
            }
            Default{}
        }
        [SphereAction] $cubeaction = $ball.Intersect($ball,$cubeModel)
        Switch ($cubeaction){
            'Collision' {
                #Write-Warning "Hit with $($Models[$cubeModel].Name)"
                $camera.Move($camera3.camera.LookDirection, +$camera.amount)
                $ball.Move("$($camera3.camera.LookDirection.X),$($camera3.camera.LookDirection.Y),$($camera3.camera.LookDirection.Z)", +$camera.amount)
                $camera3.Move($camera3.camera.LookDirection, +$camera.amount)
            }
            Default{}
        }
    }
    if($Camera.jump -ne 0.34){
        [SphereAction] $velocity = $ball.Intersect($ball,$floorModel)
        Switch ($velocity){
            'Collision' {
                if(($ball.translateTransform.OffsetY - 0.1) -le ($ball.height + 0)){
                } else {
                    $ball.Jump("0,-0.01,0", (0.34/2))
                    $camera.Move("0,-0.01,0", (0.34/2))
                    $camera3.Move("0,-0.01,0", (0.34/2))
                }
            }
            Drop{
                $ball.Jump("0,-1.0,0", (0.34*2))
                $camera.Move("0,-1.0,0", (0.34*2))
                $camera3.Move("0,-1.0,0", (0.34*2))
            }
            Default{
                if(-not ($cubeaction -eq 'Collision')){
                $ball.Jump("0,-0.1,0", (0.34/2))
                $camera.Move("0,-0.1,0", (0.34/2))
                $camera3.Move("0,-0.1,0", (0.34/2))
                }
            }
        }    
    }
    if($Camera.jump -eq 0.34){
        $ball.Jump("0,1.0,0", $camera.jump)
        $camera.Move("0,1.0,0", $camera.jump)
        $camera3.Move("0,1.0,0", $camera.jump)
        $camera.jump = 0.0
    }    
    if($Camera.crouch -eq 0.34){
        $ball.Crouch("0,-0.1,0", $camera.Crouch)
        $camera.Crouch = 0.0
    }
    # Get user ball origin and try to move opponent ball there
    # tähän tarvii rakentaa jotain millä hiffaa minne päin pitäisi mennä
    [SphereAction] $action = $opponentball.Intersect($opponentball,$ball)
    Switch ($action){
        'Collision' {
            $opponentball.move("$($camera3.camera.LookDirection.X),$($camera3.camera.LookDirection.Y),$($camera3.camera.LookDirection.Z)", +($Camera.amount * 0.1))
        }
        Default{
            [double]$xfactor = 5
            [System.Windows.Media.Media3D.Vector3D]$axis = New-Object System.Windows.Media.Media3D.Vector3D(0, 1, 0)
            $opponentball.RotateX($xfactor)
            $opponentball.move("$($ball.GetBoundsOrigin().X,0.0,$ball.GetBoundsOrigin().Z)", +($Camera.amount * 0.1))
        }
    }    
    [SphereAction] $cubeaction2 = $ball.Intersect($opponentball,$cubeModel)
    Switch ($cubeaction2){
        'Collision' {
            $opponentball.move("$($camera3.camera.LookDirection.X),$($camera3.camera.LookDirection.Y),$($camera3.camera.LookDirection.Z)", +($Camera.amount * 0.1))
        }
        Default{
            [double]$xfactor = 5
            [System.Windows.Media.Media3D.Vector3D]$axis = New-Object System.Windows.Media.Media3D.Vector3D(0, 1, 0)
            $opponentball.RotateX($xfactor)
            $opponentball.move("$($ball.GetBoundsOrigin().X,0.0,$ball.GetBoundsOrigin().Z)", +($Camera.amount * 0.1))
        }
    }
    [SphereAction] $velocity2 = $opponentball.Intersect($opponentball,$floorModel)
    Switch ($velocity2){
        'Collision' {
            if(($opponentball.translateTransform.OffsetY - 0.1) -le ($opponentball.height + 0)){
            } else {
                $opponentball.Jump("0,-0.01,0", (0.34/2))
            }
        }
        Drop{
            $opponentball.Jump("0,-1.0,0", (0.34*2))
        }
        Default{
            $opponentball.Jump("0,-0.1,0", (0.34/2))
        }
    }
})


# Changed the way how to read button inputs.
$window.Add_KeyDown({
    Param ([Object] $sender, [System.Windows.Input.KeyEventArgs]$eventArgs)
        if(-Not $disablekeys){
            Switch ($eventArgs.key){
                'up'{
                    $Camera.MovingUpDirectionIsLocked = $true
                    if($Camera.MovingDownDirectionIsLocked -eq $true){
                        [double]$camera.amount = 0.00
                        $Camera.MovingDownDirectionIsLocked = $false
                        $Camera.MovingUpDirectionIsLocked = $true
                        $timer.Stop()
                        Break;
                    }
                    elseif($camera.amount -le 0.34) {
                        [double]$camera.amount = ([double]$camera.amount + 0.02)
                        [double]$Camera.amount *= $Camera.Scale
                        $Camera.MovingDownDirectionIsLocked = $false
                        $Camera.MovingUpDirectionIsLocked = $true
                        $timer.Start()
                        Break;
                    }
                }
                'Down'{
                    $Camera.MovingDownDirectionIsLocked = $true
                    if($Camera.MovingUpDirectionIsLocked -eq $true){
                        [double]$camera.amount = 0.00
                        $Camera.MovingUpDirectionIsLocked = $false
                        $Camera.MovingDownDirectionIsLocked = $true
                        $timer.Stop()
                        Break;
                    }
                    elseif($camera.amount -le 0.34) {
                        [double]$camera.amount = ([double]$camera.amount + 0.02)
                        [double]$Camera.amount *= $Camera.Scale
                        $Camera.MovingUpDirectionIsLocked = $false
                        $Camera.MovingDownDirectionIsLocked = $true
                        $timer.Start()
                        Break;
                    }
                }
                'Left'{
                    $xfactor = 5
                    [System.Windows.Media.Media3D.Vector3D]$axis = New-Object System.Windows.Media.Media3D.Vector3D(0, 1, 0)
                    $direction = "Left"
                    $Camera.Rotate($axis,$xfactor,$Camera.position())
                    $Camera3.Rotate($axis,$xfactor,$Camera.position())
                    $ball.RotateX($xfactor)
                    Break;
                }
                'Right'{
                    $xfactor = 5
                    [System.Windows.Media.Media3D.Vector3D]$axis = New-Object System.Windows.Media.Media3D.Vector3D(0, -1, 0)
                    $direction = "Right"
                    $Camera.Rotate($axis,$xfactor,$Camera.position())
                    $Camera3.Rotate($axis,$xfactor,$Camera.position())
                    $ball.RotateX(-$xfactor)
                    Break;
                }
                'space'{
                    [double]$camera.jump = 0.34
                    Break;
                }
            }
        }
        Switch ($eventArgs.key){
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
                [double]$yfactor = 5
                $Camera.ChangePitch($yfactor)
                $ball.RotateY($yfactor)
                Break;
            }
            'g'{
                [double]$yfactor = 5
                $Camera.ChangePitch(-$yfactor)
                $ball.RotateY(-$yfactor)
                Break;
            }
            'c'{
                [double]$camera.crouch = 0.34
                Break;
            }
            'D1'{
                $MainViewPort.camera = $camera2.camera
                $MainViewPort.tag = "Camera2"
                Break;
            }
            'D2'{
                $MainViewPort.camera = $camera.camera
                $MainViewPort.tag = "Camera"
                Break;
            }
            'D3'{
                $MainViewPort.camera = $camera3.camera
                $MainViewPort.tag = "Camera3"
                Break;
            }
        }
})


$mainWindow.window.ShowDialog() | Out-Null

Cleanup-Variables


