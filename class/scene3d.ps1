class Lighting : System.Windows.Media.Media3D.ModelVisual3D
{
    [System.Windows.Media.Media3D.Model3DGroup]$lightingGroup = (new-object System.Windows.Media.Media3D.Model3DGroup)
	[System.Windows.Media.Media3D.AmbientLight]$ambientLight = (New-Object System.Windows.Media.Media3D.AmbientLight([System.Windows.Media.Colors]::White))
	[System.Windows.Media.Media3D.DirectionalLight]$directionalLight1 = (New-Object System.Windows.Media.Media3D.DirectionalLight([System.Windows.Media.Colors]::White, (New-Object System.Windows.Media.Media3D.Vector3D(23, 28, -15))))
	[System.Windows.Media.Media3D.DirectionalLight]$directionalLight2 = (new-Object System.Windows.Media.Media3D.DirectionalLight([System.Windows.Media.Colors]::White, (new-Object System.Windows.Media.Media3D.Vector3D(-23, -28, -15))))
#	[ADI]$adi;
#	[Airplane[]]$airplanes;
	[System.Collections.Generic.List[CameraBox]]$Cameras = (New-Object [System.Collections.Generic.List[(New-Object CameraBox)]);
	[System.Windows.Media.Media3D.Point3D]$touchPoint = ([Math3D]::Origin);
	[System.Windows.Point]$prevPosition = (New-Object System.Windows.Point([double]::NaN, 0))
	[System.ComponentModel.PropertyChangedEventHandler]$PropertyChanged;

    Lighting(){
		$Content = $this.lightingGroup;
		$this.lightingGroup.Children.Add($this.ambientLight);
		$this.lightingGroup.Children.Add($this.directionalLight1);
		$this.lightingGroup.Children.Add($this.directionalLight2);
	}

	[System.Windows.Media.Media3D.Model3DGroup]LightingGroup()
	{
		return $this.lightingGroup
	}
	
    [System.Windows.Media.Media3D.AmbientLight]AmbientLight(){
		return $this.ambientLight
	}

	[System.Windows.Media.Media3D.DirectionalLight]DirectionalLight1(){
		return $this.directionalLight1;
	}

	[System.Windows.Media.Media3D.DirectionalLight]DirectionalLight2(){
		return $this.directionalLight2;
	}
}


class Scene3D : System.ComponentModel.INotifyPropertyChanged{
	[System.Windows.Threading.DispatcherTimer]$timer
    [System.Windows.Controls.Viewport3D]$Viewport
	[bool]$isInteractive
	[System.EventHandler]$TimerTicked
    Scene3D()
	{
		$IsCached = $true;
		$Focusable = $true;
		$this.IsInteractive = $true;
		$Background = $this.Brushes.Black;

		$ModelsContainer = New-Object System.Windows.Media.Media3D.Object3D;
		$Models = $this.ModelsContainer.Children;
		$Lighting = New-Object System.Windows.Media.Media3D.Lighting;

		$Child = $this.Viewport = New-Object System.Windows.Media.Media3D.Viewport3D;
		$this.Viewport.Children.Add($ModelsContainer);
		$this.Viewport.Children.Add($Lighting);

		$this.AddCamera(-5, -4, 6);
		$this.AddCamera(+5, -4, 6);
		$this.AddCamera(10, 10, 9);
		$this.ActivateCamera(0);

		#//--- timer is required for flight simulation
		$this.timer = New-Object System.Windows.Threading.DispatcherTimer([System.Windows.Threading.DispatcherPriority]::Render);
		$this.timer.Interval = [System.TimeSpan]::FromMilliseconds(30);
		$this.timer.Tick += $this.TimerTick;
	}

    [System.Windows.Controls.Viewport3D]Viewport(){
        Return $this.viewport
    }
    [System.Windows.Controls.Viewport3D]Viewport($viewport){
        Return ($this.viewport = $viewport)
    }

	[CameraBox]Camera(){
		return $this.Cameras[$this.ccIndex];
	}

	[int]CameraIndex(){
		return $this.ccIndex
	}
# ei ole tehty tätä vielä
#	[System.Windows.Media.Media3D.Object3D]ModelsContainer(){
#        Return $this.modelscontainer
#    }

	[System.Windows.Media.Media3D.Visual3DCollection]Models(){
         Return $this.models
    }

	[Lighting]Lighting(){
        Return $this.Lighting
    }

	[bool]IsInteractive()
	{
        Return $this.isInterActive
    }
	[bool]IsInteractive($value){
        if($this.isInterActive -ne $value){
            Return ($this.isInterActive = $value)
            if(-not $this.isInterActive){
                [Scene3D]::RemoveHelperModels()
            }
        }
        Return $null
    }


	[bool]IsCached(){
        Return ($this.CacheMode -ne $null)
	}
	[bool]IsCached($value){
        if($this.CacheMode -eq $value){
            Return ($this.CacheMode = New-Object System.Windows.Media.BitmapCache)
        } else {
            Return ($this.CacheMode = $null)
        }
    }

<#
	protected override void OnMouseDown(MouseButtonEventArgs e)
	{
		Focus();
		base.OnMouseDown(e);
		if (!IsInteractive)
			return;

		if (WFUtils.IsCtrlDown())
		{
			touchPoint = GetTouchPoint(e.GetPosition(this));

			if (adi != null && WFUtils.IsAltDown())
			{
				adi.TargetPoint = touchPoint;
				adi.Update(Camera);
			}
		}
	}

	protected override void OnMouseUp(MouseButtonEventArgs e)
	{
		base.OnMouseUp(e);
		touchPoint = Math3D.Origin;
		prevPosition.X = double.NaN;
	}

	protected override void OnMouseLeave(MouseEventArgs e)
	{
		base.OnMouseLeave(e);
		touchPoint = Math3D.Origin;
		prevPosition.X = double.NaN;
	}

	protected override void OnMouseMove(MouseEventArgs e)
	{
		base.OnMouseMove(e);
		if (!IsInteractive || e.LeftButton != MouseButtonState.Pressed)
			return;

		Point position = e.GetPosition(this);

		if (prevPosition.IsValid())
			HandleMouseMove(prevPosition - position);

		prevPosition = position;
	}

	protected override void OnKeyDown(KeyEventArgs e)
	{
		base.OnKeyDown(e);
		if (!IsInteractive)
			return;

		//--- assume we are handling the key
		e.Handled = true;
		double amount = WFUtils.IsShiftDown() ? 1 : 0.2;

		if (WFUtils.IsCtrlDown())
		{
			amount *= WFUtils.IsAltDown() ? 0.1 : 0.5;
			amount *= Camera.Scale;
			switch (e.Key)
			{
				case Key.Up: Camera.Move(Camera.LookDirection, +amount); return;
				case Key.Down: Camera.Move(Camera.LookDirection, -amount); return;
				case Key.Left: Camera.Move(Camera.LeftDirection, +amount); return;
				case Key.Right: Camera.Move(Camera.LeftDirection, -amount); return;
				case Key.Prior: Camera.Move(Camera.UpDirection, +amount); return;
				case Key.Next: Camera.Move(Camera.UpDirection, -amount); return;
				default: e.Handled = false; return;
			}
		}

		switch (e.Key)
		{
			case Key.Up: Camera.ChangePitch(amount); break;
			case Key.Down: Camera.ChangePitch(-amount); break;
			case Key.Left: if (Camera.Speed == 0) Camera.ChangeYaw(amount); 
							else Camera.ChangeRoll(-amount); break;
			case Key.Right: if (Camera.Speed == 0) Camera.ChangeYaw(-amount); 
							else Camera.ChangeRoll(+amount); break;
			case Key.Prior: Camera.ChangeRoll(-amount); break;
			case Key.Next: Camera.ChangeRoll(+amount); break;
			case Key.W: Camera.Speed++; return;
			case Key.S: Camera.Speed--; return;
			case Key.X: Camera.Speed = 0; return;
			case Key.F: Camera.FlyParallel(); return;
			case Key.A: Camera.FlyParallel(-1); return;
			case Key.D: Camera.FlyParallel(+1); return;
			case Key.T: Camera.LookBack(); return;
			case Key.H: ToggleHelperModels(); return;
			case Key.Space: Camera.LookAtOrigin(); return;
			case Key.D1: ActivateCamera(0); return;
			case Key.D2: ActivateCamera(1); return;
			case Key.D3: ActivateCamera(2); return;
			default: e.Handled = false; return;
		}

		Camera.StopAnyTurn();
	}

	protected override void OnMouseWheel(MouseWheelEventArgs e)
	{
		base.OnMouseWheel(e);
		Camera.FieldOfView *= e.Delta < 0 ? 1.1 : 1 / 1.1;
	}

#>
	[void]ToggleHelperModels(){
		if($this.airplanes -eq $null){
			$this.airplanes = (new-object $this.Airplane[2]);
            [Scene3D]::Models.Add(($this.airplanes[0] = (New-Object $this.Airplane())));
			[Scene3D]::Models.Add(($this.airplanes[1] = (New-Object $this.Airplane())));
		} else {
			if ($this.adi -eq $null){
				$this.adi = (New-Object [ADI]);
				$this.Models.Add($this.adi);
			} else {
				[Scene3D]::RemoveHelperModels();
			}
		}
		[Scene3D]::UpdateHelperModels();
	}

	[void]RemoveHelperModels()
	{
		if ($this.adi -ne $null)
		{
			[Scene3D]::Models.Remove($this.adi);
			$this.adi = $null;
		}
		if ($this.airplanes -ne $null)
		{
			[Scene3D]::Models.Remove(($this.airplanes[0]));
			[Scene3D]::Models.Remove(($this.airplanes[1]));
			$this.airplanes = $null;
		}
	}

	[bool]ActivateCamera([int]$index)
	{
		if (-not [MathUtils]::IsValidIndex($index, $this.Cameras.Count)){
			return $false;
        }

		$this.ccIndex = $index;
		$this.Viewport.Camera = $this.Camera.Camera;
		[Scene3D]::FirePropertyChanged("Camera");

		[Scene3D]::UpdateHelperModels();
		return $true;
	}

	[void]StartTimer([int]$ms = 30)
	{
		if ($this.timer.IsEnabled){
			return;
        }

		$this.timer.Interval = [System.TimeSpan]::FromMilliseconds($ms);
		$this.manualStart = $true;
		$this.IsCached = $false;
		$this.timer.Start();
	}
	[bool]$manualStart;

	[void]StopTimer()
	{
		if (-not $this.timer.IsEnabled){
			return;
        }

		$this.manualStart = $false;
		$this.IsCached = $true;
		$this.timer.Stop();
	}

	[bool]IsTimerBusy()
	{
		return $this.timer.IsEnabled
	}

	[void]AddCamera([double]$x, [double]$y, [double]$z)
	{
		[CameraBox]$camera = (New-Object CameraBox);
		$camera.PropertyChanged += $this.CameraPropertyChanged;
		$camera.NearPlaneDistance = 0.1;
		$camera.FarPlaneDistance = 1000;
		$camera.Position = New-Object System.Windows.Media.Media3D.Point3D($x, $y, $z);
		$camera.LookAtOrigin();
		$this.Cameras.Add($camera);
	}

	[int]$ccIndex = 0
<#
	protected void HandleMouseMove(Vector mouseMove)
	{
		double factor = WFUtils.IsShiftDown() ? 0.5 : 0.1;
		double angleX = mouseMove.X * factor;
		double angleY = mouseMove.Y * factor;

		Camera.StopAnyTurn();
		if (Camera.Speed == 0)
		{
			Camera.Rotate(Math3D.UnitZ, 2 * angleX, touchPoint);
			Camera.Rotate(Camera.RightDirection, 2 * angleY, touchPoint);
		}
		else
		{
			if (Camera.MovingDirectionIsLocked)
			{
				Camera.ChangeHeading(angleX);
				Camera.ChangePitch(angleY);
			}
			else
			{
				Camera.ChangeRoll(-angleX);
				Camera.ChangePitch(angleY);
			}
		}
	}
	[System.Windows.Media.Media3D.Point3D]GetTouchPoint([System.Windows.Point]$pt2D)
	{
		RayMeshGeometry3DHitTestResult htr = Math3D.HitTest(Viewport, pt2D);
		if (htr == null)
			return Math3D.Origin;

		Point3D pt3D = htr.PointHit;//--- in model space
		Matrix3D m = Math3D.GetTransformationMatrix(htr.VisualHit);
		pt3D = m.Transform(pt3D);//--- in global space
		return pt3D;
	}
#>

	[void]CameraPropertyChanged([System.object]$sender, [System.ComponentModel.PropertyChangedEventArgs]$e)
	{
		if ($e.PropertyName -eq "Speed")
		{
			if (-not $this.manualStart)
			{
				if ($this.Cameras.FirstOrDefault($this.cam -ge $this.cam.Speed -ne 0) -eq $null)
				{
					$this.timer.Stop();
					$this.IsCached = $true;
				}
				elseif (-not $this.timer.IsEnabled)
				{
					$this.IsCached = $false;
					$this.timer.Start();
				}
			}
		}
	}

	[void]UpdateHelperModels()
	{
		# the ADI shows the position and orientation of the active camera
		if ($this.adi -ne $null){
			$this.adi.Update($this.Camera);
        }

		if ($this.airplanes -eq $null){
			return;
        }
        [int]$airplaneIndex = 0
		# the airplanes show the position and orientation of the other cameras
		for ([int]$airplaneIndex, [int]$camIndex = 0; $airplaneIndex -lt 2; $airplaneIndex++, $camIndex++){
			if ($camIndex -eq $this.ccIndex){ $camIndex++ }
			[System.Windows.Media.Media3D.Matrix3D]$vm = [Math3D]::GetViewMatrix($this.Cameras[$camIndex].Camera);
			$this.vm.Invert();

			[System.Windows.Media.Media3D.Matrix3D]$wm = [System.Windows.Media.Media3D.Matrix3D]::Identity;
			[double]$scale = $this.Cameras[$camIndex].Scale;
			$wm.Scale((new-object System.Windows.Media.Media3D.Vector3D($this.scale, $this.scale, $this.scale)));
			$wm.Rotate((new-object System.Windows.Media.Media3D.Quaternion([Math3D]::UnitX, -90)));

			$this.airplanes[$airplaneIndex].Transform = (New-Object System.Windows.Media.Media3D.MatrixTransform3D(($wm * $vm)));
		}
	}

	[void]TimerTick([system.object]$sender, [System.EventArgs]$e)
	{
		$this.Camera.MovingDirectionIsLocked = [system.Console]::CapsLock;

		foreach ($camera in $this.Cameras){
			$this.camera.Update();
        }

		[Scene3D]::UpdateHelperModels();

		if ($this.TimerTicked -ne $null){
			$this.TimerTicked($sender, $e);
        }
	}

    [Void] add_PropertyChanged([System.ComponentModel.PropertyChangedEventHandler] $propertyChanged) {
        $this.PropertyChanged = [Delegate]::Combine($this.PropertyChanged, $propertyChanged)
    }

    [Void] remove_PropertyChanged([System.ComponentModel.PropertyChangedEventHandler] $propertyChanged) {
        $this.PropertyChanged = [Delegate]::Remove($this.PropertyChanged, $propertyChanged)
    }

	[void]FirePropertyChanged([string]$propertyName)
	{
		if ($this.PropertyChanged -ne $null){
			$this.PropertyChanged($this, (New-Object System.ComponentModel.PropertyChangedEventArgs($propertyName)));
        }
	}
}
