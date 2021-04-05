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
 How to create 3D surface 
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
Using Namespace System.Windows.Input
[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
<#
    .SYNOPSIS
    Shows 3D surface
    .DESCRIPTION
    How to draw 3D surface with powershell
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

. .\class\WpfTriangle.ps1
. .\class\WpfRectangle.ps1
. .\class\WpfCube.ps1
. .\class\WpfCylinder.ps1
. .\class\WpfSphere.ps1

[system.windows.Window] $mainWindow = [System.Windows.Markup.XamlReader]::Parse(@'
    <Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="howto_do_3d"
    Height="500" Width="500">
    <Grid>
        <Viewport3D Grid.Row="0" Grid.Column="0"
            Name="MainViewport" />
    </Grid>
    </Window>
'@)


$MainModel3Dgroup = New-Object System.Windows.Media.Media3D.Model3DGroup

Function Camera{
    [System.Windows.Media.Media3D.PerspectiveCamera]$perspectiveCamera = New-Object System.Windows.Media.Media3D.PerspectiveCamera
    $perspectiveCamera.Position = [System.Windows.Media.Media3D.Point3D]::new(-[Scene]::scenesize, [Scene]::scenesize / 2, [Scene]::scenesize);
    $perspectiveCamera.LookDirection = [System.Windows.Media.Media3D.Vector3D]::new($lookat.X - $perspectiveCamera.Position.X,
                                                    $lookat.Y - $perspectiveCamera.Position.Y,
                                                    $lookat.Z - $perspectiveCamera.Position.Z);
    $perspectiveCamera.FieldOfView = 60;
    return $perspectiveCamera;
}

Function positionLight
{
    Param(
    [System.Windows.Media.Media3D.Point3D]$position
    )
    [System.Windows.Media.Media3D.DirectionalLight]$directionalLight = New-Object System.Windows.Media.Media3D.DirectionalLight
    $color = [System.Drawing.Color]::Gray
    $mediaColor = [System.Windows.Media.Color]::FromArgb($color.A, $color.R, $color.G, $color.B)
    $directionalLight.Color = $mediaColor
    $directionalLight.Direction = [System.Windows.Media.Media3D.Point3D]::new(0, 0, 0) - $position;
    return $directionalLight;
}

Class Scene{
    static [double]$scenesize = 20
}

$mainWindow.Add_Loaded({
    [double]$floorthickness = [scene]::scenesize / 100
    $mainWindow.Content.ShowGridLines = $false
    $mainWindow.Content.Background = 'Black'
    $MainViewPort = $mainWindow.FindName('MainViewport')
    # create a cube with dimensions as some fraction of the scene size
    [WpfCube]$cube = [WpfCube]::new($([System.Windows.Media.Media3D.Point3D]("0, 3, 0")), [scene]::scenesize / 6, [scene]::scenesize / 6, [scene]::scenesize / 6)
    # construct our geometry model from the cube object

    [System.Windows.Media.Media3D.GeometryModel3D]$cubeModel = $cube.CreateModel([System.Drawing.Color]::Aquamarine)
    [System.Windows.Media.Media3D.GeometryModel3D]$floorModel = [WpfCube]::CreateCubeModel("$(-([scene]::scenesize / 2),-($floorthickness),-([scene]::scenesize/2))",([scene]::scenesize),$floorthickness,[scene]::scenesize,[System.Drawing.Color]::Tan)
    # create a model group to hold our model
    [System.Windows.Media.Media3D.Model3DGroup]$groupScene = New-Object System.Windows.Media.Media3D.Model3DGroup
    $sphere = [Sphere]::New()
    $spheremodel = $sphere.CreateModel()
    #$spheremodel.Transform.position = New-Object System.Windows.Media.Media3d.Vector3D(0.0,0.6,9.2)
    # add our cube to the model group
    $groupScene.Children.Add($cubeModel)
    $groupScene.Children.Add($floorModel)
    $groupScene.Children.Add($spheremodel)
    # add a directional light
    $groupScene.Children.Add((positionLight -position ("$(-([scene]::scenesize), ([scene]::scenesize / 2), 0.0)")))
    # add ambient lighting
    $groupScene.Children.Add((new-object System.Windows.Media.Media3D.AmbientLight -property @{Color = 'Gray'}))
    # add a camera
    $MainViewport.camera = Camera
    # create a visual model that we can add to our viewport
    $visual = New-Object System.Windows.Media.Media3D.ModelVisual3D
    # populate the visual with the geometry model we made
    $visual.Content = $groupScene
    $MainViewport.Children.Add($visual)
    turnModel -center $cube.center() -model $cubeModel -beginAngle 0 -endAngle 360 -seconds 3 -forever $true
    turnModel -center "-9.2, 0.6, 9.2" -model $spheremodel -beginAngle 0 -endAngle 360 -seconds 3 -forever $true
    #Write-warning ($spheremodel | convertto-json)

})

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


function turnModel{
    Param(
        [System.Windows.Media.Media3D.Point3D]$center,
        [System.Windows.Media.Media3D.GeometryModel3D]$model,
        [double]$beginAngle,
        [double]$endAngle,
        [double]$seconds,
        [bool]$forever
    )

    # vectors serve as 2 axes to turn our model
    $vector = New-Object System.Windows.Media.Media3D.Vector3D(0, 1, 0);
    $vector2 = New-Object System.Windows.Media.Media3D.Vector3D(1, 0, 0);

    # create rotations to use.  we can set a 0.0 degrees for our rotations since we are going to animate them
    $rotation = New-Object System.Windows.Media.Media3D.AxisAngleRotation3D($vector, 0.0);
    $rotation2 = New-Object System.Windows.Media.Media3D.AxisAngleRotation3D($vector2, 0.0);

    # create double animations to animate each of our rotations
    $doubleAnimation = New-Object System.Windows.Media.Animation.DoubleAnimation($beginAngle, $endAngle, (durationTS($seconds)));
    $doubleAnimation2 = New-Object System.Windows.Media.Animation.DoubleAnimation($beginAngle, $endAngle, (durationTS($seconds)));

    # set the repeat behavior and duration for our animations
    if ($forever)
    {
        $doubleAnimation.RepeatBehavior = "Forever";
        $doubleAnimation2.RepeatBehavior = "Forever";
    }

    $doubleAnimation.BeginTime = durationTS(0.0);
    $doubleAnimation2.BeginTime = durationTS(0.0);

    # create 2 rotate transforms to apply to our model.  each needs a rotation and a center point
    $rotateTransform = New-Object System.Windows.Media.Media3D.RotateTransform3D($($rotation), "$($center)");
    $rotateTransform2 = New-Object System.Windows.Media.Media3D.RotateTransform3D($($rotation2), "$($center)");

    # create a transform group to hold our 2 transforms
    $transformGroup = New-Object System.Windows.Media.Media3D.Transform3DGroup;
    $transformGroup.Children.Add($rotateTransform);
    $transformGroup.Children.Add($rotateTransform2);

    # set our model transform to the transform group 
    $model.Transform = $transformGroup;

    # begin the animations -- specify a target object and property for each animation -- in this case,
    # the targets are the two rotations we created and we are animating the angle property for each one
    $rotation.BeginAnimation([System.Windows.Media.Media3D.AxisAngleRotation3D]::AngleProperty, $doubleAnimation);
    $rotation2.BeginAnimation([System.Windows.Media.Media3D.AxisAngleRotation3D]::AngleProperty, $doubleAnimation2);

}

$mainWindow.ShowDialog() | Out-Null
Cleanup-Variables


