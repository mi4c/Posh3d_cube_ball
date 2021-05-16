

class MathUtils{
	[double]$PI = 3.1415926535897932384626433;
	[double]$PIx2 = $PI * 2.0;
	[double]$PIo2 = $PI * 0.5;
	# Normalizes an angle to be inbetween -PI and PI.
	[double]NormalizeAngle([double]$angle)
	{
		if ($angle -lt -($this.PI) -or $angle -gt $this.PI)
		{
			$angle = [Math]::IEEERemainder($angle, $this.PIx2);

			if ($angle -lt $this.PI){
				$angle += $this.PIx2;
            }
			elseif ($angle -gt $this.PI){
				$angle -= $this.PIx2;
            }
		}

		return $angle;
	}

	[double]ToRadians([double]$angleInDegrees)
	{
        if(-not $angleInDegrees){ return 0 } else{
		    return (([MathUtils]::angleInDegrees * $this.PI) / 180.0);
        }
	}

	[double]ToDegrees([double]$angleInRadians)
	{
		return (([MathUtils]::angleInRadians * 180.0) / $this.PI);
	}

	static [double]ToSeconds([int]$d, [int]$h, [int]$m, [double]$s)
	{
		return (((((($d * 24) + $h) * 60) + $m) * 60) + $s);
	}

	static [bool]IsValidIndex([int]$index, [int]$count)
	{
		if (($index -lt 0) -or ($index -ge $count)){
			return $false;
        } else{
    		return $true;
        }
	}

	static [bool]IsValidNumber([double]$value)
	{
		if (([double]::IsNaN($value)) -or ([double]::IsInfinity($value))){
			return $false;
        } else {
		    return $true;
        }
	}

	static [double]Clamp([double]$value, [double]$minValue, [double]$maxValue)
	{
		return ([Math]::Min([Math]::Max($value, $minValue), $maxValue));
	}

	static [bool]IsValid([System.Windows.Media.Media3D.Point3D]$pt)
	{
		if ((-not [MathUtils]::IsValidNumber($pt.X)) -or (-not [MathUtils]::IsValidNumber($pt.Y))){
			return $false;
        } else {
		    return $true;
        }
	}
}

# A linear transformation from a range of doubles to another range of doubles.
class LinearTransform{
    [Double]$slope
    [Double]$offset
	LinearTransform()
	{
		[LinearTransform]::Init(0, 1, 0, 1);
	}

	LinearTransform([double]$from1, [double]$from2, [double]$to1, [double]$to2)
	{
		[LinearTransform]::Init($from1, $from2, $to1, $to2);
	}

	[void]Init([double]$from1, [double]$from2, [double]$to1, [double]$to2){
		[double]$diff = $from2 - $from1;
		if ($diff -eq 0){
			$diff = 1E-100;
        }
        
		$this.slope = [LinearTransform]::Slope(($to2 - $to1) / $diff);
		$this.offset = [LinearTransform]::Offset(($to1 - ([LinearTransform]::Slope())) * $from1);
	}

	[double]Slope(){
        Return $this.Slope
    }
    [double]Slope($value){
		Return ($this.slope = $value)
	}

    [double]Offset(){
        Return $this.offset
    }
    [double]Offset($value){
        Return ($this.offset = $value)
    }

	[double]Transform([double]$value)
	{
		return (([LinearTransform]::Slope() * $value) + [LinearTransform]::Offset());
	}

	[double]BackTransform([double]$value)
	{
		return (($value - [LinearTransform]::Offset()) / [LinearTransform]::Slope());
	}
}


class Math3D {
    [System.Windows.Media.Media3D.Point3D]$pt = (New-Object System.Windows.Media.Media3D.Point3D)
    [System.Windows.Media.Media3D.Matrix3D]$ZeroMatrix = (new-object System.Windows.Media.Media3D.Matrix3D(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0));
	[System.Windows.Media.Media3D.Point3D]$Origin = (new-object System.Windows.Media.Media3D.Point3D(0, 0, 0));
	[System.Windows.Media.Media3D.Vector3D]$UnitX = (New-Object System.Windows.Media.Media3D.Vector3D(1, 0, 0));
    [System.Windows.Media.Media3D.Vector3D]$UnitY = (New-Object System.Windows.Media.Media3D.Vector3D(0, 1, 0));
    Static [System.Windows.Media.Media3D.Vector3D]$UnitZ = (New-Object System.Windows.Media.Media3D.Vector3D(0, 0, 1));
    [System.Windows.Media.Media3D.RayMeshGeometry3DHitTestResult]$hitTestResult

    Math3D(){}


	static [Double]Distance([System.Windows.Media.Media3D.Point3D]$pt)
	{        
		return [Math]::Sqrt(($pt.X * $pt.X) + ($pt.Y * $pt.Y) + ($pt.Z * $pt.Z));
	}

	static [double]DistanceSquared([System.Windows.Media.Media3D.Point3D]$pt)
	{
		return (($pt.X * $pt.X) + ($pt.Y * $pt.Y) + ($pt.Z * $pt.Z));
	}

	static [System.Windows.Media.Media3D.Point3D]Add([System.Windows.Media.Media3D.Point3D]$pt, [System.Windows.Media.Media3D.Point3D]$Add)
	{
		return (New-Object System.Windows.Media.Media3D.Point3D(($pt.X + $add.X), ($pt.Y + $add.Y), ($pt.Z + $add.Z)));
	}

	static [System.Windows.Media.Media3D.Point3D]Subtract([System.Windows.Media.Media3D.Point3D]$pt, [System.Windows.Media.Media3D.Point3D]$add)
	{
		return (New-Object System.Windows.Media.Media3D.Point3D(($pt.X - $add.X), ($pt.Y - $add.Y), ($pt.Z - $add.Z)));
	}

	static [System.Windows.Media.Media3D.Point3D]Inverse([System.Windows.Media.Media3D.Point3D]$pt)
	{
		return (New-Object System.Windows.Media.Media3D.Point3D((-($pt.X), -($pt.Y), -($pt.Z))));
	}

	static [bool]IsPTValid([System.Windows.Media.Media3D.Point3D]$pt)
	{
		if ((-not [MathUtils]::IsValidNumber($pt.X)) -or (-not [MathUtils]::IsValidNumber($pt.Y)) -or (-not [MathUtils]::IsValidNumber($pt.Z))){
			return $false;
        }
		return $true;
	}

	static [bool]IsDIRValid([System.Windows.Media.Media3D.Point3D]$dir)
	{
		if ((-not [MathUtils]::IsValidNumber($dir.X)) -or (-not [MathUtils]::IsValidNumber($dir.Y)) -or (-not [MathUtils]::IsValidNumber($dir.Z))){
			return $false;
        }

		if ($dir.LengthSquared -lt 1e-12){
			return $false;
        }
		return $true;
	}

	# Rotates a vector using a quaternion.
	static [System.Windows.Media.Media3D.Vector3D]Transform([System.Windows.Media.Media3D.Quaternion]$q, [System.Windows.Media.Media3D.Vector3D]$v)
	{
		[double]$x2 = $q.X + $q.X;
		[double]$y2 = $q.Y + $q.Y;
		[double]$z2 = $q.Z + $q.Z;
		[double]$wx2 = $q.W * $x2;
		[double]$wy2 = $q.W * $y2;
		[double]$wz2 = $q.W * $z2;
		[double]$xx2 = $q.X * $x2;
		[double]$xy2 = $q.X * $y2;
		[double]$xz2 = $q.X * $z2;
		[double]$yy2 = $q.Y * $y2;
		[double]$yz2 = $q.Y * $z2;
		[double]$zz2 = $q.Z * $z2;
		[double]$x = $v.X * (1.0 - $yy2 - $zz2) + $v.Y * ($xy2 - $wz2) + $v.Z * ($xz2 + $wy2);
		[double]$y = $v.X * ($xy2 + $wz2) + $v.Y * (1.0 - $xx2 - $zz2) + $v.Z * ($yz2 - $wx2);
		[double]$z = $v.X * ($xz2 - $wy2) + $v.Y * ($yz2 + $wx2) + $v.Z * (1.0 - $xx2 - $yy2);
		return (New-Object System.Windows.Media.Media3D.Vector3D($x, $y, $z));
	}

	# Rotates a point using a quaternion.
	static [System.Windows.Media.Media3D.Point3D]Transform([System.Windows.Media.Media3D.Quaternion]$q, [System.Windows.Media.Media3D.Point3D]$p)
	{
		return ([Math3D]::Transform([System.Windows.Media.Media3D.Quaternion]$q,[System.Windows.Media.Media3D.Vector3D]$p));
	}

	# Rotates a vector about an axis.
	static [System.Windows.Media.Media3D.Vector3D]Rotate([System.Windows.Media.Media3D.Vector3D]$v, [System.Windows.Media.Media3D.Vector3D]$rotationAxis, [double]$angleInDegrees)
	{
		[System.Windows.Media.Media3D.Quaternion]$q = New-Object System.Windows.Media.Media3D.Quaternion($rotationAxis, $angleInDegrees);
		return $q.Transform($v);
	}

	# Calculates the cross product of two vectors.
	static [System.Windows.Media.Media3D.Vector3D]Cross([System.Windows.Media.Media3D.Vector3D]$v, [System.Windows.Media.Media3D.Vector3D]$vector)
	{
		return [System.Windows.Media.Media3D.Vector3D]::CrossProduct($v, $vector);
	}

	# Calculates the dot product of two vectors.
	static [double]Dot([System.Windows.Media.Media3D.Vector3D]$v, [System.Windows.Media.Media3D.Vector3D]$vector)
	{
		return [System.Windows.Media.Media3D.Vector3D]::DotProduct($v, $vector);
	}

	# Calculates the angle between two vectors in degrees.
	static [double]AngleTo([System.Windows.Media.Media3D.Vector3D]$v, [System.Windows.Media.Media3D.Vector3D]$vector)
	{
		return [System.Windows.Media.Media3D.Vector3D]::AngleBetween($v, $vector);
	}

	# Gets the unit direction vector from this point to a target point.
	static [System.Windows.Media.Media3D.Vector3D]DirectionTo([System.Windows.Media.Media3D.Point3D]$thisPoint, [System.Windows.Media.Media3D.Point3D]$targetPoint)
	{
		[System.Windows.Media.Media3D.Vector3D]$v = $targetPoint - $thisPoint;
		$v.Normalize();
		return $v;
	}

	# Gets the aspect ratio.
    static [double]GetAspectRatio([System.Drawing.Size]$size)
    {
        return ($size.Width / $size.Height);
    }

    static [System.Windows.Media.Media3D.Matrix3D]GetViewMatrix([System.Windows.Media.Media3D.ProjectionCamera]$camera)
    {
        # This math is identical to what you find documented for
        # D3DXMatrixLookAtRH with the exception that WPF uses a
        # LookDirection vector rather than a LookAt point.

        [System.Windows.Media.Media3D.Vector3D]$zAxis = -($camera.LookDirection);
        $zAxis.Normalize();

		[System.Windows.Media.Media3D.Vector3D]$xAxis = $camera.UpDirection.Cross($zAxis);
        $xAxis.Normalize();

		[System.Windows.Media.Media3D.Vector3D]$yAxis = $zAxis.Cross($xAxis);

        [System.Windows.Media.Media3D.Vector3D]$position = [System.Windows.Media.Media3D.Vector3D]$camera.Position;
        [double]$offsetX = -($xAxis.Dot($position));
        [double]$offsetY = -($yAxis.Dot($position));
        [double]$offsetZ = -($zAxis.Dot($position));

        return (New-Object System.Windows.Media.Media3D.Matrix3D(
            $xAxis.X, $yAxis.X, $zAxis.X, 0,
            $xAxis.Y, $yAxis.Y, $zAxis.Y, 0,
            $xAxis.Z, $yAxis.Z, $zAxis.Z, 0,
            $offsetX, $offsetY, $offsetZ, 1));
    }

	# Computes the effective view matrix for the given camera.
    static [System.Windows.Media.Media3D.Matrix3D]GetViewMatrix([System.Windows.Media.Media3D.Camera]$camera)
    {
        $result = $null
        if ($camera -eq $null)
        {
            $result = throw "camera";
        }

        [System.Windows.Media.Media3D.ProjectionCamera]$projectionCamera = $camera -as [System.Windows.Media.Media3D.ProjectionCamera];

        if ($projectionCamera -ne $null)
        {
            $result = [Math3d]::GetViewMatrix($projectionCamera);
        }

        [System.Windows.Media.Media3D.MatrixCamera]$matrixCamera = $camera -as [System.Windows.Media.Media3D.MatrixCamera];

        if ($matrixCamera -ne $null)
        {
            $result = $matrixCamera.ViewMatrix;
        }
        if($result){
            Return $result
        } else { Return $result = 'Unsupported camera'}
#        throw new ArgumentException(String.Format("Unsupported camera type '{0}'.", camera.GetType().FullName), "camera");
    }

    static [System.Windows.Media.Media3D.Matrix3D]GetProjectionMatrix([System.Windows.Media.Media3D.OrthographicCamera]$camera, [double]$aspectRatio)
    {
        # This math is identical to what you find documented for
        # D3DXMatrixOrthoRH with the exception that in WPF only
        # the camera's width is specified.  Height is calculated
        # from width and the aspect ratio.

        [double]$w = $camera.Width;
        [double]$h = $w / $aspectRatio;
        [double]$zn = $camera.NearPlaneDistance;
        [double]$zf = $camera.FarPlaneDistance;

        [double]$m33 = 1 / ($zn - $zf);
        [double]$m43 = $zn * $m33;

        return New-Object [System.Windows.Media.Media3D.Matrix3D](
				2/$w, 0, 0, 0,
				0, 2/$h, 0, 0,
				0, 0, $m33, 0,
				0, 0, $m43, 1);
    }

    static [System.Windows.Media.Media3D.Matrix3D]GetProjectionMatrix([System.Windows.Media.Media3D.PerspectiveCamera]$camera, [double]$aspectRatio)
    {
        # This math is identical to what you find documented for
        # D3DXMatrixPerspectiveFovRH with the exception that in
        # WPF the camera's horizontal rather the vertical
        # field-of-view is specified.

        [double]$hFoV = [MathUtils]::ToRadians($camera.FieldOfView);
        [double]$zn = $camera.NearPlaneDistance;
        [double]$zf = $camera.FarPlaneDistance;

        [double]$xScale = 1 / [Math]::Tan($hFoV / 2);
        [double]$yScale = $aspectRatio * $xScale;
        if(($zf -eq [double]::PositiveInfinity) -eq -1){
            [double]$m33 = $zf
        } else {
            [double]$m33 = ($zf / ($zn - $zf))
        }
        [double]$m43 = $zn * $m33;

        return New-Object System.Windows.Media.Media3D.Matrix3D(
				$xScale, 0, 0, 0,
				0, $yScale, 0, 0,
				0, 0, $m33, -1,
				0, 0, $m43, 0);
    }

    # Computes the effective projection matrix for the given camera.
    static [System.Windows.Media.Media3D.Matrix3D]GetProjectionMatrix([System.Windows.Media.Media3D.Camera]$camera, [double]$aspectRatio)
    {
        $result = $null
        if ($camera -eq $null)
        {
            $result = throw "camera";
        }

        [System.Windows.Media.Media3D.PerspectiveCamera]$perspectiveCamera = $camera -as [System.Windows.Media.Media3D.PerspectiveCamera];

        if ($perspectiveCamera -ne $null)
        {
            $result = [Math3D]::GetProjectionMatrix($perspectiveCamera, $aspectRatio);
        }

        [System.Windows.Media.Media3D.OrthographicCamera]$orthographicCamera = $camera -as [System.Windows.Media.Media3D.OrthographicCamera];

        if ($orthographicCamera -ne $null)
        {
            $result = [Math3D]::GetProjectionMatrix($orthographicCamera, $aspectRatio);
        }

        [System.Windows.Media.Media3D.MatrixCamera]$matrixCamera = $camera -as [System.Windows.Media.Media3D.MatrixCamera];

        if ($matrixCamera -ne $null)
        {
            $result = $matrixCamera.ProjectionMatrix;
        }
        if($result){Return $result}else{Return "unsupported camera"}
#        throw new ArgumentException(String.Format("Unsupported camera type '{0}'.", camera.GetType().FullName), "camera");
    }

    static [System.Windows.Media.Media3D.Matrix3D]GetHomogeneousToViewportTransform([System.Windows.Rect]$viewport)
    {
        [double]$scaleX = $viewport.Width / 2;
        [double]$scaleY = $viewport.Height / 2;
        [double]$offsetX = $viewport.X + $scaleX;
        [double]$offsetY = $viewport.Y + $scaleY;

        return New-Object System.Windows.Media.Media3D.Matrix3D(
                $scaleX, 0, 0, 0,
                    0, -($scaleY), 0, 0,
                    0, 0, 1, 0,
            $offsetX, $offsetY, 0, 1);
    }

    # <summary>
    #     Computes the transform from world space to the Viewport3DVisual's
    #     inner 2D space.
    # 
    #     This method can fail if Camera.Transform is non-invertable
    #     in which case the camera clip planes will be coincident and
    #     nothing will render.  In this case success will be false.
    # </summary>
#    static [System.Windows.Media.Media3D.Matrix3D]TryWorldToViewportTransform([System.Windows.Media.Media3D.Viewport3DVisual]$visual, out [bool]$success)
    static [System.Windows.Media.Media3D.Matrix3D]TryWorldToViewportTransform([System.Windows.Media.Media3D.Viewport3DVisual]$visual, [bool]$success)
    {
        $success = $false;
#        [System.Windows.Media.Media3D.Matrix3D]$result = [Math3D]::TryWorldToCameraTransform($visual, out $success);
        [System.Windows.Media.Media3D.Matrix3D]$result = [Math3D]::TryWorldToCameraTransform($visual, $success);

        if ($success)
        {
            $result.Append([Math3D]::GetProjectionMatrix($visual.Camera, [Math3D]::GetAspectRatio($visual.Viewport.Size)));
            $result.Append([Math3D]::GetHomogeneousToViewportTransform($visual.Viewport));
            $success = $true;
        }

        return $success;
    }

    # <summary>
    #     Computes the transform from world space to camera space
    # 
    #     This method can fail if Camera.Transform is non-invertable
    #     in which case the camera clip planes will be coincident and
    #     nothing will render.  In this case success will be false.
    # </summary>
#    static Matrix3D TryWorldToCameraTransform(Viewport3DVisual visual, out bool success)
    [System.Windows.Media.Media3D.Matrix3D]TryWorldToCameraTransform([System.Windows.Media.Media3D.Viewport3DVisual]$visual, [bool]$success)
    {
        $success = $false;

        if ($visual -eq $null){
            $result = $this.ZeroMatrix;
        }
		[System.Windows.Media.Media3D.Matrix3D]$result = [System.Windows.Media.Media3D.Matrix3D]::Identity;
        
        [System.Windows.Media.Media3D.Camera]$camera = $visual.Camera;

        if ($camera -eq $null)
        {
            $result = $this.ZeroMatrix;
        }

        [System.Windows.Rect]$viewport = $visual.Viewport;

        if ($viewport -eq [System.Windows.Rect]::Empty)
        {
            $result = $this.ZeroMatrix;
        }

        [System.Windows.Media.Media3D.Transform3D]$cameraTransform = $camera.Transform;

        if ($cameraTransform -ne $null)
        {
            [System.Windows.Media.Media3D.Matrix3D]$m = $cameraTransform.Value;

            if (-not $m.HasInverse)
            {
                $result = $this.ZeroMatrix;
            } else {
                $m.Invert();
                $result.Append($m);
            }
        }
        if($result){ return $success }else {
            $result.Append([Math3D]::GetViewMatrix($camera));
            $success = $true;
            return $success;
        }        
    }

	# Gets the object space to world space (or a parent object space) transformation for the given 3D visual.
	static [System.Windows.Media.Media3D.Matrix3D]GetTransformationMatrix([System.Windows.DependencyObject]$visual)
	{
		[System.Windows.Media.Media3D.Matrix3D]$matrix = [System.Windows.Media.Media3D.Matrix3D]::Identity;

		while ($visual -is [System.Windows.Media.Media3D.ModelVisual3D])
		{
			[System.Windows.Media.Media3D.Transform3D]$transform = [System.Windows.Media.Media3D.Transform3D]$visual.GetValue([System.Windows.Media.Media3D.ModelVisual3D]::TransformProperty);
			if ($transform -ne $null){
				$matrix.Append($transform.Value);
            }
			$visual = [System.Windows.Media.VisualTreeHelper]::GetParent($visual);
		}

		return $matrix;
	}

    # <summary>
    # Gets the object space to world space transformation for the given DependencyObject
    # </summary>
    # <param name="visual">The visual whose world space transform should be found</param>
    # <param name="viewport">The Viewport3DVisual the Visual is contained within</param>
    # <returns>The world space transformation</returns>
    [System.Windows.Media.Media3D.Matrix3D]GetWorldTransformationMatrix([System.Windows.DependencyObject]$visual, [System.Windows.Media.Media3D.Viewport3DVisual]$viewport)
    {
        [System.Windows.Media.Media3D.Matrix3D]$worldTransform = [System.Windows.Media.Media3D.Matrix3D]::Identity;
        $viewport = $null;

        if (-not($visual -is [System.Windows.Media.Media3D.Visual3D]))
        {
            throw "Must be of type Visual3D.";
        }

        while ($visual -ne $null)
        {
            if (-not($visual -is [System.Windows.Media.Media3D.ModelVisual3D]))
            {
                break;
            }

            [System.Windows.Media.Media3D.Transform3D]$transform = [System.Windows.Media.Media3D.Transform3D]$visual.GetValue([System.Windows.Media.Media3D.ModelVisual3D]::TransformProperty);

            if ($transform -ne $null)
            {
                $worldTransform.Append($transform.Value);
            }

            $visual = [System.Windows.Media.VisualTreeHelper]::GetParent($visual);
        }

        $viewport = $visual -as [System.Windows.Media.Media3D.Viewport3DVisual];

        if ($viewport -eq $null)
        {
            if ($visual -ne $null)
            {
                # In WPF 3D v1 the only possible configuration is a chain of
                # ModelVisual3Ds leading up to a Viewport3DVisual.

                throw "Unsupported type: '{0}'.  Expected tree of ModelVisual3Ds leading up to a Viewport3DVisual."
            }

            return $this.ZeroMatrix;
        }

        return $worldTransform;
    }

	# <summary>
	# Computes the transform from the inner space of the given
	# Visual3D to the 2D space of the Viewport3DVisual which
	# contains it.
	# The result will contain the transform of the given visual.
	# This method can fail if Camera.Transform is non-invertable
	# in which case the camera clip planes will be coincident and
	# nothing will render.  In this case success will be false.
	# </summary>
	# <param name="visual">The visual.</param>
	# <param name="viewport">The viewport.</param>
    [System.Windows.Media.Media3D.Matrix3D]TryTransformTo2DAncestor([System.Windows.DependencyObject]$visual, [System.Windows.Media.Media3D.Viewport3DVisual]$viewport, [bool]$success)
    {
        [System.Windows.Media.Media3D.Matrix3D]$to2D = [Math3D]::GetWorldTransformationMatrix($visual, $viewport);
        $to2D.Append([Math3D]::TryWorldToViewportTransform($viewport, $success));

        if (-not $success)
        {
            return $this.ZeroMatrix;
        } else {
            return $to2D;
        }
    }

	# <summary>
	# Computes the transform from the inner space of the given
	# Visual3D to the camera coordinate space
	# The result will contain the transform of the given visual.
	# This method can fail if Camera.Transform is non-invertable
	# in which case the camera clip planes will be coincident and
	# nothing will render.  In this case success will be false.
	# </summary>
	# <param name="visual">The visual.</param>
	# <param name="viewport">The viewport.</param>
    [System.Windows.Media.Media3D.Matrix3D]TryTransformToCameraSpace([System.Windows.DependencyObject]$visual, [System.Windows.Media.Media3D.Viewport3DVisual]$viewport, [bool]$success)
    {
        [System.Windows.Media.Media3D.Matrix3D]$toViewSpace = [Math3D]::GetWorldTransformationMatrix($visual, $viewport);
        $toViewSpace.Append([Math3D]::TryWorldToCameraTransform($viewport, $success));

        if (-not $success)
        {
            return $this.ZeroMatrix;
        } else {
            return $toViewSpace;
        }
    }

	# <summary>
	# Given a ModelVisual3D and a 2D point on the screen 
	# this function calculates the corresponding 3D ray.
	# </summary>
	# <param name="ptPlot">The 2D point on the screen.</param>
	# <param name="mv3D">The ModelVisual3D.</param>
	# <param name="ptNear">The 3D point which belongs to the near clipping plane.</param>
	# <param name="ptFar">The 3D point which belongs to the far clipping plane.</param>
	static [bool]GetRay([System.Windows.Point]$ptPlot, [System.Windows.Media.Media3D.ModelVisual3D]$mv3D, [System.Windows.Media.Media3D.Point3D]$ptNear, [System.Windows.Media.Media3D.Point3D]$ptFar)
	{
		$success = (New-Object bool);
		[System.Windows.Media.Media3D.Viewport3DVisual]$vp = (New-Object System.Windows.Media.Media3D.Viewport3DVisual)
		[System.Windows.Media.Media3D.Matrix3D]$modelToViewport = [Math3D]::TryTransformTo2DAncestor($mv3D, $vp, $success);

		if ((-not ($success)) -or (-not ($modelToViewport.HasInverse)))
		{
			$ptNear = $ptFar = New-Object System.Windows.Media.Media3D.Point3D;
			return $false;
		}

		[System.Windows.Media.Media3D.Matrix3D]$viewportToModel = $modelToViewport;
		$viewportToModel.Invert();

		[System.Windows.Media.Media3D.Point3D]$ptMouse = New-Object System.Windows.Media.Media3D.Point3D($ptPlot.X, $ptPlot.Y, 0);
		$ptNear = $viewportToModel.Transform($ptMouse);

		$ptMouse.Z = 1;
		$ptFar = $viewportToModel.Transform($ptMouse);

		return $true;
	}
	# <summary>
	# Performs a 3D hit test. Point pt is a 2D point in viewport space. 
	# The object needs to be a Viewport3D or a ModelVisual3D.
	# </summary>
	[System.Windows.Media.Media3D.RayMeshGeometry3DHitTestResult]HitTest([object]$obj, [System.Windows.Point]$pt){
        [System.Windows.Controls.Viewport3D]$viewport = $obj -as [System.Windows.Controls.Viewport3D];
		if ($viewport -ne $null){
#			$this.hitTestResult = ([System.Windows.Media.VisualTreeHelper]::HitTest($viewport, $null, ($this.HitTestResultCallback),(New-Object System.Windows.Media.PointHitTestParameters($pt))));
			$this.hitTestResult = ([System.Windows.Media.VisualTreeHelper]::HitTest($viewport, $pt));
		} else {
			[System.Windows.Media.Media3D.ModelVisual3D]$model = $obj -as [System.Windows.Media.Media3D.ModelVisual3D];
			if ($model -ne $null){
				[System.Windows.Media.Media3D.Point3D]$ptNear = (New-Object System.Windows.Media.Media3D.Point3D)
                [System.Windows.Media.Media3D.Point3D]$ptFar = (New-Object System.Windows.Media.Media3D.Point3D)
				if ([Math3D]::GetRay($pt, $model, $ptNear, $ptFar)){
					$paras = (New-Object System.Windows.Media.Media3D.RayHitTestParameters($ptNear, $ptFar - $ptNear));
					$this.hitTestResult = [System.Windows.Media.VisualTreeHelper]::HitTest($model, $null, [Math3D]::HitTestResultCallback, $paras);
				}
			}
		}
		return $this.hitTestResult
	}
    
	Static [System.Windows.Media.HitTestResultBehavior]HitTestResultCallback([System.Windows.Media.HitTestResult]$result)
	{
		[System.Windows.Media.Media3D.RayMeshGeometry3DHitTestResult]$htr = $result -as [System.Windows.Media.Media3D.RayMeshGeometry3DHitTestResult];
        Write-Warning $htr
		if ($htr -ne $null){
        	return [System.Windows.Media.HitTestResultBehavior]::Continue;
		} else {
		    return [System.Windows.Media.HitTestResultBehavior]::Stop;
        }
        #return $this.hitTestResult
	}

	# <summary>
	# Calculates the intersections between a ray and a mesh.
	# <para>
	# See also http://jgt.akpeters.com/papers/MollerTrumbore97/ and 
	# http://www.cs.virginia.edu/~gfx/Courses/2003/ImageSynthesis/papers/Acceleration/Fast%20MinimumStorage%20RayTriangle%20Intersection.pdf
	# </para>
	# </summary>
	# <param name="orig">The origin of the ray.</param>
	# <param name="dir">The direction of the ray.</param>
	# <param name="mesh">The mesh.</param>
	# <param name="frontFacesOnly">if set to <c>true</c> calculates front faces intersections only.</param>
	# <returns>A list of doubles [t1,...,tN] which can be used to calculate 
	# the intersection points by equation pI = orig + tI * dir, 1 &lt;= I &lt;= N.</returns>
#	[Obsolete]
	static [System.Collections.Generic.List[double]]RayMeshIntersections([System.Windows.Media.Media3D.Point3D]$orig, [System.Windows.Media.Media3D.Vector3D]$dir, [System.Windows.Media.Media3D.MeshGeometry3D]$mesh, [bool]$frontFacesOnly)
	{
		[System.Collections.Generic.List[double]]$result = New-Object System.Collections.Generic.List[double];

		if ($mesh -eq $null -or -not($dir.IsDIRValid())){
			return $result;
        }

		[double]$epsilon = 1E-9;
		[System.Windows.Media.Int32Collection]$indices = $mesh.TriangleIndices;
		[System.Windows.Media.Media3D.Point3DCollection]$positions = $mesh.Positions;

		for ([int]$i = 0; $i -lt $indices.Count; $i += 3)
		{
			[System.Windows.Media.Media3D.Point3D]$vert0 = $positions[$indices[$i]];
			[System.Windows.Media.Media3D.Point3D]$vert1 = $positions[$indices[$i + 1]];
			[System.Windows.Media.Media3D.Point3D]$vert2 = $positions[$indices[$i + 2]];

			# find vectors for two edges sharing vert0
			[System.Windows.Media.Media3D.Vector3D]$edge1 = $vert1 - $vert0;
			[System.Windows.Media.Media3D.Vector3D]$edge2 = $vert2 - $vert0;

			# begin calculating determinant  also used to calculate U parameter
			[System.Windows.Media.Media3D.Vector3D]$pvec = $dir.Cross($edge2);

			# if determinant is near zero ray lies in plane of triangle
			[double]$det = $edge1.Dot($pvec);
			if ($det -lt $epsilon)
			{
				if ($frontFacesOnly){
					continue;
                }
				elseif ($det -gt -($epsilon)){
					continue;
                }
			}
			[double]$inv_det = 1.0 / $det;

			# calculate distance from vert0 to ray origin
			[System.Windows.Media.Media3D.Vector3D]$tvec = $orig - $vert0;

			# calculate U parameter and test bounds
			[double]$u = $tvec.Dot($pvec) * $inv_det;
			if ($u -lt 0.0 -or $u -gt 1.0){
				continue;
            }

			# prepare to test V parameter
			[System.Windows.Media.Media3D.Vector3D]$qvec = $tvec.Cross($edge1);

			# calculate V parameter and test bounds
			[double]$v = $dir.Dot($qvec) * $inv_det;
			if ($v -lt 0.0 -or $u + $v -gt 1.0){
				continue;
            }
			# calculate t scale parameters, ray intersects triangle
			[double]$t = $edge2.Dot($qvec) * $inv_det;

			$result.Add($t);
		}

		return $result;
	}

	# <summary>
	# Transforms the axis-aligned bounding box 'bounds' by 'transform'.
	# </summary>
	# <param name="bounds">The AABB to transform.</param>
	# <param name="transform">The transform.</param>
	# <returns>Transformed AABB</returns>
    static [System.Windows.Media.Media3D.Rect3D]TransformBounds([System.Windows.Media.Media3D.Rect3D]$bounds, [System.Windows.Media.Media3D.Matrix3D]$transform)
    {
        [double]$x1 = $bounds.X;
        [double]$y1 = $bounds.Y;
        [double]$z1 = $bounds.Z;
        [double]$x2 = $bounds.X + $bounds.SizeX;
        [double]$y2 = $bounds.Y + $bounds.SizeY;
        [double]$z2 = $bounds.Z + $bounds.SizeZ;

        [System.Windows.Media.Media3D.Point3D[]]$points = (New-Object System.Windows.Media.Media3D.Point3D[]{
            (New-Object System.Windows.Media.Media3D.Point3D($x1, $y1, $z1)),
            (new-Object System.Windows.Media.Media3D.Point3D($x1, $y1, $z2)),
            (new-Object System.Windows.Media.Media3D.Point3D($x1, $y2, $z1)),
            (new-Object System.Windows.Media.Media3D.Point3D($x1, $y2, $z2)),
            (new-Object System.Windows.Media.Media3D.Point3D($x2, $y1, $z1)),
            (new-Object System.Windows.Media.Media3D.Point3D($x2, $y1, $z2)),
            (new-Object System.Windows.Media.Media3D.Point3D($x2, $y2, $z1)),
            (new-Object System.Windows.Media.Media3D.Point3D($x2, $y2, $z2))
        });

        $transform.Transform($points);

        # reuse the 1 and 2 variables to stand for smallest and largest
        [System.Windows.Media.Media3D.Point3D]$p = $points[0];
        $x1 = $x2 = $p.X; 
        $y1 = $y2 = $p.Y; 
        $z1 = $z2 = $p.Z;

        for([int]$i = 1; $i -lt $points.Length; $i++)
        {
            $p = $points[$i];

            $x1 = [Math]::Min($x1, $p.X); $y1 = [Math]::Min($y1, $p.Y); $z1 = [Math]::Min($z1, $p.Z);
            $x2 = [Math]::Max($x2, $p.X); $y2 = [Math]::Max($y2, $p.Y); $z2 = [Math]::Max($z2, $p.Z);
        }

        return New-Object System.Windows.Media.Media3D.Rect3D($x1, $y1, $z1, ($x2 - $x1), ($y2 - $y1), ($z2 - $z1));
    }

    # <summary>
    #     Computes the center of 'box'
    # </summary>
    # <param name="box">The Rect3D we want the center of</param>
    # <returns>The center point</returns>
    static [System.Windows.Media.Media3D.Point3D]GetCenter([System.Windows.Media.Media3D.Rect3D]$box)
    {
        return New-Object System.Windows.Media.Media3D.Point3D(($box.X + ($box.SizeX / 2)), ($box.Y + ($box.SizeY / 2)), ($box.Z + ($box.SizeZ / 2)));
    }

	# Linear interpolation of 3D vectors.
	static [System.Windows.Media.Media3D.Vector3D]Lerp([System.Windows.Media.Media3D.Vector3D]$from, [System.Windows.Media.Media3D.Vector3D]$to, [double]$t)
	{
		[System.Windows.Media.Media3D.Vector3D]$v = New-Object System.Windows.Media.Media3D.Vector3D
		$v.X = $from.X * (1 - $t) + $to.X * $t;
		$v.Y = $from.Y * (1 - $t) + $to.Y * $t;
		$v.Z = $from.Z * (1 - $t) + $to.Z * $t;
		return $v;
	}
	# Linear interpolation of quaternions.
	static [System.Windows.Media.Media3D.Quaternion]Lerp([System.Windows.Media.Media3D.Quaternion]$from, [System.Windows.Media.Media3D.Quaternion]$to, [double]$t)
	{
		[double]$angle = $from.Angle * (1 - $t) + $to.Angle * $t;
		[System.Windows.Media.Media3D.Vector3D]$axis = [Math3D]::Lerp($from.Axis, $to.Axis, $t);
		return New-Object System.Windows.Media.Media3D.Quaternion($axis, $angle);
	}

	# Rotates the specified point about the specified axis by the specified angle.
	static [System.Windows.Media.Media3D.Point3D]Rotate([System.Windows.Media.Media3D.Point3D]$pt, [System.Windows.Media.Media3D.Point3D]$ptAxis1, [System.Windows.Media.Media3D.Point3D]$ptAxis2, [double]$angle, [bool]$isAngleInDegrees = $true)
	{
		[System.Windows.Media.Media3D.Vector3D]$axis = $ptAxis2 - $ptAxis1;
		[System.Windows.Media.Media3D.Quaternion]$q = [Math3D]::Rotation($axis, $angle, $isAngleInDegrees);
		return [System.Windows.Media.Media3D.Point3D]$q.Transform($pt - $ptAxis1) + [System.Windows.Media.Media3D.Vector3D]$ptAxis1;
	}

	# Calculates a rotation quaternion. Rotation axis does not have to be a unit vector.
	static [System.Windows.Media.Media3D.Quaternion]Rotation([System.Windows.Media.Media3D.Vector3D]$rotationAxis, [double]$angle)
	{
        [bool]$isAngleInDegrees = $true
		if (-not ($isAngleInDegrees)){
			$angle = [MathUtils]::ToDegrees($angle);
        }

		# Angle should be within 0 and 360. Otherwise the following happens: if angle is -1 and axis is (0,0,1) 
		# the returned Quaternion will have an axis of (0,0,-1) and an angle of +1, which for sure leads to the 
		# same rotation, but is troublesome when reusing the quaternion in animation calculations.
		$angle %= 360;
		if ($angle -lt 0){ $angle += 360;}
		if ($angle -gt 360){ $angle -= 360;}

		return (New-Object System.Windows.Media.Media3D.Quaternion($rotationAxis, $angle));
	}

	# Gets a quaternion for the rotation about the global x axis.
	[System.Windows.Media.Media3D.Quaternion]RotationX([double]$angle, [bool]$isAngleInDegrees = $true)
	{
		return [Math3D]::Rotation($this.UnitX, $angle, $isAngleInDegrees);
	}

	# Gets a quaternion for the rotation about the global y axis.
	[System.Windows.Media.Media3D.Quaternion]RotationY([double]$angle, [bool]$isAngleInDegrees = $true)
	{
		return [Math3D]::Rotation($this.UnitY, $angle, $isAngleInDegrees);
	}

	# Gets a quaternion for the rotation about the global z axis.
	[System.Windows.Media.Media3D.Quaternion]RotationZ([double]$angle, [bool]$isAngleInDegrees = $true)
	{
		return [Math3D]::Rotation($this.UnitZ, $angle, $isAngleInDegrees);
	}

	# Calculates the look direction and up direction for an observer looking at a target point.
	[void]LookAt([System.Windows.Media.Media3D.Point3D]$targetPoint, [System.Windows.Media.Media3D.Point3D]$observerPosition, [System.Windows.Media.Media3D.Vector3D]$lookDirection, [System.Windows.Media.Media3D.Vector3D]$upDirection)
	{
		$lookDirection = $targetPoint - $observerPosition;
		$lookDirection.Normalize();

		[double]$a = $lookDirection.X;
		[double]$b = $lookDirection.Y;
		[double]$c = $lookDirection.Z;

		# Find the one and only up vector (x, y, z) which has a positive z value (1), 
		# which is perpendicular to the look vector (2) and and which ensures that 
		# the resulting roll angle is 0, i.e. the resulting left vector (= up cross look)
		# lies within the xy-plane (or has a z value of 0) (3). In other words: 
		# 1. z > 0 (e.g. 1)
		# 2. ax + by + cz = 0
		# 3. ay - bx = 0
		# If the observer position is right above or below the target point, i.e. a = b = 0 and c != 0, 
		# we set the up vector to (1, 0, 0) for c > 0 and to (-1, 0, 0) for c < 0.

		[double]$length = ($a * $a + $b * $b);
		if ($length -gt 1e-12)
		{
			$upDirection = New-Object System.Windows.Media.Media3D.Vector3D(-($c) * $a / $length, -($c) * $b / $length, 1);
			$upDirection.Normalize();
		}
		else
		{
			if ($c -gt 0){
				$upDirection = $this.UnitX;
            } else {
				$upDirection = -($this.UnitX);
            }
		}
	}
}

# <summary>
# A transformation for 3D points.
# </summary>
class Point3DTransform
{
	# Initializes a new instance of the <see cref="Point3DTransform"/> class.
	Point3DTransform()
	{
		$this.TX = New-Object LinearTransform;
		$this.TY = New-Object LinearTransform;
		$this.TZ = New-Object LinearTransform;
	}

	# Initializes this instance of the <see cref="Point3DTransform"/> class.
	[void]Init([System.Windows.Media.Media3D.Point3D]$p0, [System.Windows.Media.Media3D.Point3D]$p1, [double]$t0 = 0, [double]$t1 = 1)
	{
		$this.TX.Init($t0, $t1, $p0.X, $p1.X);
		$this.TY.Init($t0, $t1, $p0.Y, $p1.Y);
		$this.TZ.Init($t0, $t1, $p0.Z, $p1.Z);
	}

	[System.Windows.Media.Media3D.Point3D]GetPoint([double]$t)
	{
		return (New-Object System.Windows.Media.Media3D.Point3D($this.TX.Transform($t), $this.TY.Transform($t), $this.TZ.Transform($t)));
	}

	# Gets the transformed point.
	[System.Windows.Media.Media3D.Point3D]Transform([System.Windows.Media.Media3D.Point3D]$pt)
	{
		return (New-Object System.Windows.Media.Media3D.Point3D($this.TX.Transform($pt.X)),
			$this.TY.Transform($pt.Y), $this.TZ.Transform($pt.Z));
	}

	# Gets the inverse transformed point.
	[System.Windows.Media.Media3D.Point3D]BackTransform([System.Windows.Media.Media3D.Point3D]$pt)
	{
		return (New-Object System.Windows.Media.Media3D.Point3D($this.TX.BackTransform($pt.X))),
			$this.TY.BackTransform($pt.Y), $this.TZ.BackTransform($pt.Z);
	}

	# Gets or sets the transformation for x values.
	hidden [LinearTransform]$TX = $($this | Add-Member ScriptProperty 'TX' {
         {
            # get
            $this.TX
         }
         {
            Param($arg)
            #set
            $this.TX = $arg
         }
    })

	# Gets or sets the transformation for y values.
	hidden [LinearTransform]$TY = $($this | Add-Member ScriptProperty 'TY' {
         {
            # get
            $this.TY
         }
         {
            Param($arg)
            #set
            $this.TY = $arg
         }
    })

	# Gets or sets the transformation for z values.
	hidden [LinearTransform]$TZ = $($this | Add-Member ScriptProperty 'TZ' {
         {
            # get
            $this.TZ
         }
         {
            Param($arg)
            #set
            $this.TZ = $arg
         }
    })
}

class Vector3DTransform
{
	# Initializes a new instance of the <see cref="Vector3DTransform"/> class.
	Vector3DTransform()
	{
		$this.TX = New-Object LinearTransform;
		$this.TY = New-Object LinearTransform;
		$this.TZ = New-Object LinearTransform;
	}

	# Initializes this instance of the <see cref="Vector3DTransform"/> class.
	[void]Init([System.Windows.Media.Media3D.Vector3D]$v0, [System.Windows.Media.Media3D.Vector3D]$v1, [double]$t0 = 0, [double]$t1 = 1)
	{
		$this.TX.Init($t0, $t1, $v0.X, $v1.X);
		$this.TY.Init($t0, $t1, $v0.Y, $v1.Y);
		$this.TZ.Init($t0, $t1, $v0.Z, $v1.Z);
	}

	[System.Windows.Media.Media3D.Vector3D]GetVector([double]$t)
	{
		return (New-Object System.Windows.Media.Media3D.Vector3D($this.TX.Transform($t), $this.TY.Transform($t), $this.TZ.Transform($t)));
	}

	# Gets the transformed vector.
	[System.Windows.Media.Media3D.Vector3D]Transform([System.Windows.Media.Media3D.Vector3D]$v)
	{
		return (New-Object System.Windows.Media.Media3D.Vector3D($this.TX.Transform($v.X)),
			$this.TY.Transform($v.Y), $this.TZ.Transform($v.Z));
	}

	# Gets the inverse transformed vector.
	[System.Windows.Media.Media3D.Vector3D]BackTransform([System.Windows.Media.Media3D.Vector3D]$v)
	{
		return (New-Object System.Windows.Media.Media3D.Vector3D($this.TX.BackTransform($v.X)),
			$this.TY.BackTransform($v.Y), $this.TZ.BackTransform($v.Z));
	}
    # Tämä ei välttämättä toimi !!!!!! Voi olla, että joutuu jotain muuta keksimään GET; SET; toiminnon toteuttamiseksi
	# Gets or sets the transformation for x values.
	hidden [LinearTransform]$TX = $($this | Add-Member ScriptProperty 'TX' {
         {
            # get
            $this.TX
         }
         {
            Param($arg)
            #set
            $this.TX = $arg
         }
    })

	# Gets or sets the transformation for y values.
	hidden [LinearTransform]$TY = $($this | Add-Member ScriptProperty 'TY' {
         {
            # get
            $this.TY
         }
         {
            Param($arg)
            #set
            $this.TY = $arg
         }
    })

	# Gets or sets the transformation for z values.
	hidden [LinearTransform]$TZ = $($this | Add-Member ScriptProperty 'TZ' {
         {
            # get
            $this.TZ
         }
         {
            Param($arg)
            #set
            $this.TZ = $arg
         }
    })
}

class Matrix3DTransform
{
	[void]Init([System.Windows.Media.Media3D.Matrix3D]$m0, [System.Windows.Media.Media3D.Matrix3D]$m1, [double]$t0 = 0, [double]$t1 = 1)
	{
		$this.t11.Init($t0, $t1, $m0.M11, $m1.M11);
		$this.t12.Init($t0, $t1, $m0.M12, $m1.M12);
		$this.t13.Init($t0, $t1, $m0.M13, $m1.M13);
		$this.t14.Init($t0, $t1, $m0.M14, $m1.M14);

		$this.t21.Init($t0, $t1, $m0.M21, $m1.M21);
		$this.t22.Init($t0, $t1, $m0.M22, $m1.M22);
		$this.t23.Init($t0, $t1, $m0.M23, $m1.M23);
		$this.t24.Init($t0, $t1, $m0.M24, $m1.M24);

		$this.t31.Init($t0, $t1, $m0.M31, $m1.M31);
		$this.t32.Init($t0, $t1, $m0.M32, $m1.M32);
		$this.t33.Init($t0, $t1, $m0.M33, $m1.M33);
		$this.t34.Init($t0, $t1, $m0.M34, $m1.M34);

		$this.t44.Init($t0, $t1, $m0.M44, $m1.M44);

		$this.ox.Init($t0, $t1, $m0.OffsetX, $m1.OffsetX);
		$this.oy.Init($t0, $t1, $m0.OffsetY, $m1.OffsetY);
		$this.oz.Init($t0, $t1, $m0.OffsetZ, $m1.OffsetZ);
	}

	[LinearTransform]$t11 = (new-object LinearTransform);
	[LinearTransform]$t12 = (new-object LinearTransform);
	[LinearTransform]$t13 = (new-object LinearTransform);
	[LinearTransform]$t14 = (new-object LinearTransform);

	[LinearTransform]$t21 = (new-object LinearTransform);
	[LinearTransform]$t22 = (new-object LinearTransform);
	[LinearTransform]$t23 = (new-object LinearTransform);
	[LinearTransform]$t24 = (new-object LinearTransform);

	[LinearTransform]$t31 = (new-object LinearTransform);
	[LinearTransform]$t32 = (new-object LinearTransform);
	[LinearTransform]$t33 = (new-object LinearTransform);
	[LinearTransform]$t34 = (new-object LinearTransform);

	[LinearTransform]$t44 = (new-object LinearTransform);

	[LinearTransform]$ox = (new-object LinearTransform);
	[LinearTransform]$oy = (new-object LinearTransform);
	[LinearTransform]$oz = (new-object LinearTransform);

	[System.Windows.Media.Media3D.Matrix3D]GetMatrix([double]$t)
	{
		[System.Windows.Media.Media3D.Matrix3D]$m = new-object System.Windows.Media.Media3D.Matrix3D;

		$m.M11 = $this.t11.Transform($t);
		$m.M12 = $this.t12.Transform($t);
		$m.M13 = $this.t13.Transform($t);
		$m.M14 = $this.t14.Transform($t);

		$m.M21 = $this.t21.Transform($t);
		$m.M22 = $this.t22.Transform($t);
		$m.M23 = $this.t23.Transform($t);
		$m.M24 = $this.t24.Transform($t);

		$m.M31 = $this.t31.Transform($t);
		$m.M32 = $this.t32.Transform($t);
		$m.M33 = $this.t33.Transform($t);
		$m.M34 = $this.t34.Transform($t);

		$m.M44 = $this.t44.Transform($t);

		$m.OffsetX = $this.ox.Transform($t);
		$m.OffsetY = $this.oy.Transform($t);
		$m.OffsetZ = $this.oz.Transform($t);

		return $m;
	}
}
