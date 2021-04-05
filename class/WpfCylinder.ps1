Class WpfCylinder
{
    [void]AddCylinder([System.Windows.Media.Media3D.MeshGeometry3D]$mesh, [System.Windows.Media.Media3D.Point3D]$end_point, [System.Windows.Media.Media3D.Vector3D]$axis, [double]$radius, [int]$num_sides)
    {
        # Get two vectors perpendicular to the axis.
        if (($axis.Z -lt -0.01) -or ($axis.Z -gt 0.01)){
            $v1 = New-Object System.Windows.Media.Media3D.Vector3D($axis.Z, $axis.Z, (-($axis.X) - $axis.Y))
        } else {
            $v1 = New-Object System.Windows.Media.Media3D.Vector3D((-($axis.Y) - $axis.Z), $axis.X, $axis.X);
        }
        [System.Windows.Media.Media3D.Vector3D]$v2 = [System.Windows.Media.Media3D.Vector3D]::CrossProduct($v1, $axis);

        # Make the vectors have length radius.
        $v1 *= ($radius / $v1.Length);
        $v2 *= ($radius / $v2.Length);

        # Make the top end cap.
        [double]$theta = 0;
        [double]$dtheta = (2 * ([Math]::PI / $num_sides));
        for ([int]$i = 0; $i -lt $num_sides; $i++)
        {
            [System.Windows.Media.Media3D.Point3D]$p1 = ($end_point +
                ([Math]::Cos($theta) * $v1) +
                ([Math]::Sin($theta) * $v2));
            $theta += $dtheta;
            [System.Windows.Media.Media3D.Point3D]$p2 = ($end_point +
                ([Math]::Cos($theta) * $v1) +
                ([Math]::Sin($theta) * $v2));
            [WpfTriangle]::addTriangleBallToMesh($mesh, $end_point, $p1, $p2);
        }

        # Make the bottom end cap.
        [System.Windows.Media.Media3D.Point3D]$end_point2 = $end_point + $axis;
        $theta = 0;
        for ([int]$i = 0; $i -lt $num_sides; $i++)
        {
            [System.Windows.Media.Media3D.Point3D]$p1 = ($end_point2 +
                ([Math]::Cos($theta) * $v1) +
                ([Math]::Sin($theta) * $v2));
            $theta += $dtheta;
            [System.Windows.Media.Media3D.Point3D]$p2 = ($end_point2 +
                ([Math]::Cos($theta) * $v1) +
                ([Math]::Sin($theta) * $v2));
            [WpfTriangle]::addTriangleBallToMesh($mesh, $end_point2, $p2, $p1);
        }

        # Make the sides.
        $theta = 0;
        for ([int]$i = 0; $i -lt $num_sides; $i++)
        {
            [System.Windows.Media.Media3D.Point3D]$p1 = ($end_point +
                ([Math]::Cos($theta) * $v1) +
                ([Math]::Sin($theta) * $v2));
            $theta += $dtheta;
            [System.Windows.Media.Media3D.Point3D]$p2 = ($end_point +
                ([Math]::Cos($theta) * $v1) +
                ([Math]::Sin($theta) * $v2));

            [System.Windows.Media.Media3D.Point3D]$p3 = ($p1 + $axis);
            [System.Windows.Media.Media3D.Point3D]$p4 = ($p2 + $axis);

            [WpfTriangle]::addTriangleBallToMesh($mesh, $p1, $p3, $p2);
            [WpfTriangle]::addTriangleBallToMesh($mesh, $p2, $p3, $p4);
        }
    }

    # Add a cylinder with smooth sides.
    [void]AddSmoothCylinder([System.Windows.Media.Media3D.MeshGeometry3D]$mesh, [System.Windows.Media.Media3D.Point3D]$end_point, [System.Windows.Media.Media3D.Vector3D]$axis, [double]$radius, [int]$num_sides)
    {
        # Get two vectors perpendicular to the axis.
        if (($axis.Z -lt -0.01) -or ($axis.Z -gt 0.01)){
            $v1 = New-Object System.Windows.Media.Media3D.Vector3D($axis.Z, $axis.Z, (-($axis.X) - $axis.Y))
        } else {
            $v1 = New-Object System.Windows.Media.Media3D.Vector3D((-($axis.Y) - $axis.Z), $axis.X, $axis.X);
        }
        [System.Windows.Media.Media3D.Vector3D]$v2 = [System.Windows.Media.Media3D.Vector3D]::CrossProduct($v1, $axis);

        # Make the vectors have length radius.
        $v1 *= ($radius / $v1.Length);
        $v2 *= ($radius / $v2.Length);

        # Make the top end cap.
        # Make the end point.
        [int]$pt0 = $mesh.Positions.Count; # Index of end_point.
        $mesh.Positions.Add($end_point);

        # Make the top points.
        [double]$theta = 0;
        [double]$dtheta = (2 * ([Math]::PI / $num_sides))
        for ([int]$i = 0; $i -lt $num_sides; $i++)
        {
            $mesh.Positions.Add(($end_point +
                ([Math]::Cos($theta) * $v1) +
                ([Math]::Sin($theta) * $v2)));
            $theta += $dtheta;
        }

        # Make the top triangles.
        [int]$pt1 = $mesh.Positions.Count - 1; # Index of last point.
        [int]$pt2 = ($pt0 + 1);                  # Index of first point in this cap.
        for ([int]$i = 0; $i -lt $num_sides; $i++)
        {
            $mesh.TriangleIndices.Add($pt0);
            $mesh.TriangleIndices.Add($pt1);
            $mesh.TriangleIndices.Add($pt2);
            $pt1 = $pt2++;
        }

        # Make the bottom end cap.
        # Make the end point.
        $pt0 = $mesh.Positions.Count; # Index of end_point2.
        [System.Windows.Media.Media3D.Point3D]$end_point2 = ($end_point + $axis)
        $mesh.Positions.Add($end_point2);

        # Make the bottom points.
        $theta = 0;
        for ([int]$i = 0; $i -lt $num_sides; $i++)
        {
            $mesh.Positions.Add(($end_point2 +
                ([Math]::Cos($theta) * $v1) +
                ([Math]::Sin($theta) * $v2)));
            $theta += $dtheta;
        }

        # Make the bottom triangles.
        $theta = 0;
        $pt1 = $mesh.Positions.Count - 1; # Index of last point.
        $pt2 = $pt0 + 1;                  # Index of first point in this cap.
        for ([int]$i = 0; $i -lt $num_sides; $i++)
        {
            $mesh.TriangleIndices.Add($num_sides + 1);    # end_point2
            $mesh.TriangleIndices.Add($pt2);
            $mesh.TriangleIndices.Add($pt1);
            $pt1 = $pt2++;
        }

        # Make the sides.
        # Add the points to the mesh.
        [int]$first_side_point = $mesh.Positions.Count;
        $theta = 0;
        for ([int]$i = 0; $i -lt $num_sides; $i++)
        {
            [System.Windows.Media.Media3D.Point3D]$p1 = ($end_point +
                ([Math]::Cos($theta) * $v1) +
                ([Math]::Sin($theta) * $v2));
            $mesh.Positions.Add($p1);
            [System.Windows.Media.Media3D.Point3D]$p2 = ($p1 + $axis);
            $mesh.Positions.Add($p2);
            $theta += $dtheta;
        }

        # Make the side triangles.
        $pt1 = $mesh.Positions.Count - 2;
        $pt2 = $pt1 + 1;
        [int]$pt3 = $first_side_point;
        [int]$pt4 = ($pt3 + 1);
        for ([int]$i = 0; $i -lt $num_sides; $i++)
        {
            $mesh.TriangleIndices.Add($pt1);
            $mesh.TriangleIndices.Add($pt2);
            $mesh.TriangleIndices.Add($pt4);

            $mesh.TriangleIndices.Add($pt1);
            $mesh.TriangleIndices.Add($pt4);
            $mesh.TriangleIndices.Add($pt3);

            $pt1 = $pt3;
            $pt3 += 2;
            $pt2 = $pt4;
            $pt4 += 2;
        }
    }

}