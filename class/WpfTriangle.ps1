class WpfTriangle
{
    [System.Windows.Media.Media3D.Point3D]$p1
    [System.Windows.Media.Media3D.Point3D]$p2
    [System.Windows.Media.Media3D.Point3D]$p3
    WpfTriangle([System.Windows.Media.Media3D.Point3D]$P1, [System.Windows.Media.Media3D.Point3D]$P2, [System.Windows.Media.Media3D.Point3D]$P3)
    {
        $this.p1 = $P1
        $this.p2 = $P2
        $this.p3 = $P3
    }
    static [Void]addTriangleToMesh([System.Windows.Media.Media3D.Point3D]$p0, [System.Windows.Media.Media3D.Point3D]$p1, [System.Windows.Media.Media3D.Point3D]$p2, [System.Windows.Media.Media3D.MeshGeometry3D]$mesh)
    {
        [WpfTriangle]::addTriangleToMesh($p0, $p1, $p2, $mesh, $false);
    }
    static [Void]addPointCombined([System.Windows.Media.Media3D.Point3D]$point, [System.Windows.Media.Media3D.MeshGeometry3D]$mesh, [System.Windows.Media.Media3D.Vector3D]$normal)
    {
        [Bool]$found = $false
        [Int]$i = 0
        foreach ($p in $mesh.Positions){
            if ($p -eq $point){
                $found = $true
                $mesh.TriangleIndices.Add($i)
                $mesh.Positions.Add($point)
                $mesh.Normals.Add($normal)
                break;
            }
            $i++
        }
        if (-not $found){
            $mesh.Positions.Add($point);
            $mesh.TriangleIndices.Add($mesh.TriangleIndices.Count);
            $mesh.Normals.Add($normal);
        }
    }
    static [Void]addTriangleToMesh([System.Windows.Media.Media3D.Point3D]$p0, [System.Windows.Media.Media3D.Point3D]$p1, [System.Windows.Media.Media3D.Point3D]$p2,[System.Windows.Media.Media3D.MeshGeometry3D]$mesh, [Bool]$combine_vertices){
        [System.Windows.Media.Media3D.Vector3D]$normal = [WpfTriangle]::CalculateNormal($p0, $p1, $p2);
        If($mesh){
            if ($combine_vertices){
                [WpfTriangle]::addPointCombined($p0, $mesh, $normal);
                [WpfTriangle]::addPointCombined($p1, $mesh, $normal);
                [WpfTriangle]::addPointCombined($p2, $mesh, $normal);
            } else {
                $mesh.Positions.Add($p0);
                $mesh.Positions.Add($p1);
                $mesh.Positions.Add($p2);
                $mesh.TriangleIndices.Add($mesh.TriangleIndices.Count);
                $mesh.TriangleIndices.Add($mesh.TriangleIndices.Count);
                $mesh.TriangleIndices.Add($mesh.TriangleIndices.Count);
                $mesh.Normals.Add($normal);
                $mesh.Normals.Add($normal);
                $mesh.Normals.Add($normal);
            }
        } Else {
            Write-Warning "Mesh is missing"
        }
    }
    static [Void]addTriangleBallToMesh([System.Windows.Media.Media3D.Point3D]$p0, [System.Windows.Media.Media3D.Point3D]$p1, [System.Windows.Media.Media3D.Point3D]$p2,[System.Windows.Media.Media3D.MeshGeometry3D]$mesh){
        # Do not reuse points so triangles don't share normals.
        If($mesh){
                $index1 = $mesh.Positions.Count
                $mesh.Positions.Add($p0);
                $mesh.Positions.Add($p1);
                $mesh.Positions.Add($p2);
                $mesh.TriangleIndices.Add($index1++);
                $mesh.TriangleIndices.Add($index1++);
                $mesh.TriangleIndices.Add($index1);
        } Else {
            Write-Warning "Mesh is missing"
        }
    }
    [void]AddSmoothTriangle([System.Windows.Media.Media3D.MeshGeometry3D]$mesh, [System.Windows.Media.Media3D.Point3DCollection]$dict, [System.Windows.Media.Media3D.Point3D]$p1, [System.Windows.Media.Media3D.Point3D]$p2, [System.Windows.Media.Media3D.Point3D]$p3)
    {
        [int]$this.index1
        [int]$this.index2
        [int]$this.index3

        # Find or create the points.
        if ($dict.ContainsKey($p1)){
            $this.index1 = $dict[$p1]
        } else {
            $this.index1 = $mesh.Positions.Count
            $mesh.Positions.Add($p1);
            $dict.Add($p1, $this.index1);
        }

        if ($dict.ContainsKey($p2)){
            $this.index2 = $dict[$p2]
        } else {
            $this.index2 = $mesh.Positions.Count;
            $mesh.Positions.Add($p2);
            $dict.Add($p2, $this.index2);
        }

        if ($dict.ContainsKey($p3)){
            $this.index3 = $dict[$p3];
        } else {
            $this.index3 = $mesh.Positions.Count;
            $mesh.Positions.Add($p3);
            $dict.Add($p3, $this.index3);
        }

        # If two or more of the points are
        # the same, it's not a triangle.
        if (($this.index1 -eq $this.index2) -or
            ($this.index2 -eq $this.index3) -or
            ($this.index3 -eq $this.index1)){
            return;
        }

        # Create the triangle.
        $mesh.TriangleIndices.Add($this.index1);
        $mesh.TriangleIndices.Add($this.index2);
        $mesh.TriangleIndices.Add($this.index3);
    }
    [System.Windows.Media.Media3D.GeometryModel3D]CreateTriangleModel([System.Drawing.Color]$color)
    {
        return [WpfTriangle]::CreateTriangleModel($this.p1, $this.p2, $this.p3, $color);
    }
    static [System.Windows.Media.Media3D.GeometryModel3D]CreateTriangleModel([System.Windows.Media.Media3D.Point3D]$P0, [System.Windows.Media.Media3D.Point3D]$P1, [System.Windows.Media.Media3D.Point3D]$P2, [System.Drawing.Color]$color){
        [System.Windows.Media.Media3D.MeshGeometry3D]$mesh = New-Object System.Windows.Media.Media3D.MeshGeometry3D
        [WpfTriangle]::addTriangleToMesh($P0, $P1, $P2, $mesh);
        [System.Windows.Media.Media3D.Material]$material = New-Object System.Windows.Media.Media3D.DiffuseMaterial -Property (@{Brush = $color})
        [System.Windows.Media.Media3D.GeometryModel3D]$model = New-Object System.Windows.Media.Media3D.GeometryModel3D -ArgumentList $mesh, $material
        return $model;
    }
    static [System.Windows.Media.Media3D.Vector3D]CalculateNormal([System.Windows.Media.Media3D.Point3D]$P0, [System.Windows.Media.Media3D.Point3D]$P1, [System.Windows.Media.Media3D.Point3D]$P2)
    {
        [System.Windows.Media.Media3D.Vector3D]$v0 = New-Object System.Windows.Media.Media3D.Vector3D(($P1.X - $P0.X), ($P1.Y - $P0.Y), ($P1.Z - $P0.Z));
        [System.Windows.Media.Media3D.Vector3D]$v1 = New-Object System.Windows.Media.Media3D.Vector3D(($P2.X - $P1.X), ($P2.Y - $P1.Y), ($P2.Z - $P1.Z));
        return [System.Windows.Media.Media3D.Vector3D]::CrossProduct($v0, $v1);
    }
}
