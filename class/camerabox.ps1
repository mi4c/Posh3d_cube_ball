class CameraBox : System.ComponentModel.INotifyPropertyChanged{
    [int]$speed
    [double]$amount
    [Double]$scale = 1
	[int]$lookBackAngle
	[bool]$turnToTarget
    [Double]$FlyCameraPhi = [Math]::PI / 8.0   # 30 degrees
    [Double]$FlyCameraTheta = [Math]::PI / 8.0 # 30 degrees
    [Double]$FlyCameraR = 30.0
    [Bool]$outofscope
	[System.Windows.Media.Media3D.Vector3D]$targetUp
    [System.Windows.Media.Media3D.Vector3D]$targetLook
    Hidden [System.ComponentModel.PropertyChangedEventHandler] $PropertyChanged
    [System.Windows.Media.Media3D.Vector3D]$MovingDirection
    [System.Windows.Media.Media3D.PerspectiveCamera]$Camera = (New-Object System.Windows.Media.Media3D.PerspectiveCamera);
    [Bool]$MovingUpDirectionIsLocked
    [Bool]$MovingDownDirectionIsLocked
    [String]$Stopmoving
    [System.Windows.Media.Media3D.RotateTransform3D]$rotateTransform

    
    [Void] add_PropertyChanged([System.ComponentModel.PropertyChangedEventHandler] $propertyChanged) {
        $this.PropertyChanged = [Delegate]::Combine($this.PropertyChanged, $propertyChanged)
    }

    [Void] remove_PropertyChanged([System.ComponentModel.PropertyChangedEventHandler] $propertyChanged) {
        $this.PropertyChanged = [Delegate]::Remove($this.PropertyChanged, $propertyChanged)
    }

    [Void] TriggerPropertyChanged([String]$propertyname){
        if($this.PropertyChanged -ne $null){
            $this.PropertyChanged.Invoke($this, (New-Object PropertyChangedEventArgs $propertyName))
        }
    }

    [void] PositionFlyCamera([Double]$degrees,[Double]$value, $direction){
        Switch($direction){
            "up"{
                $this.FlyCameraPhi = $degrees + $value
                if($this.FlyCameraPhi -gt ([Math]::PI / 2.0) -and -not($this.FlyCameraPhi -lt (-[Math]::PI / 2.0))){
                    if($this.FlyCameraPhi -gt (3*[Math]::PI / 2.0) -and -not($this.FlyCameraPhi -lt (3*-[Math]::PI / 2.0) )){
                        # starting point was 1/4, so we need to reset camera after we pass 3/4 of the round
                        $this.FlyCameraPhi = (-[Math]::PI / 2.0)
                        # Set positive angle marker
                        $this.outofScope = $False
                        Break;
                    }
                    # Set negative angle marker
                    $this.outofScope = $true
                }
                elseif($this.FlyCameraPhi -lt (-[Math]::PI / 2.0) -and -not($this.FlyCameraPhi -gt ([Math]::PI / 2.0))){
                    # starting point was 1/4, so we need to reset camera after we pass negative 3/4 of the round
                    if($this.FlyCameraPhi -lt (3*-[Math]::PI / 2.0) -and -not($this.FlyCameraPhi -gt (3*[Math]::PI / 2.0))){
                        $this.FlyCameraPhi = ([Math]::PI / 2.0)
                        $this.outofScope = $False
                        Break;
                    }
                    $this.outofScope = $true
                } else {
                    # Set positive angle marker
                    $this.outofScope = $false
                }
                Break;
            }
            "down"{
                $this.FlyCameraPhi = $degrees + -$value
                if($this.FlyCameraPhi -lt (-[Math]::PI / 2.0) -and -not($this.FlyCameraPhi -gt ([Math]::PI / 2.0))){
                    # starting point was 1/4, so we need to reset camera after we pass negative 3/4 of the round
                    if($this.FlyCameraPhi -lt (3*-[Math]::PI / 2.0) -and -not($this.FlyCameraPhi -gt (3*[Math]::PI / 2.0))){
                        $this.FlyCameraPhi = ([Math]::PI / 2.0)
                        $this.outofScope = $False
                        Break;
                    }
                    $this.outofScope = $true
                }
                elseif($this.FlyCameraPhi -gt ([Math]::PI / 2.0) -and -not($this.FlyCameraPhi -lt (-[Math]::PI / 2.0))){
                    if($this.CameraPhi -gt (3*[Math]::PI / 2.0) -and -not($this.CameraPhi -lt (3*-[Math]::PI / 2.0) )){
                        # starting point was 1/4, so we need to reset camera after we pass 3/4 of the round
                        $this.FlyCameraPhi = (-[Math]::PI / 2.0)
                        # Set positive angle marker
                        $this.outofScope = $False
                        Break;
                    }
                    # Set negative angle marker
                    $this.outofScope = $true
                } else {
                    # Set positive angle marker
                    $this.outofScope = $false
                }
                Break;
            }
            "left"{
                $this.FlyCameraTheta = $degrees + $value;
                if($this.FlyCameraPhi -gt ([Math]::PI / 2.0) -and -not($this.FlyCameraPhi -lt (-[Math]::PI / 2.0))){
                    if($this.FlyCameraPhi -gt (3*[Math]::PI / 2.0) -and -not($this.FlyCameraPhi -lt (3*-[Math]::PI / 2.0) )){
                        # starting point was 1/4, so we need to reset camera after we pass 3/4 of the round
                        $this.FlyCameraPhi = (-[Math]::PI / 2.0)
                        # Set positive angle marker
                        $this.outofScope = $False
                        Break;
                    }
                    # Set negative angle marker
                    $this.outofScope = $true
                }
                elseif($this.FlyCameraPhi -lt (-[Math]::PI / 2.0) -and -not($this.FlyCameraPhi -gt ([Math]::PI / 2.0))){
                    # starting point was 1/4, so we need to reset camera after we pass negative 3/4 of the round
                    if($this.FlyCameraPhi -lt (3*-[Math]::PI / 2.0) -and -not($this.FlyCameraPhi -gt (3*[Math]::PI / 2.0))){
                        $this.FlyCameraPhi = ([Math]::PI / 2.0)
                        $this.outofScope = $False
                        Break;
                    }
                    $this.outofScope = $true
                } else {
                    # Set positive angle marker
                    $this.outofScope = $false
                }
                break;
            }
            "Right"{
                $this.FlyCameraTheta = $degrees - $value;
                if($this.FlyCameraPhi -gt ([Math]::PI / 2.0) -and -not($this.FlyCameraPhi -lt (-[Math]::PI / 2.0))){
                    if($this.FlyCameraPhi -gt (3*[Math]::PI / 2.0) -and -not($this.FlyCameraPhi -lt (3*-[Math]::PI / 2.0) )){
                        # starting point was 1/4, so we need to reset camera after we pass 3/4 of the round
                        $this.FlyCameraPhi = (-[Math]::PI / 2.0)
                        # Set positive angle marker
                        $this.outofScope = $False
                        Break;
                    }
                    # Set negative angle marker
                    $this.outofScope = $true
                }
                elseif($this.FlyCameraPhi -lt (-[Math]::PI / 2.0) -and -not($this.FlyCameraPhi -gt ([Math]::PI / 2.0))){
                    # starting point was 1/4, so we need to reset camera after we pass negative 3/4 of the round
                    if($this.FlyCameraPhi -lt (3*-[Math]::PI / 2.0) -and -not($this.FlyCameraPhi -gt (3*[Math]::PI / 2.0))){
                        $this.FlyCameraPhi = ([Math]::PI / 2.0)
                        $this.outofScope = $False
                        Break;
                    }
                    $this.outofScope = $true
                } else {
                    # Set positive angle marker
                    $this.outofScope = $false
                }
                Break;
            }
            "zoomin"{
                $this.FlyCameraR -= $value;
                if ($this.FlyCameraR -lt $value){
                    $this.FlyCameraR = $this.FlyCameraR - $value;
                }
                if($this.FlyCameraPhi -gt ([Math]::PI / 2.0) -and -not($this.FlyCameraPhi -lt (-[Math]::PI / 2.0))){
                    if($this.FlyCameraPhi -gt (3*[Math]::PI / 2.0) -and -not($this.FlyCameraPhi -lt (3*-[Math]::PI / 2.0) )){
                        # starting point was 1/4, so we need to reset camera after we pass 3/4 of the round
                        $this.FlyCameraPhi = (-[Math]::PI / 2.0)
                        # Set positive angle marker
                        $this.outofScope = $False
                        Break;
                    }
                    # Set negative angle marker
                    $this.outofScope = $true
                }
                elseif($this.FlyCameraPhi -lt (-[Math]::PI / 2.0) -and -not($this.FlyCameraPhi -gt ([Math]::PI / 2.0))){
                    # starting point was 1/4, so we need to reset camera after we pass negative 3/4 of the round
                    if($this.FlyCameraPhi -lt (3*-[Math]::PI / 2.0) -and -not($this.FlyCameraPhi -gt (3*[Math]::PI / 2.0))){
                        $this.FlyCameraPhi = ([Math]::PI / 2.0)
                        $this.outofScope = $False
                        Break;
                    }
                    $this.outofScope = $true
                } else {
                    # Set positive angle marker
                    $this.outofScope = $false
                }
                Break;
            }
            "zoomout"{
                $this.FlyCameraR = $this.FlyCameraR + $value;
                if($this.FlyCameraPhi -gt ([Math]::PI / 2.0) -and -not($this.FlyCameraPhi -lt (-[Math]::PI / 2.0))){
                    if($this.FlyCameraPhi -gt (3*[Math]::PI / 2.0) -and -not($this.FlyCameraPhi -lt (3*-[Math]::PI / 2.0) )){
                        # starting point was 1/4, so we need to reset camera after we pass 3/4 of the round
                        $this.FlyCameraPhi = (-[Math]::PI / 2.0)
                        # Set positive angle marker
                        $this.outofScope = $False
                        Break;
                    }
                    # Set negative angle marker
                    $this.outofScope = $true
                }
                elseif($this.FlyCameraPhi -lt (-[Math]::PI / 2.0) -and -not($this.FlyCameraPhi -gt ([Math]::PI / 2.0))){
                    # starting point was 1/4, so we need to reset camera after we pass negative 3/4 of the round
                    if($this.FlyCameraPhi -lt (3*-[Math]::PI / 2.0) -and -not($this.FlyCameraPhi -gt (3*[Math]::PI / 2.0))){
                        $this.FlyCameraPhi = ([Math]::PI / 2.0)
                        $this.outofScope = $False
                        Break;
                    }
                    $this.outofScope = $true
                } else {
                    # Set positive angle marker
                    $this.outofScope = $false
                }
                Break;
            }
        }
        [Double]$y = $this.FlyCameraR * [Math]::Sin($this.FlyCameraPhi)
        [Double]$hyp = $this.FlyCameraR * [Math]::Cos($this.FlyCameraPhi)
        [Double]$x = $hyp * [Math]::Cos($this.FlyCameraTheta)
        [Double]$z = $hyp * [Math]::Sin($this.FlyCameraTheta)
        if(-not $this.camera.position){
            $this.camera.position = New-Object System.Windows.Media.Media3D.Point3D($x,$y,$z)
        } else {
            $this.camera.position = "$x,$y,$z"
        }
        if(-not $this.camera.lookdirection){
            $x = $x * -1
            $y = $y * -1
            $z = $z * -1
            $this.camera.lookdirection = New-Object System.Windows.Media.Media3D.Vector3D($x,$y,$z)
        } else {
            $x = $x * -1
            $y = $y * -1
            $z = $z * -1
            $this.camera.lookdirection = "$x,$y,$z"
        }
        $this.camera.Position = $this.camera.position
        # The point of camera looks at
        $this.camera.LookDirection = $this.camera.lookdirection
        if(-not $this.outofScope){
            # Vertical axis of camera with Horizontal axis
            $this.camera.UpDirection = "0,1,0"
        }
        elseif($this.outofScope){
            # Reverse Vertical axis of camera with Horizontal axis
            $this.camera.UpDirection = "0,-1,0"
        }
    }

    [System.Windows.Media.Media3D.Point3D]Position(){
        Return $this.Camera.Position
    }
    [System.Windows.Media.Media3D.Point3D]Position($value){
        Return ($this.Camera.Position = $value)
    }

    [System.Windows.Media.Media3D.Vector3D]LookDirection(){
        Return $this.Camera.LookDirection
    }

	[void]MouseRotateX([System.Windows.Media.Media3D.Vector3D]$axis, [double]$angle){
        [System.Windows.Media.Media3D.Transform3DGroup]$group = New-Object System.Windows.Media.Media3D.Transform3DGroup
        $rotation = New-Object System.Windows.Media.Media3D.AxisAngleRotation3D($axis, $angle);
        $this.rotateTransform = New-Object System.Windows.Media.Media3D.RotateTransform3D($($rotation), ($this.Camera.Position));
        #Write-Warning ($this.camera | ConvertTo-Json)
        #$this.camera.transform = $this.rotateTransform
        $group.Children.Add($this.camera.transform)
        $group.Children.Add($this.rotateTransform)
        $this.camera.transform = $group
	}

	[void]MouseRotateY([System.Windows.Media.Media3D.Vector3D]$axis, [double]$angle){
        [System.Windows.Media.Media3D.Transform3DGroup]$group = New-Object System.Windows.Media.Media3D.Transform3DGroup
        $rotation = New-Object System.Windows.Media.Media3D.AxisAngleRotation3D(($axis), $angle);
        [System.Windows.Media.Media3D.Quaternion]$q = New-Object System.Windows.Media.Media3D.Quaternion(($axis), $angle)
        $test = [Math3D]::Transform($q,$axis)
        
        $this.rotateTransform = New-Object System.Windows.Media.Media3D.RotateTransform3D($($rotation), ($this.Camera.Position));
        #$this.rotateTransform = New-Object System.Windows.Media.Media3D.RotateTransform3D($($rotation), ($test));
        #Write-Warning ($this.camera | ConvertTo-Json)
        #$this.camera.transform = $this.rotateTransform
        $group.Children.Add($this.camera.transform)
        $group.Children.Add($this.rotateTransform)
        $this.camera.transform = $group
	}

    [System.Windows.Media.Media3D.Vector3D]LookDirection([System.Windows.Media.Media3D.Vector3D]$value){
        if($this.MovingDirectionIsLocked){
            Return $null
        }else{
            Return ([System.Windows.Media.Media3D.Vector3D]$this.camera.LookDirection = ($value))
        }
    }

    [System.Windows.Media.Media3D.Vector3D]UpDirection(){
        Return $this.Camera.UpDirection
    }

    [Double]FieldOfView(){
        Return $this.Camera.FieldOfView
    }

    [Double]FieldOfView($value){
        Return ($this.Camera.FieldOfView = [MathUtils]::Clamp($value, 1, 170))
    }

    [System.Windows.Media.Media3D.Vector3D]LeftDirection(){
        Return [System.Windows.Media.Media3D.Vector3D]::CrossProduct($this.Camera.UpDirection,($this.Camera.LookDirection))
    }
    [System.Windows.Media.Media3D.Vector3D]RightDirection(){
        Return [System.Windows.Media.Media3D.Vector3D]::CrossProduct($this.Camera.LookDirection,($this.Camera.UpDirection))
    }

    [Double]RollAngle(){
        Return ([CameraBox]::Cut($this.LeftDirection.AngleTo([Math3D]::UnitZ) - 90))
    }

    [Double]PitchAngle(){
        Return ([CameraBox]::Cut($this.LookDirection.Angle([Math3D]::UnitZ) - 90))
    }

	[int]Speed(){
		Return $this.speed
	}
	[int]Speed($value){
        if($this.speed -ne $value){
            $this.speed = $value
            [Camerabox]::TriggerPropertyChanged($this.speed)
            Return $this.speed
        } else {
            Return $null
        }
    }

	[void]ChangeYaw([double]$angle)
	{
		$this.Rotate($this.camera.UpDirection, $angle);
	}

	[void]ChangeRoll([double]$angle)
	{
        $this.Rotate($this.camera.LookDirection, $angle)
		$this.camera.UpDirection = $this.camera.UpDirection;
	}

	[void]ChangePitch([double]$angle)
	{
		[System.Windows.Media.Media3D.Quaternion]$q = [Math3D]::Rotation($this.LeftDirection(), $angle);
		$this.camera.UpDirection = [Math3D]::Transform($q,$this.camera.UpDirection);
		$this.camera.LookDirection = [Math3D]::Transform($q,$this.camera.LookDirection);
	}

	[void]ChangeHeading([double]$angle)
	{
		[System.Windows.Media.Media3D.Quaternion]$q = [Math3D]::RotationZ($angle);
		$this.camera.UpDirection = $q.Transform($this.camera.UpDirection);
		$this.camera.LookDirection = $q.Transform($this.camera.LookDirection);
	}

	[void]Move([System.Windows.Media.Media3D.Vector3D]$direction, [double]$amount){
		$this.camera.Position += ($direction * $amount);
	}

	[void]Rotate([System.Windows.Media.Media3D.Vector3D]$axis, [double]$angle){
		[System.Windows.Media.Media3D.Quaternion]$q = ([Math3D]::Rotation($axis, $angle));
        # this would be needed to add roll behaviour, but it mess the origin as this rotate is planned for a moving air plane
		#$this.camera.Position = [Math3D]::Transform($q,$this.camera.Position);

        # this would be needed to add roll behaviour, but it mess the origin as this rotate is planned for a moving air plane
		#$this.camera.UpDirection = [Math3D]::Transform($q,$this.camera.UpDirection);
		$this.camera.LookDirection = [Math3D]::Transform($q,$this.camera.LookDirection);        
	}

	[void]Rotate([System.Windows.Media.Media3D.Vector3D]$axis, [double]$angle, [System.Windows.Media.Media3D.Point3D]$center){

		$this.camera.Position = $this.camera.Position.Subtract($center);
		$this.camera.Rotate($axis, $angle);
		$this.camera.Position = $this.camera.Position.Add($center);
	}

	[void]LookBack(){
		if ($this.lookBackAngle -ne 0){
			return;
        }

		if ($this.Speed -eq 0){
			[camerabox]::ChangeYaw(180);
        } else {
			$this.lookBackAngle = 1;
        }
	}

	[void]LookAtOrigin()
	{
		$this.LookAt([Math3D]::Origin);
	}

	[void]LookAt([System.Windows.Media.Media3D.Point3D]$targetPoint){
		[Math3D]::LookAt($targetPoint, $this.camera.Position, $this.targetLook, $this.targetUp);
		if ($this.Speed -eq 0){
			$this.camera.UpDirection = $this.targetUp;
			$this.camera.LookDirection = $this.targetLook;
		} else {
			$this.turnToTarget = $true;
		}
	}

	[void]FlyParallel([int]$mode = 0){
		if ($this.speed -eq 0){
			return;
        }

		$this.targetLook = $this.LookDirection;
		$this.targetLook.Z = 0;
		$this.targetLook.Normalize();
		$this.targetUp = [Math3D]::UnitZ;

		if ($mode -ne 0){
			$this.targetUp = $this.targetUp.Rotate($this.targetLook, $mode * 15);
        }

		if ($this.speed -eq 0 -or $mode -ne 0){
			$this.camera.UpDirection = $this.targetUp;
			$this.camera.LookDirection = $this.targetLook;
		} else {
			$this.turnToTarget = $true;
		}
	}

	[void]StopAnyTurn(){
		$this.turnToTarget = $false;
	}

	[void]Update(){
		if ($this.Speed -eq 0){
			return;
        }

		if ($this.turnToTarget){
			$this.TurnToTarget();
        }

		if ($this.lookBackAngle -ne 0){
			$this.ChangeYaw(6);
			if (($this.lookBackAngle += 6) > 180){
				$this.lookBackAngle = 0;
            }
		} else {
			[double]$factor = [Math]::Log10([Math]::Abs($this.Speed) + 1);			
            # this might be the fix for the rotate roll angle origin mess, investigate it in future...
            #[double]$angle = [MathUtils]::ToRadians($this.RollAngle);
			#$this.ChangeHeading($factor * [Math]::Sin($angle)); # makes 15 degrees per second at speed 9 and roll angle 30
			$this.Move($this.MovingDirection, $this.Speed * $this.Scale / 300.0); # makes 1 world unit per second at speed 10 and scale 1
		}
	}

	[double]Cut([double]$angleInDegrees){
        if([Math]::Abs($angleInDegrees) -lt 0.5){
            Return 0
        } else {
            Return $angleInDegrees
        }
	}

	[void]TurnToTarget(){
		[double]$len1 = ($this.camera.UpDirection - $this.targetUp).LengthSquared;
		[double]$len2 = ($this.camera.LookDirection - $this.targetLook).LengthSquared;
		[double]$eps = 3e-5;

		if ($len1 -gt $eps -or $len2 -gt $eps){
			$eps = 3e-2;
			$this.camera.UpDirection = [Math3D]::Lerp($this.camera.UpDirection, $this.targetUp, $eps);
			$this.camera.LookDirection = [Math3D]::Lerp($this.camera.LookDirection, $this.targetLook, $eps);
		} else {
			$this.camera.UpDirection = $this.targetUp;
			$this.camera.LookDirection = $this.targetLook;
			$this.turnToTarget = $false;
		}
	}
}
