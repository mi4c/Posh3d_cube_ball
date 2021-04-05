Class Sphere{
    [System.Windows.Media.Media3D.Point3D]$origin
    [Double]$width
    [Double]$height
    [Double]$depth
    [System.Windows.Media.Media3D.Point3D]centerBottom(){
        [System.Windows.Media.Media3D.Point3D]$c = New-Object System.Windows.Media.Media3D.Point3D -ArgumentList(($this.origin.X + ($this.width / 2)),($this.origin.Y + $this.height),($this.origin.Z + ($this.depth / 2)));
        return $c;
    }
    [System.Windows.Media.Media3D.Point3D]center(){
        [System.Windows.Media.Media3D.Point3D]$c = New-Object System.Windows.Media.Media3D.Point3D -ArgumentList(($this.origin.X + ($this.width / 2)),($this.origin.Y - ($this.height / 2)),($this.origin.Z + ($this.depth / 2)));
        return $c;
    }
    [System.Windows.Media.Media3D.Point3D]centerTop(){
        [System.Windows.Media.Media3D.Point3D]$c = New-Object System.Windows.Media.Media3D.Point3D -ArgumentList(($this.origin.X + ($this.width / 2)),($this.origin.Y),($this.origin.Z + ($this.depth / 2)));
        return $c;
    }
    WpfSphere([System.Windows.Media.Media3D.Point3D]$P0,[Double]$w,[Double]$h,[Double]$d){
        $this.width = $w
        $this.height = $h
        $this.depth = $d
        $this.origin = $P0
    }
    WpfSphere([Sphere]$sphere){
        $this.width = $sphere.width
        $this.height = $sphere.height
        $this.depth = $sphere.depth
        $this.origin = New-Object System.Windows.Media.Media3D.Point3D -ArgumentList ($sphere.origin.X, $sphere.origin.Y, $sphere.origin.Z)
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
#    Static MakeSphere([System.Windows.Media.Media3D.Model3DGroup]$model_group, [System.Windows.Media.Media3D.MeshGeometry3D]$sphere_mesh, [System.Windows.Media.Media3D.Material]$sphere_material,
    static MakeSphere([System.Windows.Media.Media3D.MeshGeometry3D]$sphere_mesh, [System.Windows.Media.Media3D.Material]$sphere_material,
        [Double]$radius, [Double]$cx, [Double]$cy, [Double]$cz, [Int]$num_phi, [Int]$num_theta)
    {
        # Make the mesh if we must.
        if ($sphere_mesh -eq $null)
        {
            $sphere_mesh = New-Object System.Windows.Media.Media3D.MeshGeometry3D;
            $new_model = New-Object System.Windows.Media.Media3D.GeometryModel3D($sphere_mesh, $sphere_material);
#            $model_group.Children.Add($new_model)
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
    # Add the model to the Model3DGroup.
    Static DefineModel([System.Windows.Media.Media3D.Model3DGroup]$model_group)
    {
        # Globe. Place it in a new model so we can transform it.
        [System.Windows.Media.Media3D.Model3DGroup]$globe_model = New-Object System.Windows.Media.Media3D.Model3DGroup
        $model_group.Children.Add($globe_model);
        
        $uri = New-Object System.Uri("$PSScriptRoot\..\Files\face.jpg")
        $imagesource = New-Object System.Windows.Media.Imaging.BitmapImage $uri
        $globe_brush = New-Object System.Windows.Media.ImageBrush $imagesource
        $globe_material = New-Object System.Windows.Media.Media3D.DiffuseMaterial -Property @{Brush = $globe_brush}
        [System.Windows.Media.Media3D.MeshGeometry3D]$globe_mesh = $null;
        [Sphere]::MakeSphere($globe_model, $globe_mesh, $globe_material, 1, -9.2, 0.6, 9.2, 20, 30);
    }
    
    [System.Windows.Media.Media3D.GeometryModel3D]CreateModel()
    {
        return [Sphere]::CreateSphereModel($this.origin, $this.width, $this.height, $this.depth);
    }
    static [System.Windows.Media.Media3D.GeometryModel3D]CreateSphereModel([System.Windows.Media.Media3D.Point3D]$p0, [double]$w, [double]$h, [double]$d)
    {
        $mesh = New-Object System.Windows.Media.Media3D.MeshGeometry3D
        $uri = New-Object System.Uri("$PSScriptRoot\..\Files\face.jpg")
        $imagesource = New-Object System.Windows.Media.Imaging.BitmapImage $uri
        $globe_brush = New-Object System.Windows.Media.ImageBrush $imagesource
        $globe_material = New-Object System.Windows.Media.Media3D.DiffuseMaterial -Property @{Brush = $globe_brush}
        $model = New-Object System.Windows.Media.Media3D.GeometryModel3D -ArgumentList $mesh, $globe_material
        [Sphere]::MakeSphere($mesh, $globe_material, 1, -9.2, 0.6, 9.2, 20, 30);
        return $model;
    }
}

#$a = [Sphere]::new()
#$a.CreateModel()

