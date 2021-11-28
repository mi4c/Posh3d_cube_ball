Enum SphereDirection {
    Left
    Right
    Up
    Down
}

Enum SphereAction {
    Nothing
    Collision
    Drop
}

Class Sphere : System.ComponentModel.INotifyPropertyChanged{
    [System.Windows.Media.Media3D.Point3D]$origin
    [Double]$width
    [Double]$height
    [Double]$depth
    [Double]$beginAngle
    [Double]$endAngle
    [Double]$startX
    [Double]$startY
    [Double]$startZ
    [Double]$startradius
    [int]$startphi
    [int]$starttheta
    [Bool]$outofscope
#    [System.Windows.Media.Media3D.Vector3D]$axis
    [System.Windows.Media.Media3D.Model3DGroup]$SphereModelGroup
    [System.Windows.Media.Media3D.RotateTransform3D]$rotateTransformX
    [System.Windows.Media.Media3D.RotateTransform3D]$rotateTransformY
    [System.Windows.Media.Media3D.RotateTransform3D]$rotateTransformZ
    [System.Windows.Media.Media3D.TranslateTransform3D]$translateTransform
    [String]$Name
    [String]$Tag
    [System.Windows.Media.Media3D.Vector3D]$lookdirection

    [Void] add_PropertyChanged([System.ComponentModel.PropertyChangedEventHandler] $propertyChanged) {
        $this.PropertyChanged = [Delegate]::Combine($this.PropertyChanged, $propertyChanged)
    }

    [Void] remove_PropertyChanged([System.ComponentModel.PropertyChangedEventHandler] $propertyChanged) {
        $this.PropertyChanged = [Delegate]::Remove($this.PropertyChanged, $propertyChanged)
    }

    [Void] TriggerPropertyChanged([String]$propertyname){
        if($this.PropertyChanged -cne $null){
            $this.PropertyChanged.Invoke($this, (New-Object PropertyChangedEventArgs $propertyName))
        }
    }

    Sphere([System.Windows.Media.Media3D.Point3D]$P0,[Double]$w,[Double]$h,[Double]$d,[Double]$startX,[Double]$startY,[Double]$startZ){
        $this.width = $w
        $this.height = $h
        $this.depth = $d
        $this.origin = $P0
        $this.startX = $startX
        $this.startY = $startY
        $this.startZ = $startZ
    }
#    Sphere([Sphere]$sphere,[Double]$startX,[Double]$startY,[Double]$startZ,[Double]$radius,[Int]$num_phi, [Int]$num_theta, $imagefile,[Bool]$transparent,[String]$Name,$models,$Tag){
    Sphere([Sphere]$sphere,[System.Windows.Media.Media3D.Point3D]$startlocation,[Double]$radius,[Int]$num_phi, [Int]$num_theta, $imagefile,[Bool]$transparent,[String]$Name,$models,$Tag){
        $this.width = $sphere.width
        $this.height = $sphere.height
        $this.depth = $sphere.depth
        $this.SphereModelGroup = New-Object System.Windows.Media.Media3D.Model3DGroup
        $this.startX = $startlocation.X
        $this.startY = $startlocation.Y
        $this.startZ = $startlocation.Z
        $this.startradius = $radius
        $this.startphi = $num_phi
        $this.starttheta = $num_theta
        $this.name = $Name
        $this.tag = $Tag
        $this.Definemodel($imagefile,$transparent,$Name,$models,$Tag)
        $this.origin = $sphere.GetBoundsorigin()
        $this.addMotionTransforms()
    }
    

    [void]AddSphere([System.Windows.Media.Media3D.MeshGeometry3D]$mesh, [System.Windows.Media.Media3D.Point3D]$center, [double]$radius, [int]$num_phi, [int]$num_theta)
    {
        [Double]$dphi = ([Math]::PI / $num_phi);
        [Double]$dtheta = (2 * ([Math]::PI / $num_theta))
        [Double]$phi0 = 0;
        [Double]$y0 = ($radius * ([Math]::Cos($phi0)));
        [Double]$r0 = ($radius * ([Math]::Sin($phi0)));

        for ([Int]$i = 0; $i -lt $num_phi; $i++)
        {
            [Double]$phi1 = $phi0 + $dphi;
            [Double]$y1 = ($radius * ([Math]::Cos($phi1)));
            [Double]$r1 = ($radius * ([Math]::Sin($phi1)));
            # Po[Int]$ptAB has phi value A and theta value B.
            # For example, pt01 has phi = phi0 and theta = theta1.
            # Find the points with theta = theta0.
            [Double]$theta0 = 0;
            [System.Windows.Media.Media3D.Point3D]$pt00 = New-Object System.Windows.Media.Media3D.Point3D(
                ($center.X + ($r0 * [Math]::Cos($theta0))),
                ($center.Y + $y0),
                ($center.Z + ($r0 * ([Math]::Sin($theta0)))));
            [System.Windows.Media.Media3D.Point3D]$pt10 = New-Object System.Windows.Media.Media3D.Point3D(
                ($center.X + ($r1 * ([Math]::Cos($theta0)))),
                ($center.Y + $y1),
                ($center.Z + ($r1 * ([Math]::Sin($theta0)))));
            for ([Int]$j = 0; $j -lt $num_theta; $j++)
            {
                # Find the points with theta = theta1.
                [Double]$theta1 = $theta0 + $dtheta;
                [System.Windows.Media.Media3D.Point3D]$pt01 = New-Object System.Windows.Media.Media3D.Point3D(
                    ($center.X + ($r0 * [Math]::Cos($theta1))),
                    ($center.Y + $y0),
                    ($center.Z + ($r0 * [Math]::Sin($theta1))));
                [System.Windows.Media.Media3D.Point3D]$pt11 = New-Object System.Windows.Media.Media3D.Point3D(
                    ($center.X + ($r1 * [Math]::Cos($theta1))),
                    ($center.Y + $y1),
                    ($center.Z + ($r1 * [Math]::Sin($theta1))));
                # Create the triangles.
                [WpfTriangle]::addTriangleBallToMesh($mesh, $pt00, $pt11, $pt10);
                [WpfTriangle]::addTriangleBallToMesh($mesh, $pt00, $pt01, $pt11);
                # Move to the next value of theta.
                $theta0 = $theta1;
                $pt00 = $pt01;
                $pt10 = $pt11;
            }
            # Move to the next value of phi.
            $phi0 = $phi1;
            $y0 = $y1;
            $r0 = $r1;
        }
    }
    # Add a sphere.
    [void]AddSmoothSphere([System.Windows.Media.Media3D.MeshGeometry3D]$mesh, [System.Windows.Media.Media3D.Point3D]$center, [Double]$radius, [Int]$num_phi, [Int]$num_theta)
    {
        # Make a dictionary to track the sphere's points.
        $dict = @{}
        [Double]$dphi = ([Math]::PI / $num_phi);
        [Double]$dtheta = (2 * ([Math]::PI / $num_theta))
        [Double]$tphi0 = 0;
        [Double]$y0 = ($radius * ([Math]::Cos($tphi0)))
        [Double]$r0 = ($radius * ([Math]::Sin($tphi0)))
        for ([Int]$i = 0; i -lt $num_phi; $i++)
        {
            [Double]$phi1 = $tphi0 + $dphi;
            [Double]$y1 = ($radius * ([Math]::Cos($phi1)));
            [Double]$r1 = ($radius * ([Math]::Sin($phi1)));
            # Po[Int]$ptAB has phi value A and theta value B.
            # For example, pt01 has phi = phi0 and theta = theta1.
            # Find the points with theta = theta0.
            $theta0 = 0;
            [System.Windows.Media.Media3D.Point3D]$pt00 = New-Object System.Windows.Media.Media3D.Point3D(
                ($center.X + ($r0 * ([Math]::Cos($theta0)))),
                ($center.Y + $y0),
                ($center.Z + ($r0 * ([Math]::Sin($theta0)))));
            [System.Windows.Media.Media3D.Point3D]$pt10 = New-Object System.Windows.Media.Media3D.Point3D(
                $center.X + $r1 * [Math]::Cos($theta0),
                $center.Y + $y1,
                $center.Z + $r1 * [Math]::Sin($theta0));
            for ([Int]$j = 0; $j -lt $num_theta; $j++)
            {
                # Find the points with theta = theta1.
                [Double]$theta1 = $theta0 + $dtheta;
                [System.Windows.Media.Media3D.Point3D]$pt01 = New-Object System.Windows.Media.Media3D.Point3D(
                    ($center.X + ($r0 * ([Math]::Cos($theta1)))),
                    ($center.Y + $y0),
                    ($center.Z + ($r0 * ([Math]::Sin($theta1)))));
                [System.Windows.Media.Media3D.Point3D]$pt11 = New-Object System.Windows.Media.Media3D.Point3D(
                    ($center.X + ($r1 * ([Math]::Cos($theta1)))),
                    ($center.Y + $y1),
                    ($center.Z + ($r1 * ([Math]::Sin($theta1)))));

                # Create the triangles.
                [WpfTriangle]::AddSmoothTriangle($mesh, $dict, $pt00, $pt11, $pt10);
                [WpfTriangle]::AddSmoothTriangle($mesh, $dict, $pt00, $pt01, $pt11);

                # Move to the next value of theta.
                $theta0 = $theta1;
                $pt00 = $pt01;
                $pt10 = $pt11;
            }
            # Move to the next value of phi.
            $tphi0 = $phi1;
            $y0 = $y1;
            $r0 = $r1;
        }
    }
    # Make a sphere.
    Static MakeSphere([System.Windows.Media.Media3D.Model3DGroup]$model_group, [System.Windows.Media.Media3D.MeshGeometry3D]$sphere_mesh, [System.Windows.Media.Media3D.Material]$sphere_material,
        [Double]$radius, [Double]$cx, [Double]$cy, [Double]$cz, [Int]$num_phi, [Int]$num_theta, [System.Windows.Media.Media3D.Material]$globe_BackMaterial, [Bool]$transparent, [String]$Name,$models,[String]$Tag)
    {
        # Make the mesh if we must.
        if ($sphere_mesh -eq $null)
        {
            $sphere_mesh = New-Object System.Windows.Media.Media3D.MeshGeometry3D;
            $new_model = New-Object System.Windows.Media.Media3D.GeometryModel3D($sphere_mesh, $sphere_material);
            if($transparent){
                $new_model.BackMaterial = $globe_BackMaterial
            }
            $models.Add($new_model,@{Name = $Name; Tag = $Tag;})
            $model_group.Children.Add($new_model)
        }
        [Double]$dphi = ([Math]::PI / $num_phi);
        [Double]$dtheta = (2 * ([Math]::PI / $num_theta))
        # Remember the first point.
        [Int]$pt0 = $sphere_mesh.Positions.Count;
        # Make the points.
        [Double]$phi1 = ([Math]::PI / 2);
        for ([Int]$p = 0; $p -le $num_phi; $p++)
        {
            [Double]$r1 = ($radius * ([Math]::Cos($phi1)))
            [Double]$y1 = ($radius * ([Math]::Sin($phi1)))
            [Double]$theta = 0;
            for ([Int]$t = 0; $t -le $num_theta; $t++)
            {
                $sphere_mesh.Positions.Add(((New-Object System.Windows.Media.Media3D.Point3D(
                    ($cx + ($r1 * ([Math]::Cos($theta)))), ($cy + $y1), ($cz + (-($r1) * ([Math]::Sin($theta))))))))
                $sphere_mesh.TextureCoordinates.Add(
                    "$(([double]$t / $num_theta), ([double]$p / $num_phi))");
                $theta += $dtheta;
            }
            $phi1 -= $dphi;
        }
        # Make the triangles.
        for ([Int]$p = 0; $p -le $num_phi - 1; $p++)
        {
            $i1 = $p * ($num_theta + 1);
            $i2 = $i1 + ($num_theta + 1);
            for ([Int]$t = 0; $t -le $num_theta - 1; $t++)
            {
                $i3 = $i1 + 1;
                $i4 = $i2 + 1;
                $sphere_mesh.TriangleIndices.Add($pt0 + $i1);
                $sphere_mesh.TriangleIndices.Add($pt0 + $i2);
                $sphere_mesh.TriangleIndices.Add($pt0 + $i4);
                $sphere_mesh.TriangleIndices.Add($pt0 + $i1);
                $sphere_mesh.TriangleIndices.Add($pt0 + $i4);
                $sphere_mesh.TriangleIndices.Add($pt0 + $i3);
                $i1 += 1;
                $i2 += 1;
            }
        }
    }

    [System.Windows.Media.Media3D.Model3DGroup]getModelGroup()
    {
        return $this.SphereModelGroup;
    }

    [System.Windows.Media.Media3D.RotateTransform3D]getRotateTransform()
    {
        return $this.rotateTransform;
    }

    [System.Windows.Media.Media3D.TranslateTransform3D]getTranslateTransform()
    {
        return [System.Windows.Media.Media3D.TranslateTransform3D]$this.translateTransform;
    }

    [System.Windows.Media.Media3D.Point3D]getModelPlace()
    {
        [System.Windows.Media.Media3D.Point3D]$p = New-Object System.Windows.Media.Media3D.Point3D((-(([Sphere]::getWidth()) / 2)), ([Sphere]::getHeight()), (-($this.depth) / 2));
        return $p;
    }

    static [double]getHeight()
    {
        return ([Scene]::sceneSize / 3);
    }

    static [double]getWidth()
    {
        return (([Sphere]::getHeight() * 2) / 8);  # based on body width = 3 head widths
    }

    [System.Windows.Media.Media3D.Point3D]clonePoint([System.Windows.Media.Media3D.Point3D]$p)
    {
        return (New-Object System.Windows.Media.Media3D.Point3D($p.X, $p.Y, $p.Z))
    }

    # Add the model to the Model3DGroup.
    DefineModel($imagefile,[Bool]$transparent,[String]$Name,$models,[String]$Tag)
    {
        # Globe. Place it in a new model so we can transform it.
        [System.Windows.Media.Media3D.Model3DGroup]$globe_model = New-Object System.Windows.Media.Media3D.Model3DGroup
        $this.SphereModelGroup.Children.Add($globe_model);
        
        $uri = New-Object System.Uri("$PSScriptRoot\..\Files\$imagefile")
        $imagesource = New-Object System.Windows.Media.Imaging.BitmapImage $uri
        if($transparent){
            $globe_brush = New-Object System.Windows.Media.ImageBrush -Property @{ImageSource = $imagesource; Opacity = 0.5}
        } else {
            $globe_brush = New-Object System.Windows.Media.ImageBrush $imagesource
        }
        $globe_material = New-Object System.Windows.Media.Media3D.DiffuseMaterial -Property @{Brush = $globe_brush}
        $globe_BackMaterial = $globe_material
        
        [System.Windows.Media.Media3D.MeshGeometry3D]$globe_mesh = $null;
        [Sphere]::MakeSphere($globe_model, ($globe_mesh), $globe_material, $this.startradius, $($this.startX),$($this.startY),$($this.startZ), $this.startphi, $this.starttheta,$globe_BackMaterial,$transparent,[String]$Name,$models,[String]$Tag);
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

    [System.Windows.Media.Media3D.Point3D]centerBottom(){
        [System.Windows.Media.Media3D.Point3D]$c = New-Object System.Windows.Media.Media3D.Point3D -ArgumentList(($this.origin.X + ($this.width / 2)),($this.origin.Y + $this.height),($this.origin.Z + ($this.depth / 2)));
        return $c;
    }
    [System.Windows.Media.Media3D.Point3D]center(){
        [System.Windows.Media.Media3D.Point3D]$c = New-Object System.Windows.Media.Media3D.Point3D -ArgumentList(($this.origin.X + ($this.width / 2)),($this.origin.Y - ($this.height / 2)),($this.origin.Z + ($this.depth / 2)));
        return $c;
    }
    [System.Windows.Media.Media3D.Point3D]getCenter()
    {
        [System.Windows.Media.Media3D.Point3D]$center = New-Object System.Windows.Media.Media3D.Point3D(($this.origin.X + ($this.width / 2)), $this.origin.Y, ($this.origin.Z + ($this.depth / 2)));
        return $center;
    }
    [System.Windows.Media.Media3D.Point3D]centerTop(){
        [System.Windows.Media.Media3D.Point3D]$c = New-Object System.Windows.Media.Media3D.Point3D -ArgumentList(($this.origin.X + ($this.width / 2)),($this.origin.Y),($this.origin.Z + ($this.depth / 2)));
        return $c;
    }
    [System.Windows.Media.Media3D.Point3D]GetOrigin(){
        [System.Windows.Media.Media3D.Point3D]$c = "$($this.origin.X),$($this.origin.Y),$($this.origin.Z)";
        return $c;
    }

    [System.Windows.Media.Media3D.Point3D]GetBoundsorigin(){
        # Otetaan bounds sijainti ja lis‰t‰‰n vastaava koko puolikkaana tilalle, jotta saadaan origini tiet‰‰
        $cx = ($this.SphereModelGroup.bounds.X + ($this.SphereModelGroup.Bounds.SizeX /2))
        $cy = ($this.SphereModelGroup.bounds.Y + ($this.SphereModelGroup.Bounds.SizeY /2))
        $cz = ($this.SphereModelGroup.bounds.Z + ($this.SphereModelGroup.Bounds.SizeZ /2))
        $this.origin = "$($cx), $($cy), $($cz)"
        $coords = "$($cx), $($cy), $($cz)"
        [System.Windows.Media.Media3D.Point3D]$c = "$coords";
        return $c;
    }


	[Void]OnNewTransform([Sphere]$sender, [System.Windows.DependencyPropertyChangedEventArgs]$e)
	{
		[Sphere]$obj = $sender -as [Sphere];
		$obj.NewTransform();
	}

	#endregion DependencyProperties

	[void]NewTransform(){
		[System.Windows.Media.Media3D.Matrix3D]$m = New-Object System.Windows.Media.Media3D.Matrix3D
		#$m.Scale(new-object System.Windows.Media.Media3D.Vector3D("$($this.ScaleX), $($this.ScaleY), $($this.ScaleZ)"));
        if($this.Rotation1){
    		$m.Rotate($this.Rotation1);
        }
        if($this.Rotation2){
		    $m.Rotate($this.Rotation2);
        }
        if($this.position){
		    $m.Translate((new-object System.Windows.Media.Media3D.Vector3D($this.Position.X, $this.Position.Y, $this.Position.Z)));
        }
        if($this.Rotation3){
		    $m.Rotate($this.Rotation3);
        }
		$this.SphereModelGroup.Transform = New-Object System.Windows.Media.Media3D.MatrixTransform3D($m);        
	}

    [System.Windows.Media.Media3D.Vector3D]LeftDirection($camera){
        Try{
            $result = [System.Windows.Media.Media3D.Vector3D]::CrossProduct($camera.UpDirection(),($camera.LookDirection()))
        } Catch {
            $result = "Error"
        }
        Return $result
    }

    [System.Windows.Media.Media3D.Point3D]Position(){
        Return $this.GetOrigin()
    }

    [System.Windows.Media.Media3D.Point3D]Position($PositionProperty,$value){
        Return ($this.PositionProperty($PositionProperty,$value))
    }

    [void]addMotionTransforms()
    {
        [System.Windows.Media.Media3D.Transform3DGroup]$group = New-Object System.Windows.Media.Media3D.Transform3DGroup
        [System.Windows.Media.Media3D.Vector3D]$vectorX = New-Object System.Windows.Media.Media3D.Vector3D(1, 0, 0);
        [System.Windows.Media.Media3D.AxisAngleRotation3D]$rotationX = New-Object System.Windows.Media.Media3D.AxisAngleRotation3D($vectorX, 0.0);
        $this.rotateTransformX = New-Object System.Windows.Media.Media3D.RotateTransform3D($rotationX, ($this.GetBoundsorigin()));
        $group.Children.Add($this.rotateTransformX)
        #$this.addTransform($this.SphereModelGroup, $this.rotateTransformX);
        [System.Windows.Media.Media3D.Vector3D]$vectorY = New-Object System.Windows.Media.Media3D.Vector3D(0, 1, 0);
        [System.Windows.Media.Media3D.AxisAngleRotation3D]$rotationY = New-Object System.Windows.Media.Media3D.AxisAngleRotation3D($vectorY, 0.0);
        $this.rotateTransformY = New-Object System.Windows.Media.Media3D.RotateTransform3D($rotationY, ($this.GetBoundsorigin()));
        $group.Children.Add($this.rotateTransformY)
        #$this.addTransform($this.SphereModelGroup, $this.rotateTransformY);
        [System.Windows.Media.Media3D.Vector3D]$vectorZ = New-Object System.Windows.Media.Media3D.Vector3D(0, 0, 1);
        [System.Windows.Media.Media3D.AxisAngleRotation3D]$rotationZ = New-Object System.Windows.Media.Media3D.AxisAngleRotation3D($vectorZ, 0.0);
        $this.rotateTransformZ = New-Object System.Windows.Media.Media3D.RotateTransform3D($rotationZ, ($this.GetBoundsorigin()));
        $group.Children.Add($this.rotateTransformZ)
        #$this.addTransform($this.SphereModelGroup, $this.rotateTransformZ);
        $this.translateTransform = New-Object System.Windows.Media.Media3D.TranslateTransform3D(0, 0, 0);
        $group.Children.Add($this.translateTransform)
        $this.addTransform($this.SphereModelGroup, $group);
    }
    [void]addTransform([System.Windows.Media.Media3D.Model3DGroup]$model, [System.Windows.Media.Media3D.Transform3D]$transform)
    {
        [System.Windows.Media.Media3D.Transform3DGroup]$group = New-Object System.Windows.Media.Media3D.Transform3DGroup
        if ($model.Transform -ne $null -and $model.Transform -ne [System.Windows.Media.Media3D.Transform3D]::Identity)
        {
            if ($model.Transform -is [System.Windows.Media.Media3D.Transform3D])
            {
                $group.Children.Add($model.Transform);
            }
            elseif ($model.Transform -is [System.Windows.Media.Media3D.Transform3DGroup])
            {
                # T‰t‰ tarvitaan, jos tehd‰‰n esim. pallolle animoidut k‰det :D, ent‰ jalat? - ei palloilla ole jalkoja dummy...
                [System.Windows.Media.Media3D.Transform3DGroup]$g = $this.SphereModelGroup($model.Transform)
                foreach ($t in $g.Children)
                {
                    $group.Children.Add($t);
                }
            }
        }
        $group.Children.Add($transform);
        $group.Children.Add((New-Object System.Windows.Media.Media3D.TranslateTransform3D))
        $model.Transform = $group;
    }

	[void]RotateX([double]$angle){
        $this.SphereModelGroup.Transform.children.children[1].rotation.angle += $angle
	}

	[void]RotateY([double]$angle){
        $this.SphereModelGroup.Transform.children.children[2].rotation.angle += $angle
	}

    [Void]Move([System.Windows.Media.Media3D.Vector3D]$direction, [double]$amount){
            $newTransform = (New-Object System.Windows.Media.Media3D.TranslateTransform3D(($direction*$amount)))
            $this.translateTransform.OffsetX += $newTransform.OffsetX
            $this.translateTransform.OffsetY += $newTransform.OffsetY
            $this.translateTransform.OffsetZ += $newTransform.OffsetZ
    }

    [Void]Jump([System.Windows.Media.Media3D.Vector3D]$direction, [double]$amount){
            #$newTransform = (New-Object System.Windows.Media.Media3D.TranslateTransform3D(($direction*$amount)))
            $this.translateTransform.OffsetX += $direction.X*$amount
            $this.translateTransform.OffsetY += $direction.Y*$amount
            $this.translateTransform.OffsetZ += $direction.Z*$amount
    }

    [Void]Crouch([System.Windows.Media.Media3D.Vector3D]$direction, [double]$amount){
            #$newTransform = (New-Object System.Windows.Media.Media3D.TranslateTransform3D(($direction*$amount)))
            $this.translateTransform.OffsetX += $direction.X*$amount
            $this.translateTransform.OffsetY += $direction.Y*$amount
            $this.translateTransform.OffsetZ += $direction.Z*$amount
    }

    [SphereAction]Intersect($sphere,$myobject){
        if($myobject.startradius){
            $x = [Math]::Max($myobject.GetBoundsOrigin().X, [Math]::Min($sphere.GetBoundsOrigin().x, $myobject.GetBoundsOrigin().X))
            $y = [Math]::Max($myobject.GetBoundsOrigin().Y, [Math]::Min($sphere.GetBoundsOrigin().y, $myobject.GetBoundsOrigin().Y))
            $z = [Math]::Max($myobject.GetBoundsOrigin().Z, [Math]::Min($sphere.GetBoundsOrigin().z, $myobject.GetBoundsOrigin().Z))
            $distance = [Math]::Sqrt(($x - $sphere.GetBoundsOrigin().x) * ($x - $sphere.GetBoundsOrigin().x) +
                                        ($y - $sphere.GetBoundsOrigin().y) * ($y - $sphere.GetBoundsOrigin().y) +
                                        ($z - $sphere.GetBoundsOrigin().z) * ($z - $sphere.GetBoundsOrigin().z))
        } else {
            $cx = $myobject.bounds.X + ($myobject.bounds.SizeX /2)
            $cy = $myobject.bounds.Y + ($myobject.bounds.SizeY /2)
            $cZ = $myobject.bounds.Z + ($myobject.bounds.SizeZ /2)

            $x = [Math]::Max(($cx), [Math]::Min($sphere.GetBoundsOrigin().x, ($cx)))
            $y = [Math]::Max(($cy), [Math]::Min($sphere.GetBoundsOrigin().y, ($cy)))
            $z = [Math]::Max(($cz), [Math]::Min($sphere.GetBoundsOrigin().z, ($cz)))
            $distance = [Math]::Sqrt(($x - $sphere.GetBoundsOrigin().x) * ($x - $sphere.GetBoundsOrigin().x) +
                                        ($y - $sphere.GetBoundsOrigin().y) * ($y - $sphere.GetBoundsOrigin().y) +
                                        ($z - $sphere.GetBoundsOrigin().z) * ($z - $sphere.GetBoundsOrigin().z))
        }

        if($distance -le ($sphere.startradius + ($myobject.bounds.SizeX /2))){
                if((($sphere.GetBoundsOrigin().X + $this.width*4) -ge $myobject.bounds.X) -and (($sphere.GetBoundsOrigin().X - $this.width*4) -le ($myobject.bounds.X + $myobject.bounds.SizeX)) -and
                    (($sphere.GetBoundsOrigin().Y + $this.height *4) -ge $myobject.bounds.Y) -and (($sphere.GetBoundsOrigin().Y - ($this.height*4)) -le ($myobject.bounds.Y + $myobject.bounds.SizeY)) -and
                    (($sphere.GetBoundsOrigin().Z + $this.width*4) -ge $myobject.bounds.Z) -and (($sphere.GetBoundsOrigin().Z - ($this.width*4)) -le ($myobject.bounds.Z + $myobject.bounds.SizeZ))
                ){
                    Return [SphereAction]::Collision
                } else {
                    if((($sphere.GetBoundsOrigin().X + $this.width*4) -ge $myobject.bounds.X) -and (($sphere.GetBoundsOrigin().X - $this.width*4) -le ($myobject.bounds.X + $myobject.bounds.SizeX)) -and
                        (($sphere.GetBoundsOrigin().Z + $this.width*4) -ge $myobject.bounds.Z) -and (($sphere.GetBoundsOrigin().Z - ($this.width*4)) -le ($myobject.bounds.Z + $myobject.bounds.SizeZ))
                    ){
                        Return [SphereAction]::Nothing
                    } else {
                        Return [SphereAction]::Drop
                    }
                }
        }
        elseif($myobject.startradius){
            if($distance -lt (($sphere.startradius) + ($myobject.startradius))){
                Return [SphereAction]::Collision
            } else {
                Return [SphereAction]::Nothing
            }
        } 
        else {
            if((($sphere.GetBoundsOrigin().X + $this.width*4) -ge $myobject.bounds.X) -and (($sphere.GetBoundsOrigin().X - $this.width*4) -le ($myobject.bounds.X + $myobject.bounds.SizeX)) -and
                (($sphere.GetBoundsOrigin().Y + $this.height *4) -ge $myobject.bounds.Y) -and (($sphere.GetBoundsOrigin().Y - ($this.height*4)) -le ($myobject.bounds.Y + $myobject.bounds.SizeY)) -and
                (($sphere.GetBoundsOrigin().Z + $this.width*4) -ge $myobject.bounds.Z) -and (($sphere.GetBoundsOrigin().Z - ($this.width*4)) -le ($myobject.bounds.Z + $myobject.bounds.SizeZ))
            ){
                Return [SphereAction]::Collision
            } else {
                if((($sphere.GetBoundsOrigin().X + $this.width*4) -ge $myobject.bounds.X) -and (($sphere.GetBoundsOrigin().X - $this.width*4) -le ($myobject.bounds.X + $myobject.bounds.SizeX)) -and
                    (($sphere.GetBoundsOrigin().Z + $this.width*4) -ge $myobject.bounds.Z) -and (($sphere.GetBoundsOrigin().Z - ($this.width*4)) -le ($myobject.bounds.Z + $myobject.bounds.SizeZ))
                ){
                    Return [SphereAction]::Nothing
                } else {
                    Return [SphereAction]::Drop
                }
            }
        }
    }
    [Void]Storyboard($namespace,$MoveTransformString,$action,$toX,$toY,$toZ,$duration){
        [double]$Totalduration = 0.0

        $newX = $this.translateTransform.OffsetX + $toX
        $newY = $this.translateTransform.OffsetY + $toY
        $newZ = $this.translateTransform.OffsetZ + $toZ

        $storyboard = New-Object System.Windows.Media.Animation.StoryBoard
        $doubleAnimationX1 = New-Object System.Windows.Media.Animation.DoubleAnimation($this.SphereModelGroup.Transform.children.children[3].OffsetX, $newX, ($this.durationTS($duration)))
        $doubleAnimationY1 = New-Object System.Windows.Media.Animation.DoubleAnimation($this.SphereModelGroup.Transform.children.children[3].OffsetY, $newY, ($this.durationTS($duration)))
        $doubleAnimationZ1 = New-Object System.Windows.Media.Animation.DoubleAnimation($this.SphereModelGroup.Transform.children.children[3].OffsetZ, $newZ, ($this.durationTS($duration)))
        $OffsetXProperty = New-Object System.Windows.Media.Media3D.TranslateTransform3D
        $OffsetYProperty = New-Object System.Windows.Media.Media3D.TranslateTransform3D
        $OffsetZProperty = New-Object System.Windows.Media.Media3D.TranslateTransform3D
        
        [double]$offset = [Scene]::sceneSize * 0.45

        $storyboard::SetTargetName($doubleAnimationX1,$MoveTransformString)
        $storyboard::SetTargetProperty($doubleAnimationX1, (New-Object System.Windows.PropertyPath($OffsetXProperty::OffsetXProperty)))
        $storyboard::SetTargetName($doubleAnimationY1,$MoveTransformString)
        $storyboard::SetTargetProperty($doubleAnimationY1, (New-Object System.Windows.PropertyPath($OffsetYProperty::OffsetYProperty)))
        $storyboard::SetTargetName($doubleAnimationZ1,$MoveTransformString)
        $storyboard::SetTargetProperty($doubleAnimationZ1, (New-Object System.Windows.PropertyPath($OffsetZProperty::OffsetZProperty)))
        $storyboard.Children.Add($doubleAnimationY1)
        $doubleAnimationY1.BeginTime = ($this.durationTS($totalDuration))

        if($action -eq 'Jump'){
            $doubleAnimationX2 = New-Object System.Windows.Media.Animation.DoubleAnimation($newX, $this.translateTransform.OffsetX, ($this.durationTS($duration)))
            $doubleAnimationY2 = New-Object System.Windows.Media.Animation.DoubleAnimation($newY, $this.translateTransform.OffsetY, ($this.durationTS($duration)))
            $doubleAnimationZ2 = New-Object System.Windows.Media.Animation.DoubleAnimation($newZ, $this.translateTransform.OffsetZ, ($this.durationTS($duration)))
            $storyboard::SetTargetName($doubleAnimationX2,$MoveTransformString)
            $storyboard::SetTargetProperty($doubleAnimationX2, (New-Object System.Windows.PropertyPath($OffsetXProperty::OffsetXProperty)))
            $storyboard::SetTargetName($doubleAnimationY2,$MoveTransformString)
            $storyboard::SetTargetProperty($doubleAnimationY2, (New-Object System.Windows.PropertyPath($OffsetYProperty::OffsetYProperty)))
            $storyboard::SetTargetName($doubleAnimationZ2,$MoveTransformString)
            $storyboard::SetTargetProperty($doubleAnimationZ2, (New-Object System.Windows.PropertyPath($OffsetZProperty::OffsetZProperty)))
            $storyboard.Children.Add($doubleAnimationX2)
            $storyboard.Children.Add($doubleAnimationY2)
            $storyboard.Children.Add($doubleAnimationZ2)
            $doubleAnimationX2.BeginTime = ($this.durationTS($duration))
            $doubleAnimationY2.BeginTime = ($this.durationTS($duration))
            $doubleAnimationZ2.BeginTime = ($this.durationTS($duration))
        }

        $Storyboard.RepeatBehavior = "1x"
        $storyboard.Begin($namespace)
    }
}

