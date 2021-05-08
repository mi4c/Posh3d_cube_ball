Class MyStoryboard{
    [double]$turnDuration = 0.7;
    [double]$totalDuration = 0.0;
    [double]$walkDuration = 0.4;
    [double]$x
    [double]$y
    [double]$z
    [System.Windows.Media.Animation.DoubleAnimation]$doubleAnimationX1
    [System.Windows.Media.Animation.DoubleAnimation]$doubleAnimationY1
    [System.Windows.Media.Animation.DoubleAnimation]$doubleAnimationZ1
    [System.Windows.Media.Animation.StoryBoard]$storyboard

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

    Move($object,$Key,$transformgroup){
        [System.Windows.Media.Animation.StoryBoard]$this.storyboard = [System.Windows.Media.Animation.StoryBoard]::new()
        Switch($Key){
            'up'{
                $This.x = 0.1
                $This.y = 1.5
                $This.z = 0.0
                Break;
            }
            'Down'{
                $This.x = -0.1
                $This.y = -1.5
                $This.z = 0.0
                Break;
            }
            'Left'{
                $This.x = 0.0
                $This.y = 1.5
                $This.z = -0.1
                Break;
            }
            'Right'{
                $This.x = 0.0
                $This.y = -1.5
                $This.z = 0.1
                Break;
            }
            'space'{
                $This.x = 0.0
                $This.y = 0.5
                $This.z = 0.0
                Break;
            }
        }
    $this.doubleAnimationX1 = New-Object System.Windows.Media.Animation.DoubleAnimation(0, $this.x, ($this.durationTS($this.walkDuration)))
    $this.doubleAnimationY1 = New-Object System.Windows.Media.Animation.DoubleAnimation(0, $this.y, ($this.durationTS($this.walkDuration)))
    $this.doubleAnimationZ1 = New-Object System.Windows.Media.Animation.DoubleAnimation(0, $this.z, ($this.durationTS($this.walkDuration)))
    $this.storyboard::SetTargetName($this.doubleAnimationX1,"MoveTransform")
    $this.storyboard::SetTargetName($this.doubleAnimationY1,"MoveTransform")
    $this.storyboard::SetTargetName($this.doubleAnimationZ1,"MoveTransform")
    $this.storyboard::SetTargetProperty($this.doubleAnimationX1, (New-Object System.Windows.PropertyPath([System.Windows.Media.Media3D.TranslateTransform3D]::OffsetXProperty)))
    $this.storyboard::SetTargetProperty($this.doubleAnimationY1, (New-Object System.Windows.PropertyPath([System.Windows.Media.Media3D.TranslateTransform3D]::OffsetYProperty)))
    $this.storyboard::SetTargetProperty($this.doubleAnimationZ1, (New-Object System.Windows.PropertyPath([System.Windows.Media.Media3D.TranslateTransform3D]::OffsetZProperty)))
    $this.storyboard.Children.Add($this.doubleAnimationX1)
    $this.storyboard.Children.Add($this.doubleAnimationY1)
    $this.storyboard.Children.Add($this.doubleAnimationZ1)
    $this.doubleAnimationX1.BeginTime = ($this.durationTS($this.totalDuration))
    $this.doubleAnimationY1.BeginTime = ($this.durationTS($this.totalDuration))
    $this.doubleAnimationZ1.BeginTime = ($this.durationTS($this.totalDuration))
    $this.Totalduration += $this.walkDuration
    $this.Storyboard.RepeatBehavior = "1x"
    $this.storyboard.Duration = ($this.durationTS($this.totalDuration))
    #$this.storyboard.completed += $this.DoubleAnimation_Completed($object, $transformGroup)
    #$object.SphereModelGroup.Transform = ($transformGroup)
    }

    StopMoving($object, $transformGroup){
        $moveTransform = New-Object System.Windows.Media.Media3D.TranslateTransform3D("$($this.x),$($this.y),$($this.z)")
        $transformGroup.Children.Add($moveTransform)
        $object.SphereModelGroup.Transform = ($transformGroup)
    }
}

