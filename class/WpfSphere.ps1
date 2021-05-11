Enum SphereDirection {
    Left
    Right
    Up
    Down
}

Enum SphereAction {
    Nothing
    Collision
}

Class Sphere{
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
    [System.Windows.Media.Media3D.Vector3D]$axis
    [System.Windows.Media.Media3D.RotateTransform3D]$rotateTransform
    [System.Windows.Media.Media3D.TranslateTransform3D]$translateTransform
    [System.Windows.Media.Media3D.Model3DGroup]$SphereModelGroup
    [String]$Name

    

    Sphere([System.Windows.Media.Media3D.Point3D]$P0,[Double]$w,[Double]$h,[Double]$d,[Double]$startX,[Double]$startY,[Double]$startZ){
        $this.width = $w
        $this.height = $h
        $this.depth = $d
        $this.origin = $P0
        $this.startX = $startX
        $this.startY = $startY
        $this.startZ = $startZ
    }
    Sphere([Sphere]$sphere,[Double]$startX,[Double]$startY,[Double]$startZ,[Double]$radius,[Int]$num_phi, [Int]$num_theta, $imagefile,[Bool]$transparent,[String]$Name,$models){
        $this.width = $sphere.width
        $this.height = $sphere.height
        $this.depth = $sphere.depth
        $this.SphereModelGroup = New-Object System.Windows.Media.Media3D.Model3DGroup
        $this.startX = $startX
        $this.startY = $startY
        $this.startZ = $startZ
        $this.startradius = $radius
        $this.startphi = $num_phi
        $this.starttheta = $num_theta
        $this.name = $Name
        $this.Definemodel($imagefile,$transparent,$Name,$models)
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
#    static MakeSphere([System.Windows.Media.Media3D.MeshGeometry3D]$sphere_mesh, [System.Windows.Media.Media3D.Material]$sphere_material,
    Static MakeSphere([System.Windows.Media.Media3D.Model3DGroup]$model_group, [System.Windows.Media.Media3D.MeshGeometry3D]$sphere_mesh, [System.Windows.Media.Media3D.Material]$sphere_material,
        [Double]$radius, [Double]$cx, [Double]$cy, [Double]$cz, [Int]$num_phi, [Int]$num_theta, [System.Windows.Media.Media3D.Material]$globe_BackMaterial, [Bool]$transparent, [String]$Name,$models)
    {
        # Make the mesh if we must.
        if ($sphere_mesh -eq $null)
        {
            $sphere_mesh = New-Object System.Windows.Media.Media3D.MeshGeometry3D;
            $new_model = New-Object System.Windows.Media.Media3D.GeometryModel3D($sphere_mesh, $sphere_material);
            if($transparent){
                $new_model.BackMaterial = $globe_BackMaterial
            }
            $models.Add($new_model,$Name)
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
    DefineModel($imagefile,[Bool]$transparent,[String]$Name,$models)
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
        [Sphere]::MakeSphere($globe_model, ($globe_mesh), $globe_material, $this.startradius, $($this.startX),$($this.startY),$($this.startZ), $this.startphi, $this.starttheta,$globe_BackMaterial,$transparent,[String]$Name,$models);
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

    [void]addMotionTransforms()
    {
        [System.Windows.Media.Media3D.Vector3D]$vector = New-Object System.Windows.Media.Media3D.Vector3D(0, 1, 0);
        [System.Windows.Media.Media3D.AxisAngleRotation3D]$rotation = New-Object System.Windows.Media.Media3D.AxisAngleRotation3D($vector, 0.0);
        $this.rotateTransform = New-Object System.Windows.Media.Media3D.RotateTransform3D($rotation, ($this.GetBoundsorigin()));
        $this.addTransform($this.SphereModelGroup, $this.rotateTransform);
        $this.translateTransform = New-Object System.Windows.Media.Media3D.TranslateTransform3D(0, 0, 0);
        $this.addTransform($this.SphereModelGroup, $this.translateTransform);
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
                # this will be needed if I create ball some animated hands, or eyes etc...
                [System.Windows.Media.Media3D.Transform3DGroup]$g = $this.SphereModelGroup($model.Transform)
                foreach ($t in $g.Children)
                {
                    $group.Children.Add($t);
                }
            }
        }
        $group.Children.Add($transform);
        $model.Transform = $group;
    }

	[void]Rotate([System.Windows.Media.Media3D.Vector3D]$axis, [double]$angle){
        $rotation = New-Object System.Windows.Media.Media3D.AxisAngleRotation3D($axis, $angle);
        $this.rotateTransform = New-Object System.Windows.Media.Media3D.RotateTransform3D($($rotation), ($this.GetBoundsorigin()));
        $this.addTransform($this.SphereModelGroup, $this.rotateTransform)
	}
    [Void]Move([System.Windows.Media.Media3D.Vector3D]$direction, [double]$amount){
        $this.translateTransform = New-Object System.Windows.Media.Media3D.TranslateTransform3D(($direction*$amount))
        $this.addTransform($this.SphereModelGroup, $this.translateTransform)
    }
}

